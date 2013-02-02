//
//  FJWordPressAPIClient.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "AFHTTPClient.h"

@interface FJWordPressAPIClient : AFHTTPClient

+ (FJWordPressAPIClient *)clientWithAccount:(WordPressAccount *)account;
+ (FJWordPressAPIClient *)clientWithBaseURL:(NSURL *)url username:(NSString *)username password:(NSString *)password;
+ (FJWordPressAPIClient *)clientWithBaseURL:(NSURL *)url token:(NSString *)token;

- (id)initWithAccount:(WordPressAccount *)account;
- (id)initWithBaseURL:(NSURL *)url username:(NSString *)username password:(NSString *)password;
- (id)initWithBaseURL:(NSURL *)url token:(NSString *)token;

#pragma mark - WP SSO Authentication

+ (BOOL)handleOpenURL:(NSURL *)url;
+ (BOOL)isSSOAvailable;

+ (void)authenticateWithClientID:(NSString *)clientID secret:(NSString *)secret redirectURI:(NSString *)redirectURI callback:(NSString *)callback;

#pragma mark - Make Requests

+ (NSDateFormatter *)postTitleDateFormatter;

- (void)authenticateWithSuccess:(void (^)(BOOL valid))success failure:(void (^)(NSError *error))failure;
- (void)getUsersBlogsWithSuccess:(void (^)(NSArray *blogs))success failure:(void (^)(NSError *error))failure;
- (void)getPostsWithFilter:(NSDictionary *)filter success:(void (^)(NSArray *posts))success failure:(void (^)(NSError *error))failure;
- (void)uploadFiles:(NSArray *)files progress:(void (^)(NSUInteger numberOfFinishedUploads, NSUInteger totalNumberOfUploads))progress completion:(void (^)(NSArray *files))completion;
- (void)uploadFileWithName:(NSString *)name mimeType:(NSString *)mimeType data:(NSData *)data success:(void (^)(NSDictionary *file))success failure:(void (^)(NSError *error))failure;
- (void)uploadImage:(Image *)image success:(void (^)(void))success failure:(void (^)(NSError *error))failure;
- (void)uploadImages:(NSArray *)images eachWithSuccess:(void (^)(Image *image, WordPressImage *wordPressImage))success failure:(void (^)(Image *image, NSError *error))failure andTotalProgress:(void (^)(NSUInteger numberOfFinishedUploads, NSUInteger totalNumberOfUploads))progress completion:(void (^)(void))completion;
- (void)uploadImagesForPost:(Post *)post withCompletion:(void (^)(void))completion;
- (void)uploadPost:(Post *)post withCompletion:(void (^)(WordPressPost *wordPressPost, NSError *error))completion;

#pragma mark - Explicit Requests

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method parameters:(NSArray *)parameters;

#pragma mark - Method Invocation

- (void)invokeMethod:(NSString *)method withSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)invokeMethod:(NSString *)method withParameters:(id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@end
