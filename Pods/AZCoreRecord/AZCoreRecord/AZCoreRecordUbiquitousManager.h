//
//  AZCoreRecordUbiquitousManager.h
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 11/8/12.
//  Copyright 2012 Pandamonia LLC. All rights reserved.
//

#import "AZCoreRecordManagerSubclass.h"

extern NSString *const AZCoreRecordManagerDidAddUbiquitousStoreNotification;
extern NSString *const AZCoreRecordManagerWillAddUbiquitousStoreNotification;
extern NSString *const AZCoreRecordUbiquitousStoreConfigurationNameKey;
extern NSString *const AZCoreRecordLocalOnlyStoreConfigurationNameKey;

@interface AZCoreRecordUbiquitousManager : AZCoreRecordManager

+ (AZCoreRecordUbiquitousManager *) defaultManager;

#pragma mark - Stack Accessors

@property (nonatomic, strong, readonly) id <NSObject, NSCopying, NSCoding> ubiquityToken;

#pragma mark - Helpers

@property (weak, nonatomic, readonly) NSURL *ubiquitousStoreURL;
@property (weak, nonatomic, readonly) NSURL *localOnlyStoreURL;

@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;

#pragma mark - Ubiquity Support

@property (nonatomic) BOOL stackShouldUseUbiquity;
@property (nonatomic, getter = isUbiquityEnabled) BOOL ubiquityEnabled;

+ (BOOL) supportsUbiquity;

@end
