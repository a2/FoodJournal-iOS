//
//  NSManagedObject+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObject+AZCoreRecord.h"
#import "AZCoreRecordManager.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"

static NSUInteger defaultBatchSize = 20;

@interface NSManagedObject (AZCoreRecord_MOGenerator)

+ (NSEntityDescription *) entityInManagedObjectContext: (NSManagedObjectContext *) context;
+ (id) insertInManagedObjectContext: (NSManagedObjectContext *) context;

@end

@implementation NSManagedObject (AZCoreRecord)

#pragma mark - Instance Methods

- (instancetype) inContext: (NSManagedObjectContext *) context
{
	NSParameterAssert(context);
	
	NSManagedObjectContext *myContext = self.managedObjectContext ?: [NSManagedObjectContext defaultContext];
	
	if ([self.objectID isTemporaryID])
	{
		NSError *error = nil;
		[myContext obtainPermanentIDsForObjects: [NSArray arrayWithObject: self] error: &error];
		[AZCoreRecordManager handleError: error];
	}
	
	if ([context isEqual:self.managedObjectContext])
		return self;

	NSError *error = nil;
	NSManagedObject *inContext = [context existingObjectWithID: self.objectID error: &error];
	[AZCoreRecordManager handleError: error];
	
	return inContext;
}
- (instancetype) inThreadContext 
{
	return [self inContext: [NSManagedObjectContext contextForCurrentThread]];
}

- (void) reload
{
	[self.managedObjectContext refreshObject:self mergeChanges:NO];
}

- (NSURL *) URI
{
	NSManagedObjectID *objectID = self.objectID;
	
	if (objectID.isTemporaryID)
	{
		NSError *error;
		if ([self.managedObjectContext obtainPermanentIDsForObjects: [NSArray arrayWithObject: self] error: &error])
			objectID = self.objectID;
		
		[AZCoreRecordManager handleError: error];
	}
	
	return objectID.URIRepresentation;
}

#pragma mark - Default batch size

+ (NSUInteger) defaultBatchSize
{
	return defaultBatchSize;
}
+ (void) setDefaultBatchSize: (NSUInteger) newBatchSize
{
	defaultBatchSize = newBatchSize;
}

#pragma mark - Entity Description

+ (NSArray *) propertiesNamed: (NSArray *) properties
{
	if (!properties.count)
		return nil;
	
	NSDictionary *propertyDescriptions = self.entityDescription.propertiesByName;
	return [propertyDescriptions objectsForKeys: properties notFoundMarker: [NSNull null]];
}

+ (NSEntityDescription *) entityDescription
{
	return [self entityDescriptionInContext: nil];
}
+ (NSEntityDescription *) entityDescriptionInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	if ([self respondsToSelector: @selector(entityInManagedObjectContext:)]) 
		return [self performSelector: @selector(entityInManagedObjectContext:) withObject: context];
	
	NSString *className = NSStringFromClass(self);
	NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
	NSEntityDescription *entity = [model.entitiesByName objectForKey: className];
	if (!entity) {
		NSArray *entities = model.entities;
		NSUInteger index = [entities indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
			return [[obj managedObjectClassName] isEqualToString: className];
		}];
		
		if (index == NSNotFound)
			return nil;
		
		entity = [entities objectAtIndex: index];
	}
	return entity;
}

#pragma mark - Entity Creation

+ (instancetype) create
{	
	return [self createInContext: nil];
}
+ (instancetype) createInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	NSEntityDescription *entity = [self entityDescriptionInContext: context];
	return [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
}

#pragma mark - Entity deletion

- (void) delete
{
	[self.managedObjectContext deleteObject: self];
}
- (void) deleteInContext: (NSManagedObjectContext *) context
{
	[context deleteObject: [self inContext: context]];
}

+ (void) deleteAll
{
	[self deleteAllInContext: nil];
}
+ (void) deleteAllInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSArray *objects = [self findAllInContext: context];
	[objects makeObjectsPerformSelector:@selector(deleteInContext:) withObject:context];
}

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate
{
	[self deleteAllMatchingPredicate: predicate inContext: nil];
}
+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSFetchRequest *request = [self requestAllWithPredicate: predicate inContext: context];
	request.includesPropertyValues = NO;
	
	NSArray *objects = [context executeFetchRequest: request error: NULL];
	[objects makeObjectsPerformSelector:@selector(deleteInContext:) withObject:context];
}

#pragma mark - Entity Count

+ (NSUInteger) count
{
	return [self countWithPredicate: nil inContext: nil];
}
+ (NSUInteger) countInContext:(NSManagedObjectContext *)context
{
	return [self countWithPredicate: nil inContext: context];
}

+ (NSUInteger) countWithPredicate: (NSPredicate *) searchFilter
{
	return [self countWithPredicate: searchFilter inContext: nil];
}
+ (NSUInteger) countWithPredicate: (NSPredicate *) searchFilter inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	NSError *error = nil;
	NSFetchRequest *request = [self requestAllWithPredicate: searchFilter inContext: context];
	NSUInteger count = [context countForFetchRequest: request error: &error];
	[AZCoreRecordManager handleError: error];
	return count;
}

#pragma mark - Deduplication

+ (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler includeSubentities: (BOOL) includeSubentities
{
	AZCoreRecordManager *manager = [AZCoreRecordManager defaultManager];
	[manager registerDeduplicationHandler: handler forEntityName: [self entityDescriptionInContext: manager.managedObjectContext].name includeSubentities: includeSubentities];
}

#pragma mark - Singleton-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestFirst
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: nil];
}
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue
{
	return [self requestFirstWhere: property equals: searchValue sortedBy: nil ascending: NO];
}
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	return [self requestFirstWhere: property equals: searchValue sortedBy: nil ascending: NO inContext: context];
}

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestFirstWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending predicate: nil];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending predicate: nil inContext: context];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: nil];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: context];
	request.fetchLimit = 1;
	return request;
}

#pragma mark - Array-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestAll
{
	return [self requestAllSortedBy: nil ascending: NO predicate: nil];
}
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) predicate
{
	return [self requestAllSortedBy: nil ascending: NO predicate: predicate];
}
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: nil ascending: NO predicate: predicate inContext: context];
}

+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value
{
	return [self requestAllWhere: property equals: value sortedBy: nil ascending: NO];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context
{
	return [self requestAllWhere: property equals: value sortedBy: nil ascending: NO inContext: context];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestAllWhere: property equals: value sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, value];
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: predicate inContext: context];
}

+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: nil];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: nil inContext: context];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: nil];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	NSFetchRequest *request = [NSFetchRequest new];
	request.entity = [self entityDescriptionInContext: context];
	request.predicate = searchTerm;
	request.fetchBatchSize = self.defaultBatchSize;

	if (sortTerm.length)
	{
		NSSortDescriptor *sortBy = [NSSortDescriptor sortDescriptorWithKey: sortTerm ascending: ascending];
		request.sortDescriptors = [NSArray arrayWithObject: sortBy];
	}
	
	return request;
}

#pragma mark - Singleton-fetching Fetch Request Convenience Methods

+ (instancetype) findFirst
{
	return [self findFirstSortedBy: nil ascending: NO predicate: nil];
}
+ (instancetype) findFirstInContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm attributes: attributes];
}
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm attributes: attributes inContext: context];
}

+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue
{
	return [self findFirstWhere: property equals: searchValue sortedBy: nil ascending: NO];
}
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	return [self findFirstWhere: property equals: searchValue sortedBy: nil ascending: NO inContext: context];
}
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, searchValue];
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: predicate inContext: context];
}

+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: nil attributes: nil];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: nil attributes: nil inContext: context];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm attributes: nil];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm attributes: nil inContext: context];
}

+ (instancetype) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes
{
	return [self findFirstSortedBy: sortBy ascending: ascending predicate: searchTerm attributes: attributes inContext: nil];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestFirstSortedBy: sortBy ascending: ascending predicate: searchTerm inContext: context];
	request.propertiesToFetch = attributes;
	NSArray *results = [context executeFetchRequest: request error: NULL];
	return results.count ? results.lastObject : nil;
}

#pragma mark - Array-fetching Fetch Request Convenience Methods

+ (NSArray *) findAll
{
	return [self findAllSortedBy: nil ascending: NO predicate: nil];
}
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context
{
	return [self findAllSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm
{
	return [self findAllSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findAllSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value
{
	return [self findAllWhere: property equals: value sortedBy: nil ascending: NO];
}
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context
{
	return [self findAllWhere: property equals: value sortedBy: nil ascending: NO inContext: context];
}
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findAllWhere: property equals: value sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, value];
	return [self findAllSortedBy: nil ascending: NO predicate: predicate inContext: context];
}

+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findAllSortedBy: sortTerm ascending: ascending predicate: nil];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self findAllSortedBy: sortTerm ascending: ascending predicate: nil inContext: context];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self findAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: nil];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];

	NSFetchRequest *request = [self requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: context];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest: request error: &error];
	[AZCoreRecordManager handleError: error];
	return results;
}

@end
