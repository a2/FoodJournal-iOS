// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Image.m instead.

#import "_Image.h"

const struct ImageAttributes ImageAttributes = {
	.imageData = @"imageData",
	.largeThumbnailImageData = @"largeThumbnailImageData",
	.smallThumbnailImageData = @"smallThumbnailImageData",
};

const struct ImageRelationships ImageRelationships = {
	.meal = @"meal",
	.wordPressImages = @"wordPressImages",
};

const struct ImageFetchedProperties ImageFetchedProperties = {
};

@implementation ImageID
@end

@implementation _Image

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Image";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Image" inManagedObjectContext:moc_];
}

- (ImageID*)objectID {
	return (ImageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic imageData;






@dynamic largeThumbnailImageData;






@dynamic smallThumbnailImageData;






@dynamic meal;

	

@dynamic wordPressImages;

	
- (NSMutableSet*)wordPressImagesSet {
	[self willAccessValueForKey:@"wordPressImages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"wordPressImages"];
  
	[self didAccessValueForKey:@"wordPressImages"];
	return result;
}
	






@end
