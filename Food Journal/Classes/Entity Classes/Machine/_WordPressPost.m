// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WordPressPost.m instead.

#import "_WordPressPost.h"

const struct WordPressPostAttributes WordPressPostAttributes = {
	.postId = @"postId",
	.url = @"url",
};

const struct WordPressPostRelationships WordPressPostRelationships = {
	.account = @"account",
	.post = @"post",
};

const struct WordPressPostFetchedProperties WordPressPostFetchedProperties = {
};

@implementation WordPressPostID
@end

@implementation _WordPressPost

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"WordPressPost" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"WordPressPost";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"WordPressPost" inManagedObjectContext:moc_];
}

- (WordPressPostID*)objectID {
	return (WordPressPostID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"postIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"postId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic postId;



- (int64_t)postIdValue {
	NSNumber *result = [self postId];
	return [result longLongValue];
}

- (void)setPostIdValue:(int64_t)value_ {
	[self setPostId:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitivePostIdValue {
	NSNumber *result = [self primitivePostId];
	return [result longLongValue];
}

- (void)setPrimitivePostIdValue:(int64_t)value_ {
	[self setPrimitivePostId:[NSNumber numberWithLongLong:value_]];
}





@dynamic url;






@dynamic account;

	

@dynamic post;

	






@end
