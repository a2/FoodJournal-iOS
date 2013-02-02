//
//  NSManagedObjectModel+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectModel+AZCoreRecord.h"
#import "AZCoreRecordManager.h"

@implementation NSManagedObjectModel (AZCoreRecord)

#pragma mark - Model Factory Methods

+ (NSManagedObjectModel *) modelWithName: (NSString *) modelName
{
	return [self modelWithName: modelName inBundle: [NSBundle mainBundle]];
}
+ (NSManagedObjectModel *) modelWithName: (NSString *) modelName inBundle: (NSBundle *) bundle
{
	NSString *resource = [modelName stringByDeletingPathExtension];
	NSString *pathExtension = [modelName pathExtension];
	
	NSURL *URL = [bundle URLForResource: resource withExtension: pathExtension];
	if (!URL) URL = [bundle URLForResource: resource withExtension: @"momd"];
	if (!URL) URL = [bundle URLForResource: resource withExtension: @"mom"];
	NSAssert2(URL, @"Could not find model named %@ in bundle %@", modelName, bundle);
	
	return [[NSManagedObjectModel alloc] initWithContentsOfURL: URL];
}

@end
