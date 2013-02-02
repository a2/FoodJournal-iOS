//
//  NSFetchedResultsController+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 2/27/12.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

#import <CoreData/CoreData.h>

@interface NSFetchedResultsController (AZCoreRecord)

- (BOOL) performFetch;

+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request;
+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context;

+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group;
+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group inContext: (NSManagedObjectContext *) context;

+ (NSFetchedResultsController *) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath;
+ (NSFetchedResultsController *) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath inContext: (NSManagedObjectContext *) context;

@end

#endif
