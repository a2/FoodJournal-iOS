//
//  AZCoreRecordManager.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <objc/runtime.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	#import <UIKit/UIApplication.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
	#import <AppKit/NSApplication.h>
#endif

#import "AZCoreRecordManager.h"
#import "AZCoreRecordUbiquitousManager.h"
#import "AZCoreRecordUbiquitySentinel.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObject+AZCoreRecord.h"
#import "NSManagedObject+AZCoreRecordImport.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

NSString *const AZCoreRecordManagerWillBeginAddingPersistentStoresNotification = @"AZCoreRecordManagerWillBeginAddingPersistentStoresNotification";
NSString *const AZCoreRecordManagerDidAddPrimaryStoreNotification = @"AZCoreRecordManagerDidAddPrimaryStoreNotification";
NSString *const AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification = @"AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification";

NSString *const AZCoreRecordManagerShouldRunDeduplicationNotification = @"AZCoreRecordManagerShouldRunDeduplicationNotification";

NSString *const AZCoreRecordDeduplicationIdentityAttributeKey = @"identityAttribute";

static __weak id <AZCoreRecordErrorHandler> errorDelegate;
static AZCoreRecordErrorBlock errorHandler;

@interface AZCoreRecordManager ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSFileManager *fileManager;

@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) NSMutableDictionary *conflictResolutionHandlers;

@end

@implementation AZCoreRecordManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Setup and teardown

- (id) init
{
	[NSException raise: NSInvalidArgumentException format: @"AZCoreRecordManager must be initialized using -initWithStackName:"];
	return nil;
}
- (id) initWithStackName: (NSString *) name
{
	NSParameterAssert(name);
	
	if ((self = [super init]))
	{
		_stackName = [name copy];
		_semaphore = dispatch_semaphore_create(1);
		_stackManagedObjectContextClass = [NSManagedObjectContext class];
		
		self.conflictResolutionHandlers = [NSMutableDictionary dictionary];
		self.fileManager = [NSFileManager new];
	}
	
	return self;
}

- (void) dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver: self];
	if (_managedObjectContext) [nc removeObserver: _managedObjectContext];
	dispatch_release(_semaphore);
}

#pragma mark - NSLocking

- (void)lock {
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
}

- (void)unlock {
	dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Stack storage

- (NSManagedObjectContext *) contextForCurrentThread
{
	if ([NSThread isMainThread])
		return self.managedObjectContext;
	
	NSManagedObjectContext *context = nil;
	
	[self lock];
	
	NSThread *thread = [NSThread currentThread];
	NSMutableDictionary *dict = [thread threadDictionary];
	NSString *key = self.stackName;
	context = [dict objectForKey: self.stackName];
	if (!context)
	{
		context = [self.managedObjectContext newChildContext];
		[dict setObject: context forKey: key];
		
		__block __weak id observer = [[NSNotificationCenter defaultCenter] addObserverForName: NSThreadWillExitNotification object: thread queue: nil usingBlock: ^(NSNotification *note) {
			NSThread *thread = [note object];
			NSManagedObjectContext *context = [thread.threadDictionary objectForKey: key];
			[context reset];
			[[NSNotificationCenter defaultCenter] removeObserver: observer];
		}];
	}
	
	[self unlock];
	
	return context;
}

- (BOOL) hasManagedObjectContext
{
	return !!_managedObjectContext;
}
- (NSManagedObjectContext *) managedObjectContext
{
	if (!_managedObjectContext)
	{
		NSManagedObjectContext *managedObjectContext = [[self.stackManagedObjectContextClass alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
		managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
		self.managedObjectContext = managedObjectContext;
	}
	
	return _managedObjectContext;
}
- (void) setManagedObjectContext: (NSManagedObjectContext *) managedObjectContext
{
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	id key = UIApplicationWillTerminateNotification;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
	id key = NSApplicationWillTerminateNotification;
#endif

	if (_managedObjectContext) {
		[[NSNotificationCenter defaultCenter] removeObserver: _managedObjectContext name: key object: nil];
	}
	
	_managedObjectContext = managedObjectContext;
	
	if (_managedObjectContext) {
		[[NSNotificationCenter defaultCenter] addObserver: _managedObjectContext selector: @selector(save) name: key object: nil];
	}
}

- (BOOL) hasPersistentStoreCoordinator
{
	return !!_persistentStoreCoordinator;
}
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
	if (!_persistentStoreCoordinator)
	{
		NSManagedObjectModel *model = nil;
		NSURL *modelURL = self.stackModelURL;
		NSString *modelName = self.stackModelName;

		if (!modelURL && modelName) {
			model = [NSManagedObjectModel modelWithName: modelName];
		} else if (modelURL) {
			model = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
		} else {
			model = [NSManagedObjectModel mergedModelFromBundles: nil];
		}

		self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
	}

	return _persistentStoreCoordinator;
}
- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (_persistentStoreCoordinator) {
		[self azcr_resetStack];
	}

	_persistentStoreCoordinator = persistentStoreCoordinator;

	if (_persistentStoreCoordinator) {
		[self azcr_loadPersistentStores: YES];
	}
}

#pragma mark - Helpers

- (NSURL *) storeURL
{
	return [self.stackStoreURL URLByAppendingPathComponent: @"Store.sqlite"];
}
- (NSURL *) stackStoreURL
{
	static dispatch_once_t onceToken;
	static NSURL *appSupportURL = nil;
	dispatch_once(&onceToken, ^{
		NSURL *appSupportRoot = [[self.fileManager URLsForDirectory: NSApplicationSupportDirectory inDomains: NSUserDomainMask] lastObject];
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
		appSupportURL = [appSupportRoot URLByAppendingPathComponent: applicationName isDirectory: YES];
	});
	
	NSString *storeName = self.stackName.lastPathComponent;
	NSURL *storeDirectory = [storeName isEqualToString: appSupportURL.lastPathComponent] ? appSupportURL : [appSupportURL URLByAppendingPathComponent: storeName isDirectory: YES];
	
	if (![self.fileManager fileExistsAtPath: storeDirectory.path])
	{
		NSError *error = nil;
		[self.fileManager createDirectoryAtURL: storeDirectory withIntermediateDirectories: YES attributes: nil error: &error];
		[AZCoreRecordManager handleError: error];
	}
	
	return storeDirectory;
}

#pragma mark - Persistent stores

+ (NSDictionary *) lightweightMigrationOptions
{
	static NSDictionary *lightweightMigrationOptions = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		lightweightMigrationOptions = @{
			NSMigratePersistentStoresAutomaticallyOption : @(YES),
			NSInferMappingModelAutomaticallyOption : @(YES)
		};
	});
	
	return lightweightMigrationOptions;
}

- (void) loadPersistentStoresWithCompletion:(void(^)(void))completionBlock {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	NSURL *fallbackURL = self.storeURL;

	NSDictionary *options = self.stackShouldAutoMigrateStore ? [[self class] lightweightMigrationOptions] : nil;

	if (self.stackShouldUseInMemoryStore)
		[self.persistentStoreCoordinator addInMemoryStoreWithConfiguration: nil options: options];
	else
		[self.persistentStoreCoordinator addStoreAtURL: fallbackURL configuration: nil options: options];

	[nc postNotificationName: AZCoreRecordManagerDidAddPrimaryStoreNotification object: self];

	if (completionBlock) completionBlock();
}

- (void) azcr_loadPersistentStores: (BOOL) obtainLock
{
	if (obtainLock) [self lock];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: AZCoreRecordManagerWillBeginAddingPersistentStoresNotification object: self];
	
	[self azcr_resetStack];

	[self loadPersistentStoresWithCompletion:^{
		[nc postNotificationName: AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification object: self];
		if (obtainLock) [self unlock];
	}];
}
- (void)reloadPersistentStoresUnlocked {
	if (self.hasPersistentStoreCoordinator) [self azcr_loadPersistentStores: NO];
}

- (void) azcr_resetStack
{
	if (_managedObjectContext)
	{
		[self.managedObjectContext performBlockAndWait: ^{
			[self.managedObjectContext reset];
		}];
	}
	
	if (_persistentStoreCoordinator)
	{
		[self.persistentStoreCoordinator lock];
		
		[self.persistentStoreCoordinator.persistentStores enumerateObjectsUsingBlock:^(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
			NSError *error = nil;
			[self.persistentStoreCoordinator removePersistentStore: store error: &error];
			[AZCoreRecordManager handleError: error];
		}];
		
		[self.persistentStoreCoordinator unlock];
	}
}

#pragma mark - Stack Settings

- (void) setConfigurationVariable:(void(^)(id))block {
	[self lock];

	[self azcr_resetStack];
	block(self);

	[self unlock];
}

- (void) configureWithManagedDocument: (id) managedDocument
{
	Class documentClass = NULL;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	documentClass = NSClassFromString(@"UIManagedDocument");
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
	documentClass = NSClassFromString(@"NSPersistentDocument");
#endif
	
	NSAssert(documentClass, @"Not available on this OS.");
	NSParameterAssert([managedDocument isKindOfClass:documentClass]);

	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager.persistentStoreCoordinator = [[managedDocument managedObjectContext] persistentStoreCoordinator];
		manager.managedObjectContext = [managedDocument managedObjectContext];
	}];
}
- (void) setStackModelName: (NSString *) stackModelName
{
	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager->_stackModelName = [stackModelName copy];
	}];
}
- (void) setStackModelURL: (NSURL *) stackModelURL
{
	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager->_stackModelURL = [stackModelURL copy];
	}];
}
- (void) setStackModelConfigurations:(NSDictionary *)stackModelConfigurations
{
	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager->_stackModelConfigurations = [stackModelConfigurations copy];
	}];
}
- (void) setStackShouldAutoMigrateStore: (BOOL) stackShouldAutoMigrateStore
{
	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager->_stackShouldAutoMigrateStore = stackShouldAutoMigrateStore;
	}];
}
- (void) setStackShouldUseInMemoryStore: (BOOL) stackShouldUseInMemoryStore
{
	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager->_stackShouldUseInMemoryStore = stackShouldUseInMemoryStore;
	}];
}
- (void) setStackManagedObjectContextClass:(Class)stackManagedObjectContextClass
{
	[self setConfigurationVariable:^(AZCoreRecordManager *manager) {
		manager->_stackManagedObjectContextClass = stackManagedObjectContextClass;
	}];
}

#pragma mark - Default stack settings

static AZCoreRecordManager *_sharedManager = nil;
static Class _defaultStackClass = NULL;

+ (AZCoreRecordManager *) defaultManager
{
	if (!_sharedManager) {
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
		Class stackClass = _defaultStackClass ?: [self class];
		self.defaultManager = [[stackClass alloc] initWithStackName: applicationName];
	}
	return _sharedManager;
}

+ (void) setDefaultManager:(AZCoreRecordManager *)manager
{
	@synchronized(self) {
		_sharedManager = manager;
	}
}

+ (void) setDefaultManagerClass:(Class)class {
	@synchronized(self) {
		_defaultStackClass = class;
	}
}

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate
{
	[[self defaultManager] setStackShouldAutoMigrateStore: shouldMigrate];
}
+ (void) setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory
{
	[[self defaultManager] setStackShouldUseInMemoryStore: inMemory];
}
+ (void) setDefaultStackShouldUseUbiquity: (BOOL) usesUbiquity
{
	if (usesUbiquity)
		[self setDefaultManagerClass: [AZCoreRecordUbiquitousManager class]];

	[(AZCoreRecordUbiquitousManager *)[self defaultManager] setStackShouldUseUbiquity: usesUbiquity];
}
+ (void) setDefaultStackModelName: (NSString *) name
{
	[[self defaultManager] setStackModelName: name];
}
+ (void) setDefaultStackModelURL: (NSURL *) name
{
	[[self defaultManager] setStackModelURL: name];
}
+ (void) setDefaultStackModelConfigurations: (NSDictionary *) dictionary
{
	[[self defaultManager] setStackModelConfigurations: dictionary];
}
+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject
{
	[[self defaultManager] configureWithManagedDocument: managedObject];
}

#pragma mark - Deduplication

- (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler forEntityName: (NSString *) entityName includeSubentities: (BOOL) includeSubentities
{
	NSParameterAssert(entityName != nil);
	NSParameterAssert(handler != nil);
	
	if (includeSubentities) entityName = [@"+" stringByAppendingString: entityName];
	[self.conflictResolutionHandlers setObject: [handler copy] forKey: entityName];
}

- (void) azcr_didRecieveDeduplicationNotification: (NSNotification *) note
{
	[[NSNotificationCenter defaultCenter] postNotificationName: AZCoreRecordManagerShouldRunDeduplicationNotification object: self];

	if (!self.conflictResolutionHandlers.count)
		return;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[self lock];

		[self saveDataInBackgroundWithBlock: ^(NSManagedObjectContext *context) {
			[self.conflictResolutionHandlers enumerateKeysAndObjectsUsingBlock: ^(NSString *entityName, AZCoreRecordDeduplicationHandlerBlock handler, BOOL *stop) {
				BOOL includesSubentities = NO;
				if ([entityName hasPrefix: @"+"])
				{
					includesSubentities = YES;
					entityName = [entityName substringFromIndex: 1];
				}

				NSEntityDescription *entityDescription = [context.persistentStoreCoordinator.managedObjectModel.entitiesByName objectForKey: entityName];
				NSArray *identityAttributes = [[entityDescription.userInfo objectForKey: AZCoreRecordDeduplicationIdentityAttributeKey] componentsSeparatedByString: @","];

				NSFetchRequest *masterFetchRequest = [[NSFetchRequest alloc] init];
				masterFetchRequest.entity = entityDescription;
				masterFetchRequest.fetchBatchSize = [NSManagedObject defaultBatchSize];
				masterFetchRequest.includesPendingChanges = NO;
				masterFetchRequest.includesSubentities = includesSubentities;
				masterFetchRequest.resultType = NSDictionaryResultType;

				NSMutableArray *propertiesToFetch = [NSMutableArray arrayWithCapacity: identityAttributes.count * 2];
				NSMutableArray *propertiesToGroupBy = [NSMutableArray arrayWithCapacity: identityAttributes.count];

				[identityAttributes enumerateObjectsUsingBlock: ^(NSString *identityAttribute, NSUInteger idx, BOOL *stop) {
					NSAttributeDescription *attributeDescription = [entityDescription.propertiesByName objectForKey: identityAttribute];
					[propertiesToFetch addObject: attributeDescription];
					[propertiesToGroupBy addObject: attributeDescription];

					NSExpressionDescription *countExpressionDescription = [[NSExpressionDescription alloc] init];
					countExpressionDescription.name = [NSString stringWithFormat: @"%@Count", identityAttribute];
					countExpressionDescription.expression = [NSExpression expressionWithFormat: @"count:(%K)", identityAttribute];
					countExpressionDescription.expressionResultType = NSInteger64AttributeType;
					[propertiesToFetch addObject: countExpressionDescription];
				}];

				masterFetchRequest.propertiesToFetch = propertiesToFetch;
				masterFetchRequest.propertiesToGroupBy = propertiesToGroupBy;

				NSError *error;
				NSMutableArray *dictionaryResults = [[context executeFetchRequest: masterFetchRequest error: &error] mutableCopy];
				[AZCoreRecordManager handleError: error];

				NSFetchRequest *fetchRequestTemplate = [[NSFetchRequest alloc] init];
				fetchRequestTemplate.entity = entityDescription;
				fetchRequestTemplate.fetchBatchSize = [NSManagedObject defaultBatchSize];
				fetchRequestTemplate.includesPendingChanges = NO;
				fetchRequestTemplate.includesSubentities = includesSubentities;

				[dictionaryResults enumerateObjectsUsingBlock: ^(NSDictionary *dictionaryResult, NSUInteger _idx, BOOL *stop) {
					__block BOOL hasDuplicates = YES;

					[propertiesToFetch enumerateObjectsUsingBlock: ^(NSExpressionDescription *expressionDescription, NSUInteger idx, BOOL *stop) {
						if (idx % 2 == 0) return;

						NSNumber *value = [dictionaryResult objectForKey: expressionDescription.name];
						if ([value integerValue] < 2)
						{
							hasDuplicates = NO;
							*stop = YES;
						}
					}];

					if (!hasDuplicates)
						return;

					NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity: identityAttributes.count];
					[identityAttributes enumerateObjectsUsingBlock: ^(NSString *identityAttribute, NSUInteger idx, BOOL *stop) {
						NSPredicate *subpredicate = [NSPredicate predicateWithFormat: @"%K == %@", identityAttribute, [dictionaryResult valueForKey: identityAttribute]];
						[subpredicates addObject: subpredicate];
					}];

					NSFetchRequest *fetchRequest = [fetchRequestTemplate copy];
					fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates: subpredicates];;

					NSError *error;
					NSMutableArray *duplicateGroup = [[context executeFetchRequest: fetchRequest error: &error] mutableCopy];
					[AZCoreRecordManager handleError: error];

					NSArray *resultingObjects = handler(duplicateGroup, identityAttributes);
					if (resultingObjects.count)
					{
						[resultingObjects enumerateObjectsUsingBlock: ^(id resultingObject, NSUInteger idx, BOOL *stop) {
							if ([resultingObject isKindOfClass: [NSManagedObject class]])
							{
								[duplicateGroup removeObject: resultingObject];
							}
							else if ([resultingObjects isKindOfClass: [NSDictionary class]])
							{
								NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity: entityDescription insertIntoManagedObjectContext: context];
								[managedObject updateValuesFromDictionary: resultingObject];
							}
							else
							{
								NSAssert1(NO, @"Resulting object of unexpected class %@ was returned", [resultingObject class]);
							}
						}];

						[duplicateGroup makeObjectsPerformSelector: @selector(deleteInContext:) withObject: context];
					}
				}];
			}];
		} completion: ^{
			// LASTLY, signal the load semaphore
			[self unlock];
		}];
	});
}

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error
{
	if (!error)
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		void (^block)(NSError *error) = [self errorHandler];
		if (block)
		{
			block(error);
			return;
		}
		
		id target = [self errorDelegate];
		if (target)
		{
			[target performSelector: @selector(handleError:) withObject: error];
			return;
		}
		
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
		[[NSApplication sharedApplication] presentError: error];
#endif
	});
}

+ (AZCoreRecordErrorBlock) errorHandler
{
	return errorHandler;
}
+ (void) setErrorHandler: (AZCoreRecordErrorBlock) block
{
	errorHandler = [block copy];
}

+ (id <AZCoreRecordErrorHandler>) errorDelegate
{
	return errorDelegate;
}
+ (void) setErrorDelegate: (id <AZCoreRecordErrorHandler>) target
{
	errorDelegate = target;
}

#pragma mark - Data Commit

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block
{
	[self.managedObjectContext saveDataWithBlock: block];
}
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block
{
	[self.managedObjectContext saveDataInBackgroundWithBlock: block completion: NULL];
}
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (void (^)(void)) callback
{
	[self.managedObjectContext saveDataInBackgroundWithBlock: block completion: callback];
}

@end
