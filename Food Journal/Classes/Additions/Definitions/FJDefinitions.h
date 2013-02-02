//
//  FJDefinitions.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

extern CGFloat const FJImageLargeThumbnailHeight;
extern CGFloat const FJNavigationBarButtonItemImageHeight;
extern CGFloat const FJNavigationBarButtonItemLandscapeImageHeight;
extern CGFloat const FJToolbarButtonItemImageHeight;
extern CGFloat const FJToolbarButtonItemLandscapeImageHeight;

extern CGSize const FJImageSmallThumbnailSize;

extern NSString *const FJApplicationErrorDomain;
extern NSString *const FJFailedOperationResponseKey;
extern NSString *const FJXMLRPCResponseFaultErrorDomain;
extern NSString *const FJWordPressAPIBlogURLUserInfoKey;
extern NSString *const FJWordPressAPIDidAuthenticateWithSSONotification;
extern NSString *const FJWordPressAPIDidFailToAuthenticateWithSSONotification;
extern NSString *const FJWordPressAPITokenUserInfoKey;
extern NSString *const FJWordPressAPIXMLRPCURLUserInfoKey;

#define CFSafeRelease(obj) do { if (obj) CFRelease(obj), obj = NULL; } while (0)
#define NSAssertProperty(prop) NSAssert2(self.prop, @"An instance of %s requires a non-nil %s", object_getClassName(self), #prop)
#define RXCompare(left, right) ((left) == (right) ? NSOrderedSame : ((left) - (right))/abs((left) - (right)))
#define RXFormatDouble(d) ([NSNumberFormatter localizedStringFromNumber: @(d) numberStyle: NSNumberFormatterDecimalStyle])
#define UIApp ((UIApplication *) [UIApplication sharedApplication])

#pragma mark - Enumerations

enum
{
	UIActivityIndicatorViewStyleWhiteSmall = 3,
	UIActivityIndicatorViewStyleGraySmall = 4
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000 // __IPHONE_5_0
	,
	UIActivityIndicatorViewStyleSyncWhite = 6,
	UIActivityIndicatorViewStyleSyncGray = 7,
	UIActivityIndicatorViewStyleWhiteSmallShadowed = 11,
	UIActivityIndicatorViewStyleSyncWhiteShadowed = 12
#endif
};

#pragma mark - Type Definitions

typedef NS_ENUM(NSInteger, FJError)
{
	FJErrorUnknown = 0,
	FJErrorBlogReturnedInvalidData,
	FJErrorNoBlogsFound,
	FJErrorInvalidCredentials
};
