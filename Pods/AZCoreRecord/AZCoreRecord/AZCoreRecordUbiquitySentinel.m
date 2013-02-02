//
//  AZCoreRecordUbiquitySentinel.m
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 6/22/12.
//  Copyright 2012 The Mental Faculty BV. Licensed under BSD.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordUbiquitySentinel.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreData/CoreData.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIApplication.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#import <AppKit/NSApplication.h>
#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED < 60000) || (__MAC_OS_X_VERSION_MAX_ALLOWED < 1080)
NSString *const AZUbiquityIdentityDidChangeNotification = @"NSUbiquityIdentityDidChangeNotification";
#else
NSString *const AZUbiquityIdentityDidChangeNotification = NSUbiquityIdentityDidChangeNotification;
#endif

static NSString *const AZCoreRecordManagerUbiquityIdentityTokenKey = @"ApplicationUbiquityUniqueID";

@interface AZCoreRecordUbiquitySentinel ()

@property (nonatomic) BOOL haveSentResetNotification;
@property (nonatomic) BOOL performingDeviceRegistrationCheck;
@property (nonatomic, copy) NSURL *ubiquityURL;
@property (nonatomic, strong) NSMetadataQuery *devicesListMetadataQuery;
@property (nonatomic, strong) NSFileManager *fileManager;

- (BOOL) nativelySupportsUbiquityIdentityToken;

- (void) devicesListDidUpdate: (NSNotification *) note;
- (void) startMonitoringDevicesList;
- (void) stopMonitoringDevicesList;
- (void) syncURLWithCloud: (NSURL *) URL completion: (void (^)(BOOL success, NSError *error)) block;
- (void) updateDevicesList;
- (void) updateFromPersistentStoreCoordinatorNotification: (NSNotification *) note;

@end

@implementation AZCoreRecordUbiquitySentinel

+ (AZCoreRecordUbiquitySentinel *) sharedSentinel
{
	static dispatch_once_t onceToken;
	static AZCoreRecordUbiquitySentinel *sharedSentinel = nil;
	dispatch_once(&onceToken, ^{
		sharedSentinel = [self new];
	});
	
	return sharedSentinel;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.fileManager = [NSFileManager new];
	}
	
	return self;
}

- (void) dealloc
{
	[self stopMonitoringDevicesList];
}
+ (void) load
{
	@autoreleasepool
	{
		AZCoreRecordUbiquitySentinel *sentinel = [AZCoreRecordUbiquitySentinel sharedSentinel];
		if ([sentinel nativelySupportsUbiquityIdentityToken])
			return;
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: [self sharedSentinel] selector: @selector(updateFromPersistentStoreCoordinatorNotification:) name: NSPersistentStoreCoordinatorStoresDidChangeNotification object: nil];
		
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
		id termination = UIApplicationWillTerminateNotification;
		id resume = UIApplicationDidBecomeActiveNotification;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
		id termination = NSApplicationWillTerminateNotification;
		id resume = NSApplicationDidBecomeActiveNotification;
#endif
		
		[nc addObserver: sentinel selector: @selector(stopMonitoringDevicesList) name: termination object: nil];
		[nc addObserver: sentinel selector: @selector(updateDevicesList) name: resume object: nil];
	}
}

#pragma mark - Helpers

- (void) syncURLWithCloud: (NSURL *) URL completion: (void (^)(BOOL success, NSError *error)) block
{
	NSParameterAssert(block);
	
	NSError *error;
	NSNumber *downloaded;
	if (![URL getResourceValue: &downloaded forKey: NSURLUbiquitousItemIsDownloadedKey error: &error])
	{
		// Resource doesn't exist
		block(YES, nil);
		return;
	}
	
	if (!downloaded.boolValue)
	{
		NSNumber *downloading;
		if (![URL getResourceValue: &downloading forKey: NSURLUbiquitousItemIsDownloadingKey error: &error])
		{
			block(NO, error);
			return;
		}
		
		if (!downloading.boolValue)
		{
			if (![self.fileManager startDownloadingUbiquitousItemAtURL: URL error:&error])
			{
				block(NO, error);
				return;
			}
		}
		
		// Download not complete. Schedule another check.
		dispatch_queue_t queue = dispatch_get_current_queue();
		dispatch_retain(queue);
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), queue, ^{
			[self syncURLWithCloud: URL completion: [block copy]];
			dispatch_release(queue);
		});
	}
	else
	{
		block(YES, nil);
	}
}

#pragma mark - Internal

- (void) startMonitoringDevicesList
{
	self.devicesListMetadataQuery = [NSMetadataQuery new];
	self.devicesListMetadataQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope];
	self.devicesListMetadataQuery.predicate = [NSPredicate predicateWithFormat: @"%K like %@", NSMetadataItemFSNameKey, self.presentedItemURL.lastPathComponent];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(devicesListDidUpdate:) name: NSMetadataQueryDidUpdateNotification object: self.devicesListMetadataQuery];
	[NSFileCoordinator addFilePresenter: self];
}
- (void) stopMonitoringDevicesList
{
	[NSFileCoordinator removeFilePresenter:self];
	
	[self.devicesListMetadataQuery disableUpdates];
	[self.devicesListMetadataQuery stopQuery];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	self.devicesListMetadataQuery = nil;
}

#pragma mark - Notifications

- (void) devicesListDidUpdate: (NSNotification *) note
{
	if (self.haveSentResetNotification || self.performingDeviceRegistrationCheck) return;
	[self.devicesListMetadataQuery disableUpdates];
	self.performingDeviceRegistrationCheck = YES;
	
	dispatch_queue_t completionQueue = dispatch_get_current_queue();
	dispatch_retain(completionQueue);
	
	NSURL *url = self.presentedItemURL;
	[self syncURLWithCloud: self.presentedItemURL completion: ^(BOOL success, NSError *error) {
		NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter: self];
		[coordinator coordinateReadingItemAtURL: url options: 0 error: NULL byAccessor: ^(NSURL *readURL) {
			NSArray *devices = [NSArray arrayWithContentsOfURL: readURL];
			id deviceId = [self ubiquityIdentityToken];
			BOOL deviceIsRegistered = [devices containsObject: deviceId];
			dispatch_async(completionQueue, ^{
				self.performingDeviceRegistrationCheck = NO;
				if (!deviceIsRegistered)
				{
					self.haveSentResetNotification = YES;
					[self stopMonitoringDevicesList];
					[[NSNotificationCenter defaultCenter] postNotificationName: AZUbiquityIdentityDidChangeNotification object: self userInfo: nil];
				}
				else
				{
					[self.devicesListMetadataQuery enableUpdates];
				}
				
				dispatch_release(completionQueue);
			});
		}];
	}];
}
- (void) updateDevicesList
{
	if (!self.ubiquityAvailable)
		return;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self syncURLWithCloud: self.presentedItemURL completion: ^(BOOL success, NSError *error) {
			if (!success) return;
			
			__block BOOL updated = NO;
			__block NSMutableArray *devices = nil;
			NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter: self];
			[coordinator coordinateReadingItemAtURL: self.presentedItemURL options: 0 error: NULL byAccessor: ^(NSURL *readURL) {
				devices = [NSMutableArray arrayWithContentsOfURL: readURL];
				if (!devices) devices = [NSMutableArray array];
				
				id deviceID = [self ubiquityIdentityToken];
				
				if (![devices containsObject: deviceID])
				{
					[devices addObject: deviceID];
					updated = YES;
				}
			}];
			
			[coordinator coordinateWritingItemAtURL: self.ubiquityURL options: 0 error: NULL byAccessor: ^(NSURL *newURL) {
				NSFileManager *fm = [[NSFileManager alloc] init];
				[fm createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
			}];
			
			if (updated) [coordinator coordinateWritingItemAtURL: self.presentedItemURL options: NSFileCoordinatorWritingForReplacing error: NULL byAccessor: ^(NSURL *writeURL) {
				[devices writeToURL: writeURL atomically: YES];
			}];
		}];
	});
}
- (void) updateFromPersistentStoreCoordinatorNotification: (NSNotification *) note
{
	if (!self.ubiquityAvailable)
		return;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#if TARGET_IPHONE_SIMULATOR
		self.ubiquityURL = nil;
#else
		self.ubiquityURL = [self.fileManager URLForUbiquityContainerIdentifier:nil];
#endif

		NSArray *newStores = [note.userInfo objectForKey: NSAddedPersistentStoresKey];
		NSUInteger foundIndex = [newStores indexOfObjectPassingTest: ^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
			NSDictionary *storeOptions = store.options;
			return ([storeOptions objectForKey: NSPersistentStoreUbiquitousContentNameKey] != nil && [storeOptions objectForKey: NSPersistentStoreUbiquitousContentURLKey] != nil);
		}];

		if (foundIndex != NSNotFound)
			[self updateDevicesList];
	});
}

#pragma mark - Utilities

- (BOOL) nativelySupportsUbiquityIdentityToken
{
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 60000) || (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1080)
	return [NSFileManager instancesRespondToSelector: @selector(ubiquityIdentityToken)];
#else
	return NO;
#endif
}
- (BOOL) isUbiquityAvailable
{
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 60000) || (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1080)
	if (self.nativelySupportsUbiquityIdentityToken)
		return !![self.fileManager ubiquityIdentityToken];
#endif
	
	return !!self.ubiquityURL;
}

- (id <NSObject, NSCopying, NSCoding>) ubiquityIdentityToken
{
	if (!self.ubiquityAvailable)
		return nil;
	
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 60000) || (__MAC_OS_X_VERSION_MAX_ALLOWED >= 1080)
	if (self.nativelySupportsUbiquityIdentityToken)
		return [self.fileManager ubiquityIdentityToken];
#endif

	NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
	id uniqueID = [sud objectForKey: AZCoreRecordManagerUbiquityIdentityTokenKey];
	
	if (!uniqueID)
	{
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuid);
		CFRelease(uuid);

		unsigned char hash[CC_SHA1_DIGEST_LENGTH];
		CC_SHA1(&bytes, sizeof(bytes), hash);

		uniqueID = [NSData dataWithBytes: hash length: CC_SHA1_DIGEST_LENGTH];
		[sud setObject: uniqueID forKey: AZCoreRecordManagerUbiquityIdentityTokenKey];
		[sud synchronize];
	}
	
	return uniqueID;
}

- (void) setUbiquityURL: (NSURL *) ubiquityURL
{
	if (self.devicesListMetadataQuery) [self stopMonitoringDevicesList];
	_ubiquityURL = [ubiquityURL copy];
	if (self.ubiquityURL) [self startMonitoringDevicesList];
}

#pragma mark - NSFilePresenter

- (NSOperationQueue *) presentedItemOperationQueue
{
	static dispatch_once_t onceToken;
	static NSOperationQueue *presentedItemOperationQueue = nil;
	dispatch_once(&onceToken, ^{
		presentedItemOperationQueue = [NSOperationQueue new];
	});
	
	return presentedItemOperationQueue;
}

- (NSURL *) presentedItemURL
{
	if (!self.ubiquityURL)
		return nil;
	
	return [self.ubiquityURL URLByAppendingPathComponent: @"UbiquitousSyncingDevices.plist"];
}

- (void) accommodatePresentedItemDeletionWithCompletionHandler: (void (^)(NSError *)) completionHandler
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateDevicesList];
		[[NSNotificationCenter defaultCenter] postNotificationName: AZUbiquityIdentityDidChangeNotification object: nil];
		completionHandler(NULL);
	});
}
- (void) presentedItemDidChange
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateDevicesList];
	});
}

@end

