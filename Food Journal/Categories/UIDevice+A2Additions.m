//
//  UIDevice+A2Additions.m
//  Arex
//
//  Created by Alexsander Akers on 10/30/11.
//  Copyright (c) 2011-2012 Pandamonia LLC. All rights reserved.
//

#import "UIDevice+A2Additions.h"

@implementation UIDevice (A2Additions)

+ (BOOL) isPad
{
	static BOOL isPad = NO;
	
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		isPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
	});
	
	return isPad;
}
+ (BOOL) isPhone
{
	static BOOL isPhone = NO;
	
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		isPhone = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone);
	});
	
	return isPhone;
}

@end
