// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Food.m instead.

#import "_Food.h"

const struct FoodAttributes FoodAttributes = {
	.name = @"name",
};

const struct FoodRelationships FoodRelationships = {
	.meal = @"meal",
};

const struct FoodFetchedProperties FoodFetchedProperties = {
};

@implementation FoodID
@end

@implementation _Food

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Food" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Food";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Food" inManagedObjectContext:moc_];
}

- (FoodID*)objectID {
	return (FoodID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic name;






@dynamic meal;

	






@end
