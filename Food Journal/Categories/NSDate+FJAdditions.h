//
//  NSDate+FJAdditions.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/5/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (FJAdditions)

- (NSDate *)dateByMovingToBeginningOfDay;
- (NSDate *)dateByMovingToEndOfDay;

@end
