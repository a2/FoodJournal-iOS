// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WordPressImage.m instead.

#import "_WordPressImage.h"

const struct WordPressImageAttributes WordPressImageAttributes = {
	.attachmentId = @"attachmentId",
	.url = @"url",
};

const struct WordPressImageRelationships WordPressImageRelationships = {
	.account = @"account",
	.image = @"image",
};

const struct WordPressImageFetchedProperties WordPressImageFetchedProperties = {
};

@implementation WordPressImageID
@end

@implementation _WordPressImage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"WordPressImage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"WordPressImage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"WordPressImage" inManagedObjectContext:moc_];
}

- (WordPressImageID*)objectID {
	return (WordPressImageID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"attachmentIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"attachmentId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic attachmentId;



- (int64_t)attachmentIdValue {
	NSNumber *result = [self attachmentId];
	return [result longLongValue];
}

- (void)setAttachmentIdValue:(int64_t)value_ {
	[self setAttachmentId:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveAttachmentIdValue {
	NSNumber *result = [self primitiveAttachmentId];
	return [result longLongValue];
}

- (void)setPrimitiveAttachmentIdValue:(int64_t)value_ {
	[self setPrimitiveAttachmentId:[NSNumber numberWithLongLong:value_]];
}





@dynamic url;






@dynamic account;

	

@dynamic image;

	






@end
