//
//  NSPersistentStoreCoordinator+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "AZCoreRecordManager.h"
#import "NSManagedObjectModel+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"

NSString *const AZCoreRecordDidFinishSeedingPersistentStoreNotification = @"AZCoreRecordDidFinishSeedingPersistentStoreNotification";

@implementation NSPersistentStoreCoordinator (AZCoreRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	return [[AZCoreRecordManager defaultManager] persistentStoreCoordinator];
}

#pragma mark - In-Memory Store

- (NSPersistentStore *) addInMemoryStoreWithConfiguration: (NSString *)configuration options: (NSDictionary *)options
{
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType: NSInMemoryStoreType configuration: configuration URL: nil options: options error: &error];
	[AZCoreRecordManager handleError: error];
	return store;
}

- (NSPersistentStore *) addInMemoryStore
{
	return [self addInMemoryStoreWithConfiguration: nil options: nil];
}

- (NSPersistentStore *) addStoreAtURL: (NSURL *)URL configuration: (NSString *)configuration options: (NSDictionary *)options
{
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType: NSSQLiteStoreType configuration: configuration URL: URL options: options error: &error];
	[AZCoreRecordManager handleError: error];
	return store;
}

#pragma mark - Seeding stores

- (void) seedWithPersistentStoreAtURL: (NSURL *) oldStoreURL usingBlock: (AZCoreRecordSeedBlock) block
{
	NSParameterAssert(block);
	
	if (![[NSFileManager defaultManager] fileExistsAtPath: oldStoreURL.path])
		return;
	
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		void (^unlock)(void) = ^{
			[self unlock];
		};
		
		[self lock];
		
		NSPersistentStoreCoordinator *oldPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.managedObjectModel];
		NSDictionary *oldPSOption = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES] forKey: NSReadOnlyPersistentStoreOption];
		
		__block NSString *configuration = nil;
		[self.persistentStores enumerateObjectsUsingBlock:^(NSPersistentStore *obj, NSUInteger idx, BOOL *stop) {
			if ([obj.options objectForKey: NSPersistentStoreUbiquitousContentNameKey]) {
				configuration = obj.configurationName;
				*stop = YES;
			}
		}];
		
		if (![oldPSC addStoreAtURL: oldStoreURL configuration: configuration options: oldPSOption])
		{
			unlock();
			return;
		}
		
		NSManagedObjectContext *oldMOC = [[NSManagedObjectContext alloc] init];
		[oldMOC setPersistentStoreCoordinator: oldPSC];
		
		NSManagedObjectContext *newMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[newMOC setPersistentStoreCoordinator: self];
		
		block(oldMOC, newMOC);
		
		if ([newMOC hasChanges] && [newMOC save])
			[newMOC reset];
		
		NSError *error;
		[[NSFileManager defaultManager] removeItemAtURL: oldStoreURL error: &error];
		[AZCoreRecordManager handleError: error];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: AZCoreRecordDidFinishSeedingPersistentStoreNotification object: self];
		
		unlock();
	});
}

@end
