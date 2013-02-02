//
//  NSManagedObjectModel+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (AZCoreRecord)

#pragma mark - Model Factory Methods

+ (NSManagedObjectModel *) modelWithName: (NSString *) name;
+ (NSManagedObjectModel *) modelWithName: (NSString *) name inBundle: (NSBundle *) bundle;

@end
