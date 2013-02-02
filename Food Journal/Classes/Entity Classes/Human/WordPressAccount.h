#import "_WordPressAccount.h"

@interface WordPressAccount : _WordPressAccount

+ (void)validateAccountWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password success:(void (^)(BOOL valid))success failure:(void (^)(NSError *error))failure;
+ (void)validateAndCreateAccountWithURL:(NSURL *)url token:(NSString *)token completion:(void (^)(WordPressAccount *account))completion;
+ (void)validateAndCreateAccountWithURL:(NSURL *)url username:(NSString *)username password:(NSString *)password completion:(void (^)(WordPressAccount *account))completion;

@property (nonatomic, strong) NSString *token;

@end
