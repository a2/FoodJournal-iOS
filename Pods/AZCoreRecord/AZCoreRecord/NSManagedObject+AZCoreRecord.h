//
//  NSManagedObject+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AZCoreRecordManager.h"

/**
 The AZCoreRecord extensions for NSManagedObject are primarily
 oriented turning complex methods into readable one-liners.
 
 Instantiate new model objects, transfer them between contexts,
 find information about the entity, or use our famous one-line fetches.
 
 @warning *Important*: All methods that do not have a parameter for
 context will use the default context of the shared AZCoreRecordManager
 instance. For brevity's sake, this will not be pointed out on the
 methods below.
 
 If you are using child contexts of the default context or
 are using multiple Core Data stacks - *including the default context
 of another stack* - you must use a method with an `inContext:` parameter.
 */
@interface NSManagedObject (AZCoreRecord)

#pragma mark -
/** @name Object Utilities */

/** Returns a managed object context of the same entity representing the same
 object in the store in the given managed object context. */
- (instancetype) inContext: (NSManagedObjectContext *) otherContext;

/** Returns a managed object context of the same entity representing the same
 object in the store in the local thread context.
 
 @see inContext:
 @see [AZCoreRecordManager -contextForCurrentThread]
 */
- (instancetype) inThreadContext;

/** Turns the reciever into a fault so that its contents are refreshed from its
 managed object context on next access. */
- (void) reload;

/** A permanent URI for the represented object in the model. Useful for 
 getting the reciever later. If the reciever is deleted or is never saved into
 a persistent store, this value becomes invalid. */
@property (nonatomic, readonly) NSURL *URI;

#pragma mark -
/** @name Default Batch Size */

/** The app-wide default batch size for any of the one-line fetches. */
+ (NSUInteger) defaultBatchSize;

/** Sets the app-wide default batch size for any of the one-line fetches.
 
 The default value is 20. Change this value to tweak the performance
 specifications of your app.
 
 When this value is greater than 0, a fetch will not cause every matching object
 to be loaded into memory at once, but instead causes the fetch to return a
 special array that will fault other objects as needed. See
 [NSFetchRequest -batchSize] for a full discussion.
 
 @param newBatchSize A batch size
 */
+ (void) setDefaultBatchSize: (NSUInteger) newBatchSize;

#pragma mark -
/** @name Entity Description */

/** Returns property descriptions for an array of property key paths.
 
 @param properties An array of string key paths.
 @returns An array of property descriptions.
 @see findFirstWithPredicate:attributes:
 @see findFirstWithPredicate:attributes:inContext:
 @see findFirstSortedBy:ascending:predicate:attributes:
 @see findFirstSortedBy:ascending:predicate:attributes:inContext:
 */
+ (NSArray *) propertiesNamed: (NSArray *) properties;

/** Obtains the entity description for the recieving class in a specified
 managed object context. An entity description can be obtained no matter what
 the class name is in relation to the entity. */
+ (NSEntityDescription *) entityDescription;

/** Obtains the entity description for the recieving class in a specified
 managed object context.
 
 An entity description can be obtained no matter what the class name is in
 relation to the entity.
 
 @param context A managed object context. If nil, this method behaves like
 -entityDescription.
 @returns An entity description
 */
+ (NSEntityDescription *) entityDescriptionInContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Object Creation */

/** Creates a new object using the recieving entity and inserts it into the
 current thread-safe managed object context.

 @param context A managed object context. If nil, this method behaves
 like -create.
 @returns A managed object of the specified entity.
 @see create
 @see [AZCoreRecordManager -contextForCurrentThread]
 */
+ (instancetype) create;

/** Creates a new object using the recieving entity and inserts it into the
 specified managed object context.
 
 @param context A managed object. If nil, this method behaves like -create.
 @returns A managed object of the specified entity.
 @see create
 */
+ (instancetype) createInContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Object Deletion */

/** Specifies that the reciever should be removed from the persistent store
 when changes are committed to its current managed object context.
 
 Any references to the reciever become invalid after saving the context. It
 is not recommended to use this object after calling delete:.
 
 If the reciever has not yet been saved to a persistent store, it is simply
 removed from its managed object context and will never be saved to a store.
 
 @see deleteInContext:
 */
- (void) delete;

/** Finds a reference for the reciever in a different managed object context,
 and specifies that it should be removed in that context.
 
 This does not necessarily mean that the object is invalid. If the specified
 context is never saved, then the reciever object is not deleted.

 If the reciever has not yet been saved to a persistent store, it cannot be
 resurrected in a different managed object context and this operation does
 nothing.

 @see delete
 */
- (void) deleteInContext: (NSManagedObjectContext *) context;

/** Fetches and deletes all objects belonging to the receiving entity.

 @see deleteInContext:
 @see deleteAllMatchingPredicate:inContext:
 */
+ (void) deleteAll;

/** Fetches and deletes all objects belonging to the receiving entity in a 
 anaged object context.

 @param context The managed object context in which to search for objects.
 @see deleteInContext:
 @see deleteAllMatchingPredicate:inContext:
 */
+ (void) deleteAllInContext: (NSManagedObjectContext *) context;

/** Fetches and deletes any objects matching a given predicate for the receiving
 entity.

 @param searchTerm A predicate representing when to delete an object.
 @see deleteAllMatchingPredicate:inContext:
 */
+ (void) deleteAllMatchingPredicate: (NSPredicate *) searchTerm;

/** Fetches and deletes any objects matching a given predicate for the receiving
 entity in a managed object context.

 @warning *Information*: Do note that this method is significantly faster than
 fetching them using a one-line fetch and then deleting, and is therefore
 recommended for every pure deletion operation.

 @param searchTerm A predicate representing when to delete an object.
 @param context The managed object context in which to search for objects.
 @see deleteAll
 @see deleteAllInContext:
 @see deleteAllMatchingPredicate:
 */
+ (void) deleteAllMatchingPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Counting Objects */

/** Fetches the number of objects for the receiving entity.

 @returns A number of objects.
 @see countWithPredicate:inContext:
 */
+ (NSUInteger) count;

/** Fetches the number of objects for the receiving entity in a managed object
 context.

 @returns The number of objects matching the predicate.
 @see countWithPredicate:inContext:
 */
+ (NSUInteger) countInContext: (NSManagedObjectContext *) context;

/** Fetches the number of objects matching a given predicate for
 the receiving entity.

 @param searchTerm A predicate representing when to count an object.
 @returns The number of objects matching the predicate.
 @see countWithPredicate:inContext:
 */
+ (NSUInteger) countWithPredicate: (NSPredicate *) searchTerm;

/** Fetches the number of objects matching a given predicate for
 the receiving entity in a managed object context.
 
 @warning *Information*: Do note that this method is significantly faster than
 any of the one-line fetches below, and is therefore recommended for every pure
 check of existence that doesn't need actual objects returned.
 
 @param searchTerm A predicate representing when to count an object.
 @param context The managed object context in which to search for objects.
 @returns The number of objects matching the predicate.
 @see count
 @see countInContext:
 @see countWithPredicate:
 */
+ (NSUInteger) countWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Deduplication */

/** Registers a deduplication handler for the entity represented by the
 recieving class.
 
 Deduplication handlers are registered on the shared instance of
 AZCoreRecordManager. If you maintain multiple Core Data stacks in your app,
 use the instance method on your stack instead.
 @see [AZCoreRecordManager registerDeduplicationHandler:forEntityName:includeSubentities:]
 */
+ (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler includeSubentities: (BOOL) includeSubentities;

#pragma mark -
/** @name Creating Fetch Requests For Single Objects */

/** Requests the first model object for the receiving entity.

 This class method is a member of the `requestFirst` group of methods.

 @return A fetch request for the first object.
 @see requestFirstWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestFirst;

/** Requests the first model object in a managed object context for the
 receiving entity.

 This class method is a member of the `requestFirst` group of methods.

 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object.
 @see requestFirstWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context;

/** Requests the first model object matching a predicate for the receiving
 entity.

 This class method is a member of the `requestFirst` group of methods.

 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm;

/** Requests the first model object matching a predicate in a managed object
 context for the receiving entity.

 This class method is the base of the `requestFirst` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirst
 @see requestFirstInContext:
 @see requestFirstWithPredicate:
 */
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests the first model object where an attribute is equal to a given value
 for the receiving entity.

 This class method is a member of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value;

/** Requests the first model object in a managed object context where an
 attribute is equal to a given value for the receiving entity.

 This class method is a member of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests the first model object, when sorted ascending or descending by a
 key path, where an attribute is equal to a given value for the receiving entity.

 This class method is a member of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests the first model object, when sorted ascending or descending by a
 key path, in a managed object context where an attribute is equal to a given
 value for the receiving entity.

 This class method is the base of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstWhere:equals:
 @see requestFirstWhere:equals:inContext:
 @see requestFirstWhere:equals:sortedBy:ascending:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests the first model object, when sorted ascending or descending by a
 key path, for the receiving entity.

 This class method is a member of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests the first model object, when sorted ascending or descending by a
 key path, in a managed object context for the receiving entity.

 This class method is a member of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests the first model object, when sorted ascending or descending by a
 key path, matching a given predicate for the receiving entity.

 This class method is the base of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests the first model object, when sorted ascending or descending by a
 key path, in a managed object context matching a given predicate for the \
 receiving entity.

 This class method is the base of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object satisfying the parameters.
 @see requestFirstSortedBy:ascending:
 @see requestFirstSortedBy:ascending:inContext:
 @see requestFirstSortedBy:ascending:predicate:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Creating Fetch Requests */

/** Requests instances of all model objects.

 This class method is a member of the `requestAll` group of methods.

 @return A fetch request.
 @see requestAll
 @see requestAllInContext:
 @see requestAllWithPredicate:
 */
+ (NSFetchRequest *) requestAll;

/** Requests instances of all model objects in a managed object context.

 This class method is a member of the `requestAll` group of methods.

 @param context The managed object context in which to search for objects.
 @return A fetch request.
 @see requestAll
 @see requestAllInContext:
 @see requestAllWithPredicate:
 */
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects in a managed object context matching
 a given predicate for the receiving entity.

 This class method is a member of the `requestAll` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm;

/** Requests instances of all model objects in a managed object context matching
 a given predicate for the receiving entity.

 This class method is the base of the `requestAll` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request for objects satisfying the parameters.
 @see requestAll
 @see requestAllInContext:
 @see requestAllWithPredicate:
 */
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects where an attribute is equal to a
 given value for the receiving entity.

 This class method is a member of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value;

/** Requests instances of all model objects in a managed object context where an
 attribute is equal to a given value for the receiving entity.

 This class method is a member of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param context The managed object context in which to search for objects.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects where an attribute is equal to a
 given value for the receiving entity, sorted ascending or descending by a key
 path.

 This class method is a member of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests instances of all model objects in a managed object context where an
 attribute is equal to a given value for the receiving entity, sorted ascending
 or descending by a key path.

 This class method is the base of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllWhere:equals:
 @see requestAllWhere:equals:inContext:
 @see requestAllWhere:equals:sortedBy:ascending:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects for the receiving entity, sorted
 ascending or descending by a key path.

 This class method is a member of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests instances of all model objects in a managed object context for the
 receiving entity, sorted ascending or descending by a key path.

 This class method is a member of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects matching a given predicate for the
 receiving entity, sorted ascending or descending by a key path.

 This class method is a member of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests instances of all model objects in a managed object context matching
 a given predicate for the receiving entity, sorted ascending or descending by a
 key path.

 This class method is the base of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request for objects satisfying the parameters.
 @see requestAllSortedBy:ascending:
 @see requestAllSortedBy:ascending:inContext:
 @see requestAllSortedBy:ascending:predicate:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Fetching Single Objects */

/** Requests and returns the first model object for the receiving entity.

 This class method is a member of the `findFirst` group of methods.

 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirst;

/** Requests and returns the first model object in a managed object context for
 the receiving entity.

 This class method is a member of the `findFirst` group of methods.

 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstInContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object matching a predicate for the
 receiving entity.

 This class method is a member of the `findFirst` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm;

/** Requests and returns the first model object matching a predicate in a
 managed object context for the receiving entity.

 This class method is a member of the `findFirst` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object matching a predicate for the
 receiving entity with specific attributes.

 This class method is a member of the `findFirst` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @param attributes An array of property descriptions.
 @return The first result for the fetch, or `nil` if no results.
 @see propertiesNamed:
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes;

/** Requests and returns the first model object matching a predicate in a
 managed object context for the receiving entity with specific attributes.

 This class method is the base of the `findFirst` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @param attributes An array of property descriptions.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirst
 @see findFirstInContext:
 @see findFirstWithPredicate:
 @see findFirstWithPredicate:inContext:
 @see findFirstWithPredicate:attributes:
 @see propertiesNamed:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object where an attribute is equal to a
 given value for the receiving entity.

 This class method is a member of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue;

/** Requests and returns the first model object in a managed object context
 where an attribute is equal to a given value for the receiving entity.

 This class method is a member of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, where an attribute is equal to a given value for the
 receiving entity.

 This class method is a member of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, in a managed object context where an attribute is
 equal to a given value for the receiving entity.

 This class method is the base of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 
 @see findFirstWhere:equals:
 @see findFirstWhere:equals:inContext:
 @see findFirstWhere:equals:sortedBy:ascending:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, for the receiving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, in a managed object context for the receiving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, matching a given predicate for the receiving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, in a managed object context matching a given
 predicate for the receiving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, matching a given predicate for the receiving entity
 with specific attributes.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @param attributes An array of property descriptions.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:attributes:inContext:
 @see propertiesNamed:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes;

/** Requests and returns the first model object, when sorted ascending or
 descending by a key path, in a managed object context matching a given
 predicate for the receiving entity with specific attributes.
 
 This class method is the base of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @param attributes An array of property descriptions. 
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:
 @see findFirstSortedBy:ascending:inContext:
 @see findFirstSortedBy:ascending:predicate:
 @see findFirstSortedBy:ascending:predicate:inContext:
 @see findFirstSortedBy:ascending:predicate:attributes:
 @see propertiesNamed:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Fetching Object Arrays */

/** Requests and returns instances of all model objects.

 This class method is a member of the `findAll` group of methods.

 @return An array of results.
 @see findAllWithPredicate:inContext:
 */
+ (NSArray *) findAll;

/** Requests and returns instances of all model objects in a managed object
 context.

 This class method is a member of the `findAll` group of methods.

 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAllWithPredicate:inContext:
 */
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects matching a given
 predicate for the receiving entity.

 This class method is a member of the `findAll` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @return An array of results.
 @see findAllWithPredicate:inContext:
 */
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm;

/** Requests and returns instances of all model objects in a managed object
 context matching a given predicate for the receiving entity.

 This class method is the base of the `findAll` group of methods.

 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAll
 @see findAllInContext:
 @see findAllWithPredicate:
 */
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects where an attribute is
 equal to a given value for the receiving entity.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @return An array of results.
 @see findAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value;

/** Requests and returns instances of all model objects in a managed object
 context where an attribute is equal to a given value for the receiving entity.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects where an attribute is
 equal to a given value for the receiving entity, sorted ascending or descending
 by a key path.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return An array of results.
 @see findAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns instances of all model objects in a managed object
 context where an attribute is equal to a given value for the receiving entity,
 sorted ascending or descending by a key path.

 This class method is the base of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value An object that can be parsed as part of a predicate.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAllWhere:equals:
 @see findAllWhere:equals:inContext:
 @see findAllWhere:equals:sortedBy:ascending:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects for the receiving
 entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @return An array of results.
 @see findAllSortedBy:ascending:predicate:inContext:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns instances of all model objects in a managed object
 context for the receiving entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAllSortedBy:ascending:predicate:inContext:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects matching a given
 predicate for the receiving entity, sorted ascending or descending by a key
 path.

 This class method is a member of the `findAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @return An array of results.
 @see findAllSortedBy:ascending:predicate:inContext:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests and returns instances of all model objects in a managed object
 context matching a given predicate for the receiving entity, sorted ascending
 or descending by a key path.
 
 This class method is the base of the `findAllSortedBy` group of methods.
 
 @param sortTerm A key path for an attribute on the entity to sort by. 
 @param ascending If YES, sorting will be low-to-high, otherwise high-to-low.
 @param searchTerm A predicate representing when to include an object.
 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAllSortedBy:ascending:
 @see findAllSortedBy:ascending:inContext:
 @see findAllSortedBy:ascending:predicate:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

@end
