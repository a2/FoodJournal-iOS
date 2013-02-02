//
//  AZCoreRecordUbiquitySentinel.h
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 6/22/12.
//  Copyright 2012 The Mental Faculty BV. Licensed under BSD.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <Foundation/Foundation.h>

/** A notification sent after the iCloud (“ubiquity”) identity has changed.
 
 When your app receives this notification, call the
 [AZCoreRecordUbiquitySentinel -ubiquityIdentityToken] or, on iOS 6,
 [NSFileManager -ubiquityIdentityToken] to obtain a token that represents the
 new ubiquity identity, or nil if the user has disabled Ubiquity.
 
 */
extern NSString *const AZUbiquityIdentityDidChangeNotification;

/** An object that abstractly represents a privacy-friendly representation of
 the current device for the current app for the purpose of identifying when
 Ubiquity settings have changed for the app. This emulates the new method
 [NSFileManager -ubiquityIdentityToken] introduced in iOS 6.
 
 It is generally recommended to use the shared instance.
 */
@interface AZCoreRecordUbiquitySentinel : NSObject <NSFilePresenter>

/** Returns the shared ubiquity sentinel. */
+ (AZCoreRecordUbiquitySentinel *) sharedSentinel;

/** Returns an opaque token that represents the current ubiquity identity.
 
 Call this method to check if Ubiquity is available. You can call this method on
 the main thread. You can also use this method, together with
 NSUbiquityIdentityDidChangeNotification or
 AZUbiquityIdentityDidChangeNotification to detect when a user changes their
 iCloud account. You can copy or encode a ubiquity identity token, and you can
 compare it to previously-obtained values by using the isEqual: method.
 
 This method returns nil if no ubiquity containers are available because the
 user has disabled them, or if the user is not logged in to iCloud.
 
 @see [NSFileManager -ubiquityIdentityToken]
 */
@property (nonatomic, copy, readonly) id <NSObject, NSCopying, NSCoding> ubiquityIdentityToken;

/** Returns whether or not ubiquity is available as a shorthand of determining
 whether the user is logged in or the server is unavailable. */
@property (nonatomic, readonly, getter = isUbiquityAvailable) BOOL ubiquityAvailable;

@end
