//
//  NSDate+FJAdditions.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/5/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "NSDate+FJAdditions.h"

@implementation NSDate (FJAdditions)

- (NSDate *)dateByMovingToBeginningOfDay
{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:self];
	components.hour = [calendar minimumRangeOfUnit:NSHourCalendarUnit].location;
	components.minute = [calendar minimumRangeOfUnit:NSMinuteCalendarUnit].location;
	components.second = [calendar minimumRangeOfUnit:NSSecondCalendarUnit].location;
	return [calendar dateFromComponents:components];
}
- (NSDate *)dateByMovingToEndOfDay
{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	NSDateComponents *components = [calendar components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit) fromDate:self];
	components.hour = NSMaxRange([calendar maximumRangeOfUnit:NSHourCalendarUnit]);
	components.minute = NSMaxRange([calendar maximumRangeOfUnit:NSMinuteCalendarUnit]);
	components.second = NSMaxRange([calendar maximumRangeOfUnit:NSSecondCalendarUnit]);
	return [calendar dateFromComponents:components];
}

@end
