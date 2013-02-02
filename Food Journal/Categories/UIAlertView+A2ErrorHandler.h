//
//  UIAlertView+A2ErrorHandler.h
//
//  Created by Alexsander Akers on 11/2/11.
//  Copyright (c) 2011-2012 Pandamonia LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (A2ErrorHandler)

// Returns an alert view that can respond to an error. The error must contain AT
// LEAST a localized description and reason. It will present buttons for
// recovery options if the error also contains a recovery attempter and recovery
// options. The last recovery option is always asumed to be the safe "Cancel"
// option. The recovery atempter must be able to handle optionIndex equal to
// NSNotFound, it sent if an alert view is cancelled by the system.

+ (UIAlertView *) alertViewWithError: (NSError *) error;

@end
