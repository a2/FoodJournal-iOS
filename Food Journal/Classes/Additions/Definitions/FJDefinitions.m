//
//  FJDefinitions.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJDefinitions.h"

#define FJScreenMaxScale 2.0

CGFloat const FJImageLargeThumbnailHeight = 140.0 * FJScreenMaxScale;
CGFloat const FJNavigationBarButtonItemImageHeight = 18.0;
CGFloat const FJNavigationBarButtonItemLandscapeImageHeight = 14.0;
CGFloat const FJToolbarButtonItemImageHeight = 20.0;
CGFloat const FJToolbarButtonItemLandscapeImageHeight = 18.0;

CGSize const FJImageSmallThumbnailSize = { 100.0 * FJScreenMaxScale, 75.0 * FJScreenMaxScale };

NSString *const FJApplicationErrorDomain = @"FoodJournalErrorDomain";
NSString *const FJFailedOperationResponseKey = @"FailedOperationResponse";
NSString *const FJXMLRPCResponseFaultErrorDomain = @"XMLRPCResponseFaultErrorDomain";
NSString *const FJWordPressAPIBlogURLUserInfoKey = @"blogUrl";
NSString *const FJWordPressAPIDidAuthenticateWithSSONotification = @"FJWordPressAPIDidAuthenticateWithSSONotification";
NSString *const FJWordPressAPIDidFailToAuthenticateWithSSONotification = @"FJWordPressAPIDidFailToAuthenticateWithSSONotification";
NSString *const FJWordPressAPITokenUserInfoKey = @"token";
NSString *const FJWordPressAPIXMLRPCURLUserInfoKey = @"xmlrpcUrl";
