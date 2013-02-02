#import "Account.h"

@interface Account ()

@end

@implementation Account

- (void)prepareForDeletion
{
	self.password = nil;

	[super prepareForDeletion];
}

#pragma mark - Password

- (NSString *)password
{
	NSError *error;
	NSString *password;
	if (self.url && self.username)
		password = [SSKeychain passwordForService:self.url account:self.username error:&error];
	else
		password = [SSKeychain passwordForService:self.title account:self.url error:&error];
	[AZCoreRecordManager handleError:error];
	return password;
}

- (void)setPassword:(NSString *)aPassword
{
	NSError *error;
	if (aPassword)
	{
		if (self.url && self.username)
			[SSKeychain setPassword:aPassword forService:self.url account:self.username error:&error];
		else
			[SSKeychain setPassword:aPassword forService:self.title account:self.url error:&error];
	}
	else
	{
		if (self.url && self.username)
			[SSKeychain deletePasswordForService:self.url account:self.username error:&error];
		else
			[SSKeychain deletePasswordForService:self.title account:self.url error:&error];
	}
	
	[AZCoreRecordManager handleError:error];
}

@end
