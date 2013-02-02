//
//  AZCoreRecordUbiquitousManager.m
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 11/8/12.
//  Copyright 2012 Pandamonia LLC. All rights reserved.
//

#import "AZCoreRecordUbiquitousManager.h"
#import "AZCoreRecordUbiquitySentinel.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"

NSString *const AZCoreRecordManagerDidAddUbiquitousStoreNotification = @"AZCoreRecordManagerDidAddUbiquitousStoreNotification";
NSString *const AZCoreRecordManagerWillAddUbiquitousStoreNotification = @"AZCoreRecordManagerWillAddUbiquitousStoreNotification";
NSString *const AZCoreRecordLocalOnlyStoreConfigurationNameKey = @"LocalOnlyStore";
NSString *const AZCoreRecordUbiquitousStoreConfigurationNameKey = @"UbiquitousStore";

@interface AZCoreRecordUbiquitousManager ()

@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityToken;

@end

@implementation AZCoreRecordUbiquitousManager

+ (AZCoreRecordUbiquitousManager *) defaultManager
{
	return (AZCoreRecordUbiquitousManager *) [super defaultManager];
}

#pragma mark AZCoreRecordManager

- (id) initWithStackName: (NSString *) name
{
	NSParameterAssert(name);

	if ((self = [super initWithStackName: name]))
	{
		self.ubiquityToken = [[AZCoreRecordUbiquitySentinel sharedSentinel] ubiquityIdentityToken];

		//subscribe to the account change notification
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(azcr_didChangeUbiquityIdentityNotification:)
													 name: AZUbiquityIdentityDidChangeNotification
												   object: nil];
	}

	return self;
}

- (void) loadPersistentStoresWithCompletion:(void(^)(void))completionBlock {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSString *localConfiguration = [self.stackModelConfigurations objectForKey: AZCoreRecordLocalOnlyStoreConfigurationNameKey];
	NSString *ubiquitousConfiguration = [self.stackModelConfigurations objectForKey: AZCoreRecordUbiquitousStoreConfigurationNameKey];
	NSURL *localURL = self.localOnlyStoreURL;
	NSURL *fallbackURL = self.storeURL;
	NSURL *ubiquityURL = self.ubiquitousStoreURL;
#if TARGET_IPHONE_SIMULATOR
	NSURL *ubiquityContainer = nil;
#else
	NSURL *ubiquityContainer = [self.fileManager URLForUbiquityContainerIdentifier:nil];
#endif

	NSDictionary *options = (self.stackShouldUseUbiquity || self.stackShouldAutoMigrateStore) ? [[self class] lightweightMigrationOptions] : [NSDictionary dictionary];

	if (localConfiguration.length)
	{
		if (![self.fileManager fileExistsAtPath: localURL.path])
		{
			NSURL *bundleURL = [[NSBundle mainBundle] URLForResource: localURL.lastPathComponent.stringByDeletingPathExtension withExtension: localURL.pathExtension];
			if (bundleURL)
			{
				NSError *error = nil;
				if (![self.fileManager copyItemAtURL: bundleURL toURL: localURL error: &error])
				{
					[AZCoreRecordManager handleError: error];
					return;
				}
			}
		}

		[self.persistentStoreCoordinator addStoreAtURL: localURL configuration: localConfiguration options: options];
	}

	dispatch_block_t addFallback = ^{

		NSMutableDictionary *storeOptions = [options mutableCopy];

		if (self.stackShouldUseInMemoryStore)
			[self.persistentStoreCoordinator addInMemoryStoreWithConfiguration: ubiquitousConfiguration options: storeOptions];
		else
			[self.persistentStoreCoordinator addStoreAtURL: fallbackURL configuration: ubiquitousConfiguration options: storeOptions];

		[nc postNotificationName: AZCoreRecordManagerDidAddPrimaryStoreNotification object: self];
		_ubiquityEnabled = NO;
	};

	if (self.stackShouldUseUbiquity && ubiquityURL) {
		[nc postNotificationName: AZCoreRecordManagerWillAddUbiquitousStoreNotification object: self];

		dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(globalQueue, ^{
			NSMutableDictionary *storeOptions = [options mutableCopy];
			BOOL fallback = NO;

			if (ubiquityContainer)
			{
				[storeOptions setObject: @"UbiquitousStore" forKey: NSPersistentStoreUbiquitousContentNameKey];
				[storeOptions setObject: [ubiquityContainer URLByAppendingPathComponent: @"UbiquitousData"] forKey: NSPersistentStoreUbiquitousContentURLKey];
			}
			else
			{
				[storeOptions setObject: [NSNumber numberWithBool: YES] forKey: NSReadOnlyPersistentStoreOption];
				fallback = YES;
			}

			if ([self.persistentStoreCoordinator addStoreAtURL: ubiquityURL configuration: ubiquitousConfiguration options: storeOptions])
			{
				[nc postNotificationName: AZCoreRecordManagerDidAddUbiquitousStoreNotification object: self];
				if (self.managedObjectContext)
					[self.managedObjectContext startObservingUbiquitousChanges];
				_ubiquityEnabled = YES;
			}
			else
			{
				fallback = YES;
			}

			if (fallback) addFallback();
			if (completionBlock) completionBlock();
		});
	} else {
		addFallback();
		if (completionBlock) completionBlock();
	}
}

- (void) setManagedObjectContext: (NSManagedObjectContext *) managedObjectContext
{
	BOOL isUbiquitous = self.ubiquityEnabled;

	if (isUbiquitous && self.hasManagedObjectContext)
		[self.managedObjectContext stopObservingUbiquitousChanges];

	[super setManagedObjectContext: managedObjectContext];

	if (isUbiquitous && self.hasManagedObjectContext) {
		[managedObjectContext startObservingUbiquitousChanges];
	}
}
- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (self.hasPersistentStoreCoordinator) {
		[nc removeObserver: self name: AZCoreRecordDidFinishSeedingPersistentStoreNotification object: self.persistentStoreCoordinator];
		[nc removeObserver: self name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: self.persistentStoreCoordinator];
	}

	[super setPersistentStoreCoordinator: persistentStoreCoordinator];

	if (self.hasPersistentStoreCoordinator) {
		[nc addObserver: self selector: @selector(azcr_didRecieveDeduplicationNotification:) name: AZCoreRecordDidFinishSeedingPersistentStoreNotification object: self.persistentStoreCoordinator];
		[nc addObserver: self selector: @selector(azcr_didRecieveDeduplicationNotification:) name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: self.persistentStoreCoordinator];
	}
}

#pragma mark - Read-only accessors

- (BOOL) isReadOnly
{
	if (!self.stackShouldUseUbiquity)
		return NO;

	return self.ubiquityToken && [(NSData *) self.ubiquityToken length];
}

- (NSURL *) localOnlyStoreURL
{
	return [self.stackStoreURL URLByAppendingPathComponent: @"LocalStore.sqlite"];
}
- (NSURL *) ubiquitousStoreURL
{
	if (![(NSData *) self.ubiquityToken length])
		return nil;

	NSURL *tokenURL = [self.stackStoreURL URLByAppendingPathComponent: @"TokenFoldersData.plist"];
	NSData *tokenData = [NSData dataWithContentsOfURL: tokenURL];

	NSMutableDictionary *foldersByToken = nil;

	if (tokenData)
		foldersByToken = [NSKeyedUnarchiver unarchiveObjectWithData: tokenData];
	else
		foldersByToken = [NSMutableDictionary dictionary];

	NSString *storeDirectoryUUID = [foldersByToken objectForKey: self.ubiquityToken];
	if (!storeDirectoryUUID)
	{
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		storeDirectoryUUID = (__bridge_transfer NSString *) CFUUIDCreateString(kCFAllocatorDefault, uuid);
		CFRelease(uuid);

		[foldersByToken setObject: storeDirectoryUUID forKey: self.ubiquityToken];
		tokenData = [NSKeyedArchiver archivedDataWithRootObject: foldersByToken];
		[tokenData writeToFile: tokenURL.path atomically: YES];
	}

	NSURL *iCloudStoreURL = [self.stackStoreURL URLByAppendingPathComponent: storeDirectoryUUID];

	if (![self.fileManager fileExistsAtPath: iCloudStoreURL.path])
	{
		NSError *error = nil;
		[self.fileManager createDirectoryAtURL: iCloudStoreURL withIntermediateDirectories: YES attributes: nil error: &error];
		[AZCoreRecordManager handleError: error];
	}

	return [iCloudStoreURL URLByAppendingPathComponent: @"UbiquitousStore.sqlite"];
}

#pragma mark - Ubiquity Support

+ (BOOL) supportsUbiquity
{
	return [[AZCoreRecordUbiquitySentinel sharedSentinel] isUbiquityAvailable];
}

- (void) setUbiquityEnabled: (BOOL) enabled
{
	if (_ubiquityEnabled == enabled)
		return;

	[self lock];

	_stackShouldUseUbiquity = enabled;
	self.ubiquityToken = [[AZCoreRecordUbiquitySentinel sharedSentinel] ubiquityIdentityToken];
	[self reloadPersistentStoresUnlocked];

	[self unlock];
}

- (void) setStackShouldUseUbiquity: (BOOL) stackShouldUseUbiquity
{
	[self setConfigurationVariable:^(AZCoreRecordUbiquitousManager *manager){
		manager->_stackShouldUseUbiquity = stackShouldUseUbiquity;
	}];
}

#pragma mark -

- (void) azcr_didChangeUbiquityIdentityNotification: (NSNotification *) note
{
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		[self lock];

		self.ubiquityToken = [[AZCoreRecordUbiquitySentinel sharedSentinel] ubiquityIdentityToken];
		[self reloadPersistentStoresUnlocked];

		[self unlock];
	});
}

@end
