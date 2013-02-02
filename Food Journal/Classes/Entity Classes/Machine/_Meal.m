// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Meal.m instead.

#import "_Meal.h"

const struct MealAttributes MealAttributes = {
	.name = @"name",
};

const struct MealRelationships MealRelationships = {
	.foods = @"foods",
	.images = @"images",
	.post = @"post",
};

const struct MealFetchedProperties MealFetchedProperties = {
};

@implementation MealID
@end

@implementation _Meal

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Meal" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Meal";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Meal" inManagedObjectContext:moc_];
}

- (MealID*)objectID {
	return (MealID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic foods;

	
- (NSMutableOrderedSet*)foodsSet {
	[self willAccessValueForKey:@"foods"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"foods"];
  
	[self didAccessValueForKey:@"foods"];
	return result;
}
	

@dynamic images;

	
- (NSMutableOrderedSet*)imagesSet {
	[self willAccessValueForKey:@"images"];
  
	NSMutableOrderedSet *result = (NSMutableOrderedSet*)[self mutableOrderedSetValueForKey:@"images"];
  
	[self didAccessValueForKey:@"images"];
	return result;
}
	

@dynamic post;

	






@end
