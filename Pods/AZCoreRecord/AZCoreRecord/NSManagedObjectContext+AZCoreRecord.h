//
//  NSManagedObjectContext+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AZCoreRecordManager.h"

@interface NSManagedObjectContext (AZCoreRecord)

#pragma mark - Instance Methods

- (BOOL) save;
- (BOOL) saveRecursive: (BOOL)recursive errorHandler: (AZCoreRecordErrorBlock) errorCallback;

- (id) existingObjectWithURI: (id) URI;
- (id) existingObjectWithID: (NSManagedObjectID *) objectID;

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext;
+ (NSManagedObjectContext *) contextForCurrentThread;

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext;

#pragma mark - Ubiquity Support

- (void) startObservingUbiquitousChanges;
- (void) stopObservingUbiquitousChanges;

#pragma mark - Reset Context

+ (void) resetDefaultContext;
+ (void) resetContextForCurrentThread;

#pragma mark - Data saving

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block;

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block;
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (AZCoreRecordVoidBlock) callback;

@end
