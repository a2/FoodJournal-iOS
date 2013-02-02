// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Post.m instead.

#import "_Post.h"

const struct PostAttributes PostAttributes = {
	.contents = @"contents",
	.date = @"date",
};

const struct PostRelationships PostRelationships = {
	.meals = @"meals",
	.wordPressPosts = @"wordPressPosts",
};

const struct PostFetchedProperties PostFetchedProperties = {
};

@implementation PostID
@end

@implementation _Post

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Post";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Post" inManagedObjectContext:moc_];
}

- (PostID*)objectID {
	return (PostID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic contents;






@dynamic date;






@dynamic meals;

	
- (NSMutableOrderedSet*)mealsSet {
	[self willAccessValueForKey:@"meals"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"meals"];
  
	[self didAccessValueForKey:@"meals"];
	return result;
}
	

@dynamic wordPressPosts;

	
- (NSMutableSet*)wordPressPostsSet {
	[self willAccessValueForKey:@"wordPressPosts"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"wordPressPosts"];
  
	[self didAccessValueForKey:@"wordPressPosts"];
	return result;
}
	






@end
