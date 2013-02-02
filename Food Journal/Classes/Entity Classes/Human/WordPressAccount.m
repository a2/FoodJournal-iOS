#import "FJWordPressAPIClient.h"
#import "WordPressAccount.h"

@interface WordPressAccount ()

@end

@implementation WordPressAccount

+ (void)validateAccountWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password success:(void (^)(BOOL valid))success failure:(void (^)(NSError *error))failure
{
	[[FJWordPressAPIClient clientWithBaseURL:url username:username password:password] getUsersBlogsWithSuccess:^(NSArray *blogs) {
		if (blogs.count)
			success(YES);
		else
			success(NO);
	} failure:^(NSError *error) {
		failure(error);
	}];
}
+ (void)validateAndCreateAccountWithURL:(NSURL *)url token:(NSString *)token completion:(void (^)(WordPressAccount *account))completion
{
	[self validateAndCreateAccountWithURL:url username:nil password:nil token:token completion:completion];
}
+ (void)validateAndCreateAccountWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password completion:(void (^)(WordPressAccount *account))completion
{
	[self validateAndCreateAccountWithURL:url username:username password:password token:nil completion:completion];
}
+ (void)validateAndCreateAccountWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password token:(NSString *)token completion:(void (^)(WordPressAccount *account))completion
{
	NSParameterAssert(token != nil || (username != nil && password != nil));
	
	DZProgressController *progressController = [[DZProgressController alloc] init];
	progressController.label.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
	progressController.label.text = NSLocalizedStringWithDefaultValue(@"Signing in...", nil, [NSBundle mainBundle], @"Signing in…", nil);
	[progressController show];
	
	void (^success)(NSArray *) = ^(NSArray *blogs){
		WordPressAccount *(^createAccountWithBlog)(NSDictionary *) = ^(NSDictionary *blog) {
			__block WordPressAccount *account = nil;
			[[NSManagedObjectContext defaultContext] saveDataWithBlock:^(NSManagedObjectContext *context) {
				account = [WordPressAccount create];
				account.title = blog[@"blogName"];
				account.url = blog[@"url"];
				account.xmlrpcUrl = blog[@"xmlrpc"];
				account.blogIdValue = [blog[@"blogid"] longLongValue];
				
				if (username && password)
				{
					account.username = username;
					account.password = password;
				}
				else if (token)
				{
					account.token = token;
				}
			}];
			
			if (completion)
			{
				double delayInSeconds = 3.0;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					completion(account);
				});
			}
			
			return account;
		};
		
		if (!token && blogs.count > 1)
		{
			[progressController hide];
			
			double delayInSeconds = 1.5;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Choose a blog to use with %@.", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:(id)kCFBundleNameKey]];
				NSArray *otherButtonTitles = [blogs map:^id(NSDictionary *blog) {
					return blog[@"blogName"];
				}];
				[UIAlertView showAlertViewWithTitle:NSLocalizedString(@"Select a Blog", nil) message:message cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:otherButtonTitles handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
					if (buttonIndex == alertView.cancelButtonIndex)
						return;
					
					NSDictionary *blog = blogs[buttonIndex - alertView.firstOtherButtonIndex];
					WordPressAccount *account = createAccountWithBlog(blog);
					completion(account);
				}];
			});
			return;
		}

		NSDictionary *blog;
		if (token)
		{
			blog = [blogs match:^BOOL(NSDictionary *blog) {
				return [url isEqual:[NSURL URLWithString:blog[@"url"]]];
			}];
		}
		else
			blog = blogs[0];
		
		[progressController performChanges:^{
			progressController.customView = DZProgressControllerSuccessView;
			progressController.label.text = NSLocalizedString(@"Success!", nil);
		}];
		[progressController performSelector:@selector(hide) withObject:nil afterDelay:1.0];
		
		createAccountWithBlog(blog);
	};
	
	void (^failure)(NSError *) = ^(NSError *error) {
		[progressController performChanges:^{
			progressController.customView = DZProgressControllerErrorView;
			progressController.label.text = error.localizedDescription;
		}];
		[progressController performSelector:@selector(hide) withObject:nil afterDelay:3.0];
		
		if (completion)
		{
			double delayInSeconds = 3.0;
			dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
			dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
				completion(nil);
			});
		}
	};
	
	FJWordPressAPIClient *apiClient;
	if (username && password)
		apiClient = [FJWordPressAPIClient clientWithBaseURL:url username:username password:password];
	else
		apiClient = [FJWordPressAPIClient clientWithBaseURL:url token:token];
	
	[apiClient getUsersBlogsWithSuccess:^(NSArray *blogs) {
		if (!blogs.count)
		{
			NSError *error = [NSError errorWithDomain:FJApplicationErrorDomain code:FJErrorNoBlogsFound userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"No blogs found.", nil)}];
			failure(error);
			return;
		}
		
		success(blogs);
	} failure:^(NSError *error) {
		failure(error);
	}];
}

#pragma mark - Token Accessors

- (NSString *)token
{
	if (self.hasToken)
		return self.password;
	return nil;
}

- (void)setToken:(NSString *)aToken
{
	if (aToken)
	{
		self.password = aToken;
		self.hasTokenValue = YES;
	}
	else
	{
		self.password = nil;
		self.hasTokenValue = NO;
	}
}

@end
