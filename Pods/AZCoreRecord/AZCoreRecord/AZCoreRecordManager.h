//
//  AZCoreRecordManager.h
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef NSArray *(^AZCoreRecordDeduplicationHandlerBlock)(NSArray *conflictingManagedObjects, NSArray *identityAttributes);
typedef void (^AZCoreRecordContextBlock)(NSManagedObjectContext *context);
typedef void (^AZCoreRecordErrorBlock)(NSError *error);
typedef void (^AZCoreRecordVoidBlock)(void);

extern NSString *const AZCoreRecordManagerWillBeginAddingPersistentStoresNotification;
extern NSString *const AZCoreRecordManagerDidAddPrimaryStoreNotification;
extern NSString *const AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification;

extern NSString *const AZCoreRecordManagerShouldRunDeduplicationNotification;

extern NSString *const AZCoreRecordDeduplicationIdentityAttributeKey;

@protocol AZCoreRecordErrorHandler <NSObject>
@required

- (void) handleError: (NSError *) error;

@end

@interface AZCoreRecordManager : NSObject <NSLocking>

- (id)initWithStackName: (NSString *) name;

@property (nonatomic, readonly) NSString *stackName;

#pragma mark - Stack Accessors

- (NSManagedObjectContext *)contextForCurrentThread;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong, readonly) NSFileManager *fileManager;

#pragma mark - Helpers

@property (weak, nonatomic, readonly) NSURL *storeURL;

#pragma mark - Options

@property (nonatomic) BOOL stackShouldAutoMigrateStore;
@property (nonatomic) BOOL stackShouldUseInMemoryStore;
@property (nonatomic, copy) NSString *stackModelName;
@property (nonatomic, copy) NSURL *stackModelURL;
@property (nonatomic, copy) NSDictionary *stackModelConfigurations;
@property (unsafe_unretained, nonatomic) Class stackManagedObjectContextClass;

- (void) configureWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

- (void) loadPersistentStoresWithCompletion:(void(^)(void))completionBlock;

#pragma mark - Default stack settings

+ (AZCoreRecordManager *) defaultManager;
+ (void) setDefaultManager: (AZCoreRecordManager *)manager;
+ (void) setDefaultManagerClass:(Class)cls;

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
+ (void) setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory;
+ (void) setDefaultStackShouldUseUbiquity: (BOOL) usesUbiquity;
+ (void) setDefaultStackModelName: (NSString *) name;
+ (void) setDefaultStackModelURL: (NSURL *) name;
+ (void) setDefaultStackModelConfigurations: (NSDictionary *) dictionary;

+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Deduplication

- (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler forEntityName: (NSString *) entityName includeSubentities: (BOOL) includeSubentities;

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error;

+ (AZCoreRecordErrorBlock) errorHandler;
+ (void) setErrorHandler: (AZCoreRecordErrorBlock) block;

+ (id <AZCoreRecordErrorHandler>) errorDelegate;
+ (void) setErrorDelegate: (id <AZCoreRecordErrorHandler>) target;

#pragma mark - Data Commit

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block;

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block;
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (AZCoreRecordVoidBlock) callback;

@end
