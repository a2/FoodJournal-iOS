//
//  FJWordPressAPIClient.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "AFAuthenticationAlertView.h"
#import "FJWordPressAPIClient.h"

@interface FJWordPressAPIClient ()

@property (strong, nonatomic) WordPressAccount *account;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSString *username;
@property (nonatomic) int64_t blogId;

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString;

@end

@implementation FJWordPressAPIClient

+ (FJWordPressAPIClient *)clientWithAccount:(WordPressAccount *)account
{
	return [[self alloc] initWithAccount:account];
}
+ (FJWordPressAPIClient *)clientWithBaseURL:(NSURL *)url username:(NSString *)username password:(NSString *)password
{
	return [[self alloc] initWithBaseURL:url username:username password:password];
}
+ (FJWordPressAPIClient *)clientWithBaseURL:(NSURL *)url token:(NSString *)token;
{
	return [[self alloc] initWithBaseURL:url token:token];
}

- (id)initWithAccount:(WordPressAccount *)account
{
	if (account.hasTokenValue)
		self = [self initWithBaseURL:[NSURL URLWithString:account.url] token:account.token];
	else
		self = [self initWithBaseURL:[NSURL URLWithString:account.url] username:account.username password:account.password];
	if (!self)
		return nil;
	
	self.account = account;
	self.blogId = account.blogIdValue;
	
	return self;
}
- (id)initWithBaseURL:(NSURL *)url username:(NSString *)username password:(NSString *)password
{
	self = [self initWithBaseURL:url];
	if (!self)
		return nil;
	
	self.username = username;
	self.password = password;
	
	return self;
}
- (id)initWithBaseURL:(NSURL *)url token:(NSString *)token
{
	self = [self initWithBaseURL:url username:@"" password:@""];
	if (!self)
		return nil;
	
	self.token = token;
	[self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", token]];
	
	return self;
}

#pragma mark - WP SSO Authentication

+ (BOOL) handleOpenURL:(NSURL *)url
{
	if (!url || ![url.host isEqualToString:@"wordpress-sso"])
		return NO;
	
	NSDictionary *params = [self dictionaryWithQueryString:url.query];
	NSString *blog = params[@"blog"];
	NSString *token = params[@"token"];
	if (blog && token)
	{
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/", blog]];
		NSURL *xmlrpcUrl = [url URLByAppendingPathComponent:@"xmlrpc.php" isDirectory:NO];
		
		NSDictionary *userInfo = @{FJWordPressAPIBlogURLUserInfoKey: url, FJWordPressAPITokenUserInfoKey: token, FJWordPressAPIXMLRPCURLUserInfoKey: xmlrpcUrl};
		[[NSNotificationCenter defaultCenter] postNotificationName:FJWordPressAPIDidAuthenticateWithSSONotification object:self userInfo:userInfo];
		
		return YES;
	}
	else
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:FJWordPressAPIDidFailToAuthenticateWithSSONotification object:self];
		return NO;
	}
}
+ (BOOL) isSSOAvailable
{
	return [UIApp canOpenURL:[NSURL URLWithString:@"wordpress://"]];
}

+ (NSDictionary *)dictionaryWithQueryString:(NSString *)queryString
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	
	NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
	[pairs each:^(NSString *pair) {
		NSRange separator = [pair rangeOfString:@"="];
		NSString *key;
		NSString *value;
		if (separator.location != NSNotFound)
		{
			key = [pair substringToIndex:separator.location];
			value = [[pair substringFromIndex:separator.location + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		}
		else
		{
			key = pair;
			value = @"";
		}
		
		key = [key stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		result[key] = value;
	}];
	
	return result;
}

+ (void)authenticateWithClientID:(NSString *)clientID secret:(NSString *)secret redirectURI:(NSString *)redirectURI callback:(NSString *)callback
{
	if (![self isSSOAvailable])
		return;
	
	NSString *urlString = [NSString stringWithFormat:@"wordpress://oauth?client_id=%@&secret=%@&callback=%@&redirect_uri=%@", clientID, secret, callback, redirectURI];
	[UIApp openURL:[NSURL URLWithString:urlString]];
}

#pragma mark - Make Requests

- (BOOL)validateCredentials:(BOOL)accountRequired error:(NSError **)error
{
	if (!(((self.username && self.password) || self.token) && self.blogId))
	{
		if (error)
			*error = [NSError errorWithDomain:FJApplicationErrorDomain code:FJErrorInvalidCredentials userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid username and/or password.", nil)}];
		return NO;
	}
	else if (accountRequired && !self.account)
	{
		if (error)
			*error = [NSError errorWithDomain:FJApplicationErrorDomain code:FJErrorInvalidCredentials userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Account required. Use +clientWithAccount: or -initWithAccount: to initialize FJWordPressAPIClient.", nil)}];
		return NO;
	}
	
	return YES;
}

+ (NSDateFormatter *)postTitleDateFormatter
{
	static NSDateFormatter *dateFormatter;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"yyyyMMMMdEEEE" options:kNilOptions locale:[NSLocale currentLocale]];;
	});
	
	return dateFormatter;
}

- (void)authenticateWithSuccess:(void (^)(BOOL valid))success failure:(void (^)(NSError *error))failure
{
	[self getUsersBlogsWithSuccess:^(NSArray *blogs) {
		if (success)
			success(YES);
	} failure:^(NSError *error) {
		if (error.code == 403 && [error.domain isEqualToString:@"XMLRPC"])
		{
			if (success)
				success(NO);
		}
		else
		{
			if (failure)
				failure(error);
		}
	}];
}
- (void)getUsersBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure
{
	NSError *error;
	if (![self validateCredentials:NO error:&error])
	{
		if (failure)
			failure(error);
		return;
	}
	
	[self invokeMethod:@"wp.getUsersBlogs" withParameters:@[self.username, self.password] success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success)
			success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure)
			failure(error);
	}];
}
- (void)getPostsWithFilter:(NSDictionary *)filter success:(void (^)(NSArray *posts))success failure:(void (^)(NSError *error))failure
{
	NSError *error;
	if (![self validateCredentials:NO error:&error])
	{
		if (failure)
			failure(error);
		return;
	}
	
	NSMutableArray *parameters = [@[@(self.blogId), self.username, self.password] mutableCopy];
	if (filter) [parameters addObject:filter];
	
	[self invokeMethod:@"wp.getPosts" withParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success)
			success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure)
			failure(error);
	}];
}
- (void)uploadFiles:(NSArray *)files progress:(void (^)(NSUInteger numberOfFinishedUploads, NSUInteger totalNumberOfUploads))progress completion:(void (^)(NSArray *files))completion
{
	NSError *error;
	if (![self validateCredentials:NO error:&error])
	{
		if (completion)
			completion(@[error]);
		return;
	}

	NSParameterAssert(files != nil && files.count > 0);
	NSMutableDictionary *wpFiles = [NSMutableDictionary dictionaryWithCapacity:files.count];
	NSArray *operations = [files map:^id(NSDictionary *file) {
		NSParameterAssert(file[@"name"] != nil && file[@"mimeType"] != nil && file[@"data"] != nil);
		NSMutableDictionary *dataStruct = [NSMutableDictionary dictionaryWithCapacity:3];
		dataStruct[@"name"] = file[@"name"];
		dataStruct[@"type"] = file[@"mimeType"];
		dataStruct[@"bits"] = [file[@"data"] base64EncodedString];
		
		NSArray *parameters = @[@(self.blogId), self.username, self.password, dataStruct];
		NSURLRequest *request = [self requestWithMethod:@"wp.uploadFile" parameters:parameters];
		return [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
			wpFiles[file] = responseObject;
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			wpFiles[file] = error;
		}];
	}];
	[self enqueueBatchOfHTTPRequestOperations:operations progressBlock:progress completionBlock:^(NSArray *operations) {
		completion([wpFiles objectsForKeys:files notFoundMarker:[NSNull null]]);
	}];
}
- (void)uploadFileWithName:(NSString *)name mimeType:(NSString *)mimeType data:(NSData *)data success:(void (^)(NSDictionary *file))success failure:(void (^)(NSError *error))failure
{
	NSError *error;
	if (![self validateCredentials:NO error:&error])
	{
		if (failure)
			failure(error);
		return;
	}

	NSParameterAssert(name != nil && mimeType != nil && data != nil);
	NSDictionary *dataStruct = @{@"name": name, @"type": mimeType, @"bits": data};
	NSArray *parameters = @[@(self.blogId), self.username, self.password, dataStruct];
	
	[self invokeMethod:@"wp.uploadFile" withParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success)
			success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure)
			failure(error);
	}];
}
- (void)uploadImage:(Image *)image success:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
	NSError *error;
	if (![self validateCredentials:YES error:&error])
	{
		if (failure)
			failure(error);
		return;
	}
	
	NSParameterAssert(image != nil && image.imageData.length > 0);
	NSDictionary *dataStruct = @{@"name": [NSString stringWithFormat:@"%@.jpg", image.meal.name], @"type": @"image/jpeg", @"bits": image.imageData};
	NSArray *parameters = @[@(self.blogId), self.username, self.password, dataStruct];
	
	[self invokeMethod:@"wp.uploadFile" withParameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDictionary) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", WordPressImageRelationships.account, self.account, WordPressImageRelationships.image, image];
		WordPressImage *wordPressImage = [WordPressImage findFirstWithPredicate:predicate inContext:image.managedObjectContext];
		if (!wordPressImage)
		{
			wordPressImage = [WordPressImage createInContext:image.managedObjectContext];
			wordPressImage.account = [self.account inContext:image.managedObjectContext];
			wordPressImage.image = image;
		}
		
		wordPressImage.attachmentIdValue = [responseDictionary[@"id"] longLongValue];
		wordPressImage.url = responseDictionary[@"url"];
		
		[image.managedObjectContext save];
		
		if (success)
			success();
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure)
			failure(error);
	}];
}
- (void)uploadImages:(NSArray *)images eachWithSuccess:(void (^)(Image *image, WordPressImage *wordPressImage))success failure:(void (^)(Image *image, NSError *error))failure andTotalProgress:(void (^)(NSUInteger numberOfFinishedUploads, NSUInteger totalNumberOfUploads))progress completion:(void (^)(void))completion
{
	NSError *error;
	if (![self validateCredentials:YES error:&error])
	{
		if (failure)
			failure(nil, error);
		return;
	}
	
	static NSString *noName;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		noName = NSLocalizedString(@"Untitled", nil);
	});
	
	NSParameterAssert(images != nil && images.count > 0);
	NSArray *operations = [images map:^id(NSManagedObject *anImage) {
		Image *image;
		if ([anImage.entity isKindOfEntity:[Image entityDescriptionInContext:anImage.managedObjectContext]])
			image = A2_STATIC_CAST(Image, anImage);
		else if ([anImage.entity isKindOfEntity:[WordPressImage entityDescriptionInContext:anImage.managedObjectContext]])
			image = A2_STATIC_CAST(WordPressImage, anImage).image;
		
		NSParameterAssert(image.imageData.length > 0);
		NSDictionary *dataStruct = @{@"name": [NSString stringWithFormat:@"%@.jpg", image.meal.name ?: noName], @"type": @"image/jpeg", @"bits": image.imageData};
		NSArray *parameters = @[@(self.blogId), self.username, self.password, dataStruct];
		
		NSURLRequest *request = [self requestWithMethod:@"wp.uploadFile" parameters:parameters];
		return [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDictionary) {
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", WordPressImageRelationships.account, self.account, WordPressImageRelationships.image, image];
			WordPressImage *wordPressImage = [WordPressImage findFirstWithPredicate:predicate inContext:image.managedObjectContext];
			if (!wordPressImage)
			{
				wordPressImage = [WordPressImage createInContext:image.managedObjectContext];
				wordPressImage.account = [self.account inContext:image.managedObjectContext];
				wordPressImage.image = image;
			}
			
			wordPressImage.attachmentIdValue = [responseDictionary[@"id"] longLongValue];
			wordPressImage.url = responseDictionary[@"url"];
			
			[image.managedObjectContext save];

			if (success)
				success(image, wordPressImage);
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			if (failure)
				failure(image, error);
		}];
	}];
	[self enqueueBatchOfHTTPRequestOperations:operations progressBlock:progress completionBlock:^(NSArray *operations) {
		if (completion)
			completion();
	}];
}
- (void)uploadImagesForPost:(Post *)post withCompletion:(void (^)(void))completion
{
	NSError *error;
	if (![self validateCredentials:YES error:&error])
	{
		if (completion)
			completion();
		return;
	}

	NSMutableArray *imagesToCheck = [NSMutableArray array];
	[post.meals each:^(Meal *meal) {
		[imagesToCheck addObjectsFromArray:meal.images.array];
	}];
	
	NSMutableArray *imagesToUpload = [imagesToCheck mutableCopy];
	
	[imagesToCheck performSelect:^BOOL(Image *image) {
		return (image.wordPressImages.count > 0);
	}];
	[imagesToUpload removeObjectsInArray:imagesToCheck];
	
	[imagesToCheck performMap:^id(Image *image) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", WordPressImageRelationships.account, self.account, WordPressImageRelationships.image, image];
		WordPressImage *wordPressImage = [WordPressImage findFirstWithPredicate:predicate inContext:image.managedObjectContext];
		
		NSArray *parameters = @[@(self.blogId), self.username, self.password, wordPressImage.attachmentId];
		NSURLRequest *request = [self requestWithMethod:@"wp.getMediaItem" parameters:parameters];
		return [self HTTPRequestOperationWithRequest:request success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			if (error.code == 404)
				[imagesToUpload addObject:image];
		}];
	}];
	
	void (^uploadOperations)(NSArray *) = ^(NSArray *operations) {
		if (imagesToUpload.count)
		{
			[self uploadImages:imagesToUpload eachWithSuccess:nil failure:nil andTotalProgress:nil completion:completion];
			return;
		}

		if (completion)
			completion();
	};
	
	if (imagesToCheck.count)
		[self enqueueBatchOfHTTPRequestOperations:imagesToCheck progressBlock:nil completionBlock:uploadOperations];
	else
		uploadOperations(nil);
}
- (void)uploadPost:(Post *)post withCompletion:(void (^)(WordPressPost *wordPressPost, NSError *error))completion
{
	NSError *error;
	if (![self validateCredentials:YES error:&error])
	{
		if (completion)
			completion(nil, error);
		return;
	}

	[self uploadImagesForPost:post withCompletion:^{
		__block WordPressPost *wordPressPost = nil;
		
		if (post.wordPressPosts.count)
		{
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@ AND %K == %@", WordPressPostRelationships.account, self.account, WordPressPostRelationships.post, post];
			wordPressPost = [WordPressPost findFirstWithPredicate:predicate inContext:post.managedObjectContext];
		}
		
		NSMutableArray *images = [NSMutableArray array];
		[post.meals each:^(Meal *meal) {
			[meal.images each:^(Image *image) {
				WordPressImage *wordPressImage = [image.wordPressImages match:^BOOL(WordPressImage *wordPressImage) {
					return [wordPressImage.account isEqual:self.account];
				}];
				if (wordPressImage)
					[images addObject:wordPressImage];
			}];
		}];
		
		NSString *imageIds = [[images map:^id(WordPressImage *image) {
			return [image.attachmentId stringValue];
		}] componentsJoinedByString:@","];
		
		NSMutableString *postContent = [NSMutableString string];
		[postContent appendFormat:@"[gallery link=\"file\" ids=\"%@\"]\n", imageIds];
		[post.meals each:^(Meal *meal) {
			[postContent appendFormat:@"<strong>%@</strong>\n", meal.name];
			if (meal.foods)
			{
				[postContent appendString:@"<ul>\n"];
				[meal.foods each:^(Food *food) {
					[postContent appendFormat:@"\t<li>%@</li>\n", food.name];
				}];
				[postContent appendString:@"</ul>\n"];
			}
		}];
		
		NSMutableDictionary *content = [NSMutableDictionary dictionary];
		content[@"post_title"] = [[FJWordPressAPIClient postTitleDateFormatter] stringFromDate:post.date];
		content[@"post_content"] = postContent;
		content[@"post_status"] = @"publish";
		content[@"post_date_gmt"] = post.date;
		
		BKBlock uploadPost = ^{
			NSArray *parameters = @[@(self.blogId), self.username, self.password, content];
			[self invokeMethod:@"wp.newPost" withParameters:parameters success:^(AFHTTPRequestOperation *operation, NSString *responsePostId) {
				NSNumber *postId = @([responsePostId longLongValue]);
				
				if (!wordPressPost)
				{
					wordPressPost = [WordPressPost createInContext:post.managedObjectContext];
					wordPressPost.account = self.account;
					wordPressPost.post = post;
				}
				
				wordPressPost.postId = postId;
				
				NSArray *parameters = @[@(self.blogId), self.username, self.password, postId];
				[self invokeMethod:@"wp.getPost" withParameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary *responseDictionary) {
					wordPressPost.url = responseDictionary[@"link"];
					
					if (completion)
						completion(wordPressPost, nil);
				} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					if (completion)
						completion(nil, error);
				}];
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				if (completion)
					completion(nil, error);
			}];
		};
		
		if (wordPressPost)
		{
			NSArray *parameters = @[@(self.blogId), self.username, self.password, wordPressPost.postId, content];
			[self invokeMethod:@"wp.editPost" withParameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
				if (completion)
					completion(wordPressPost, nil);
			} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				if (error.code == 404)
					uploadPost();
				else if (completion)
					completion(nil, error);
			}];
		}
		else
		{
			uploadPost();
		}
	}];
}

#pragma mark - AFHTTPClient Methods

-(AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)urlRequest success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure
{
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseData) {
		XMLRPCResponse *response = [[XMLRPCResponse alloc] initWithData:responseData];
		NSError *error = nil;
		
		if (response.isFault)
		{
			error = [NSError errorWithDomain:FJXMLRPCResponseFaultErrorDomain code:response.faultCode.integerValue userInfo:@{NSLocalizedDescriptionKey: response.faultString}];
		}
		
		if (!response.object)
		{
			error = [NSError errorWithDomain:FJApplicationErrorDomain code:FJErrorBlogReturnedInvalidData userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Blog returned invalid data.", nil)}];
		}
		
		id object = [response.object copy];
		if (error)
		{
			if (failure)
			{
				dispatch_block_t block = ^{
					failure(operation, error);;
				};
				
				if (operation.failureCallbackQueue)
					dispatch_async(operation.failureCallbackQueue, block);
				else
					block();
			}
		}
		else if (success)
		{
			dispatch_block_t block = ^{
				success(operation, object);
			};

			if (operation.successCallbackQueue)
				dispatch_async(operation.successCallbackQueue, block);
			else
				block();
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure)
		{
			NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
			if (operation.response) userInfo[FJFailedOperationResponseKey] = operation.response;
			NSError *newError = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
			
			dispatch_block_t block = ^{
				failure(operation, newError);
			};
			
			if (operation.failureCallbackQueue)
				dispatch_async(operation.failureCallbackQueue, block);
			else
				block();
		}
	}];
	
	[operation setAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
		if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
		{
			// Handle invalid certificates
			SecTrustResultType result;
			OSStatus certificateStatus = SecTrustEvaluate(challenge.protectionSpace.serverTrust, &result);
			if (certificateStatus == 0 && result == kSecTrustResultRecoverableTrustFailure)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[[[AFAuthenticationAlertView alloc] initWithChallenge:challenge] show];
				});
			}
			else
			{
				[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
			}
		}
		else
		{
			NSURLCredential *credential = [[NSURLCredentialStorage sharedCredentialStorage] defaultCredentialForProtectionSpace:challenge.protectionSpace];
			if (challenge.previousFailureCount == 0 && credential)
			{
				[challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
			}
			else
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[[[AFAuthenticationAlertView alloc] initWithChallenge:challenge] show];
				});
			}
		}
	}];
	
	[operation setAuthenticationAgainstProtectionSpaceBlock:^BOOL(NSURLConnection *connection, NSURLProtectionSpace *protectionSpace) {
		// We can handle any authentication available except client certificates.
		return ![protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate];
	}];
	
	return operation;
}

#pragma mark - Explicit Requests

- (NSMutableURLRequest *) requestWithMethod:(NSString *)method parameters:(NSArray *)parameters
{
	NSParameterAssert(method != nil);
	if (!parameters) parameters = @[];
	
	NSParameterAssert([parameters isKindOfClass: [NSArray class]]);
	
	NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:@"xmlrpc.php" parameters:nil];
	
	XMLRPCDefaultEncoder *encoder = [[XMLRPCDefaultEncoder alloc] init];
	[encoder setMethod:method withParameters:parameters];
	request.HTTPBody = [encoder.encode dataUsingEncoding:NSUTF8StringEncoding];
	
	return request;
}

#pragma mark - Method Invocation

- (void)invokeMethod:(NSString*)method withSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	[self invokeMethod:method withParameters:nil success:success failure:failure];
}
- (void)invokeMethod:(NSString*)method withParameters:(id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
	NSMutableURLRequest *request = [self requestWithMethod:method parameters:parameters];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
	[self enqueueHTTPRequestOperation:operation];
}

@end
