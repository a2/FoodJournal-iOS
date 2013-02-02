//
//  AZCoreRecordManager+Subclass.h
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 11/8/12.
//  Copyright 2012 Pandamonia LLC. All rights reserved.
//

#import "AZCoreRecordManager.h"

@interface AZCoreRecordManager (ForSubclassEyesOnly)

+ (NSDictionary *) lightweightMigrationOptions;

@property (nonatomic, readonly) BOOL hasManagedObjectContext;
@property (nonatomic, readonly) BOOL hasPersistentStoreCoordinator;

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, readonly) NSURL *stackStoreURL;

- (void) setConfigurationVariable:(void(^)(id))block;

- (void) reloadPersistentStoresUnlocked;

@end
