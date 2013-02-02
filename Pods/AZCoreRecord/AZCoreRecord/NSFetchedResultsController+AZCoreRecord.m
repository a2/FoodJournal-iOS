//
//  NSFetchedResultsController+AZCoreRecord
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 2/27/12.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordManager.h"
#import "NSFetchedResultsController+AZCoreRecord.h"
#import "NSManagedObject+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

@implementation NSFetchedResultsController (AZCoreRecord)

- (BOOL) performFetch
{
	NSError *error = nil;
	BOOL saved = [self performFetch: &error];
	[AZCoreRecordManager handleError: error];
	return saved;
}

+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request
{
	return [self fetchedResultsControllerForRequest: request inContext: nil];
}
+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context
{
	return [self fetchedResultsControllerForRequest: request groupedBy: nil inContext: context];
}

+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group
{
	return [self fetchedResultsControllerForRequest: request groupedBy: group inContext: nil];
}
+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	NSString *cacheName = nil;
#if !TARGET_IPHONE_SIMULATOR
	cacheName = [NSString stringWithFormat: @"AZCoreRecordCache-%@", [request entityName]];
#endif
	
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest: request managedObjectContext: context sectionNameKeyPath: group cacheName: cacheName];
	[controller performFetch];
	return controller;
}

+ (NSFetchedResultsController *) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath
{
	return [self fetchedResultsControllerForEntity: entityClass sortedBy: sortTerm ascending: ascending predicate: searchTerm groupedBy: keyPath inContext: nil];
}
+ (NSFetchedResultsController *) fetchedResultsControllerForEntity: (Class)entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath inContext: (NSManagedObjectContext *) context
{
	NSParameterAssert([entityClass isSubclassOfClass:[NSManagedObject class]]);
	NSFetchRequest *request = [entityClass requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: context];
	return [self fetchedResultsControllerForRequest: request groupedBy: keyPath inContext: context];
}

@end

#endif
