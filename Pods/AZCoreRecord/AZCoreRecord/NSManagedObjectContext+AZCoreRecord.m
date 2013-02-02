//
//  NSManagedObjectContext+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectContext+AZCoreRecord.h"
#import "AZCoreRecordManager.h"
#import <objc/runtime.h>
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"

@implementation NSManagedObjectContext (AZCoreRecord)

#pragma mark - Instance Methods

- (BOOL) save
{
	return [self saveRecursive: NO errorHandler: NULL];
}
- (BOOL) saveRecursive: (BOOL)recursive errorHandler: (AZCoreRecordErrorBlock) errorCallback
{
	__block BOOL success = YES;
	__block NSError *error = nil;
	NSManagedObjectContext *context = self;

	void (^save)(NSManagedObjectContext *) = ^(NSManagedObjectContext *ctx){
		if (ctx.concurrencyType == NSConfinementConcurrencyType) {
			success = [ctx save: &error];
		} else {
			[ctx performBlockAndWait: ^{
				success = [ctx save: &error];
			}];
		}
	};

	if (recursive) {
		while (success && error == nil && context != nil) {
			save(context);
			context = context.parentContext;
		}
	} else {
		save(context);
	}

	if (!success) {
		if (errorCallback)
			errorCallback(error);
		else
			[AZCoreRecordManager handleError: error];
	}

	return success;
}

- (id) existingObjectWithURI: (id) URI
{
	NSParameterAssert(URI);
	
	if ([URI isKindOfClass:[NSString class]])
		URI = [NSURL URLWithString:URI];
	
	if ([URI isKindOfClass:[NSURL class]])
		URI = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation: URI];
	
	if (!URI || ![URI isKindOfClass:[NSManagedObjectID class]])
		return nil;
	
	return [self existingObjectWithID: URI];
}

- (id) existingObjectWithID: (NSManagedObjectID *) objectID
{
	NSError *error = nil;
	id ret = [self existingObjectWithID: objectID error: &error];
	[AZCoreRecordManager handleError: error];
	return ret;
}

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext
{
	return [[AZCoreRecordManager defaultManager] managedObjectContext];
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
	return [[AZCoreRecordManager defaultManager] contextForCurrentThread];
}

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext
{
	NSManagedObjectContext *context = [[[self class] alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	context.parentContext = self;	
	return context;
}

#pragma mark - Ubiquity Support

- (void) azcr_mergeUbiquitousChanges: (NSNotification *) notification
{
	[self performBlock: ^{
		[self mergeChangesFromContextDidSaveNotification: notification];
	}];
}

- (void) startObservingUbiquitousChanges
{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(azcr_mergeUbiquitousChanges:) name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: self.persistentStoreCoordinator];
}

- (void) stopObservingUbiquitousChanges
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: self.persistentStoreCoordinator];
}

#pragma mark - Reset Context

+ (void) resetDefaultContext
{
	NSManagedObjectContext *context = [[AZCoreRecordManager defaultManager] managedObjectContext];
	[context performBlockAndWait: ^{
		[context reset];
	}];
}
+ (void) resetContextForCurrentThread 
{
	[[NSManagedObjectContext contextForCurrentThread] reset];
}

#pragma mark - Data saving

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block
{
	NSParameterAssert(block != nil);
	
	if (self.concurrencyType == NSConfinementConcurrencyType) {
		block(self);
	} else {
		[self performBlockAndWait: ^{
			NSManagedObjectContext *localContext = [self newChildContext];
			
			NSMergePolicy *backupMergePolicy = self.mergePolicy;
			self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			localContext.mergePolicy = NSOverwriteMergePolicy;
			
			block(localContext);
			
			[localContext save];
			
			self.mergePolicy = backupMergePolicy;
		}];
	}

	[self save];
}

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block
{
	[self saveDataInBackgroundWithBlock: block completion: NULL];
}

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (AZCoreRecordVoidBlock) callback
{
	NSParameterAssert(block != nil);
	NSParameterAssert(self.concurrencyType != NSConfinementConcurrencyType);
	
	[self performBlock: ^{
		NSManagedObjectContext *localContext = [self newChildContext];
		
		NSMergePolicy *backupMergePolicy = self.mergePolicy;
		self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
		localContext.mergePolicy = NSOverwriteMergePolicy;
		
		block(localContext);
		
		[localContext save];
		
		self.mergePolicy = backupMergePolicy;
		
		[self save];
		
		if (callback)
			dispatch_async(dispatch_get_main_queue(), callback);
	}];
}

@end
