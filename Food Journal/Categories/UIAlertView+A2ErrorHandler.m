//
//  UIAlertView+A2ErrorHandler.m
//  Arex
//
//  Created by Alexsander Akers on 11/2/11.
//  Copyright (c) 2011-2012 Pandamonia LLC. All rights reserved.
//

#import "UIAlertView+A2ErrorHandler.h"

@interface A2ErrorHandler : NSObject <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *recoveryErrors;

+ (A2ErrorHandler *) sharedHandler;

- (NSError *) popErrorForAlertView: (UIAlertView *) alertView;

- (void) setError: (NSError *) error forAlertView: (UIAlertView *) alertView;

@end

@implementation A2ErrorHandler

A2_SYNTHESIZE_SINGLETON(A2ErrorHandler, sharedHandler)

- (id) init
{
	if ((self = [super init]))
	{
		self.recoveryErrors = [[NSMutableDictionary alloc] initWithCapacity: 4];
	}
	
	return self;
}

- (NSError *) popErrorForAlertView: (UIAlertView *) alertView
{
	NSValue *value = [NSValue valueWithNonretainedObject: alertView];
	NSError *error = self.recoveryErrors[value];
	[self.recoveryErrors removeObjectForKey: value];
	return error;
}

- (void) setError: (NSError *) error forAlertView: (UIAlertView *) alertView
{
	NSValue *value = [NSValue valueWithNonretainedObject: alertView];
	self.recoveryErrors[value] = error;
}

- (void) alertViewCancel: (UIAlertView *) alertView;
{
	NSError *error = [self popErrorForAlertView: alertView];
	[error.recoveryAttempter attemptRecoveryFromError: error optionIndex: NSNotFound];
}
- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex;
{
	NSError *error = [self popErrorForAlertView: alertView];
	NSString *buttonTitle = [alertView buttonTitleAtIndex: buttonIndex];
	NSInteger recoveryIndex = [error.localizedRecoveryOptions indexOfObject: buttonTitle];
	[error.recoveryAttempter attemptRecoveryFromError: error optionIndex: recoveryIndex];
}

@end

@implementation UIAlertView (A2ErrorHandler)

+ (UIAlertView *) alertViewWithError: (NSError *) error
{
	if (!error) return nil;
	
	BOOL hasRecoveryAttempter = (error.recoveryAttempter && error.localizedRecoveryOptions.count);
	NSString *cancelButton = hasRecoveryAttempter ? nil : NSLocalizedString(@"Dismiss", @"Button text");
	NSString *message = error.localizedFailureReason;
	
	if (error.localizedRecoverySuggestion)
	{
		message = [message stringByAppendingFormat: @"\n%@", error.localizedRecoverySuggestion];
	}
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: error.localizedDescription message: message delegate: nil cancelButtonTitle: cancelButton otherButtonTitles: nil];
	
	if (hasRecoveryAttempter)
	{
		[[A2ErrorHandler sharedHandler] setError: error forAlertView: alertView];
		
		[error.localizedRecoveryOptions enumerateObjectsUsingBlock: ^(NSString *option, NSUInteger idx, BOOL *stop) {
			[alertView addButtonWithTitle: option];
		}];
		
		alertView.cancelButtonIndex = error.localizedRecoveryOptions.count - 1;
		alertView.delegate = [A2ErrorHandler sharedHandler];
	}
	
	return alertView;
}

@end
