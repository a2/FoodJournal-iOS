// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WordPressAccount.m instead.

#import "_WordPressAccount.h"

const struct WordPressAccountAttributes WordPressAccountAttributes = {
	.blogId = @"blogId",
	.hasToken = @"hasToken",
	.xmlrpcUrl = @"xmlrpcUrl",
};

const struct WordPressAccountRelationships WordPressAccountRelationships = {
	.wordPressImages = @"wordPressImages",
	.wordPressPosts = @"wordPressPosts",
};

const struct WordPressAccountFetchedProperties WordPressAccountFetchedProperties = {
};

@implementation WordPressAccountID
@end

@implementation _WordPressAccount

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"WordPressAccount" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"WordPressAccount";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"WordPressAccount" inManagedObjectContext:moc_];
}

- (WordPressAccountID*)objectID {
	return (WordPressAccountID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"blogIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"blogId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"hasTokenValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"hasToken"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic blogId;



- (int64_t)blogIdValue {
	NSNumber *result = [self blogId];
	return [result longLongValue];
}

- (void)setBlogIdValue:(int64_t)value_ {
	[self setBlogId:[NSNumber numberWithLongLong:value_]];
}

- (int64_t)primitiveBlogIdValue {
	NSNumber *result = [self primitiveBlogId];
	return [result longLongValue];
}

- (void)setPrimitiveBlogIdValue:(int64_t)value_ {
	[self setPrimitiveBlogId:[NSNumber numberWithLongLong:value_]];
}





@dynamic hasToken;



- (BOOL)hasTokenValue {
	NSNumber *result = [self hasToken];
	return [result boolValue];
}

- (void)setHasTokenValue:(BOOL)value_ {
	[self setHasToken:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveHasTokenValue {
	NSNumber *result = [self primitiveHasToken];
	return [result boolValue];
}

- (void)setPrimitiveHasTokenValue:(BOOL)value_ {
	[self setPrimitiveHasToken:[NSNumber numberWithBool:value_]];
}





@dynamic xmlrpcUrl;






@dynamic wordPressImages;

	
- (NSMutableSet*)wordPressImagesSet {
	[self willAccessValueForKey:@"wordPressImages"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"wordPressImages"];
  
	[self didAccessValueForKey:@"wordPressImages"];
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
