//
//  NSManagedObject+AZCoreRecordImport.m
//  AZCoreRecord
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObject+AZCoreRecordImport.h"
#import "AZCoreRecordManager.h"
#import <objc/message.h>
#import "NSManagedObject+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#import <Cocoa/Cocoa.h>
#endif

static id azcr_colorFromString(NSString *serializedColor)
{
	BOOL isRGB = [serializedColor hasPrefix: @"rgb"];
	BOOL isHSB = [serializedColor hasPrefix: @"hsb"];
	BOOL isHSV = [serializedColor hasPrefix: @"hsv"];
	double divisor = (isRGB || isHSB || isHSV) ? 255.0 : 1.0;
	
	NSScanner *colorScanner = [NSScanner scannerWithString: serializedColor];
	
	NSCharacterSet *delimiters = [[NSCharacterSet characterSetWithCharactersInString: @"0.123456789"] invertedSet];
	[colorScanner scanUpToCharactersFromSet: delimiters intoString: NULL];
	
	CGFloat *components = calloc(4, sizeof(CGFloat));
	components[3] = 1.0;
	
	CGFloat *component = components;
	while (![colorScanner isAtEnd])
	{
		[colorScanner scanCharactersFromSet: delimiters intoString: NULL];
#if CGFLOAT_IS_DOUBLE
		[colorScanner scanDouble: component];
#else
		[colorScanner scanFloat: component];
#endif
		component++;
	}
	
	// Normalize values
	for (int i = 0; i <= 2; ++i) components[i] = MIN(components[i] / divisor, divisor);
	
	// Convert HSB to HSV
	if (isHSV) components[3] = divisor - components[3];
	
	id color = nil;
	
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	if (isHSB || isHSV)
	{
		color = [UIColor colorWithHue: components[0] saturation: components[1] brightness: components[2] alpha: components[3]];
	}
	else
	{
		color = [UIColor colorWithRed: components[0] green: components[1] blue: components[2] alpha: components[3]];
	}
#else
	if (isHSB || isHSV)
	{
		color = [NSColor colorWithDeviceHue: components[0] saturation: components[1] brightness: components[2] alpha: components[3]];
	}
	else
	{
		color = [NSColor colorWithDeviceRed: components[0] green: components[1] blue: components[2] alpha: components[3]];
	}
#endif

	free(components);
	return color;
}

static NSDate *azcr_dateAdjustForDST(NSDate *date)
{
	NSTimeInterval dstOffset = [[NSTimeZone localTimeZone] daylightSavingTimeOffsetForDate: date];
	NSDate *actualDate = [date dateByAddingTimeInterval: dstOffset];
	return actualDate;
}

static NSDate *azcr_dateFromString(NSString *value, NSString *format)
{
	static dispatch_once_t onceToken;
	static NSDateFormatter *helperFormatter;
	dispatch_once(&onceToken, ^{
		helperFormatter = [NSDateFormatter new];
		helperFormatter.timeZone = [NSTimeZone localTimeZone];
		helperFormatter.locale = [NSLocale currentLocale];
	});
	
	helperFormatter.dateFormat = (format ?: AZCoreRecordImportDefaultDateFormat);
	return [helperFormatter dateFromString: value];
}

static NSString *azcr_attributeNameFromString(NSString *value)
{
	NSString *firstCharacter = [[value substringToIndex: 1] capitalizedString];
	value = [value stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstCharacter];
	
	return value;
}
static NSString *azcr_primaryKeyNameFromString(NSString *value)
{
	NSString *firstCharacter = [[value substringToIndex: 1] lowercaseString];
	value = [value stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstCharacter];
	value = [value stringByAppendingString: @"ID"];
	
	return value;
}

NSString *const AZCoreRecordImportCustomDateFormat = @"dateFormat";
NSString *const AZCoreRecordImportDefaultDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

NSString *const AZCoreRecordImportMapKey = @"mappedKey";
NSString *const AZCoreRecordImportClassNameKey = @"className";

NSString *const AZCoreRecordImportPrimaryAttributeKey = @"primaryAttribute";
NSString *const AZCoreRecordImportRelationshipPrimaryKey = @"primaryKey";

@implementation NSManagedObject (AZCoreRecordImport)

#pragma mark - Private Helper Methods

- (NSManagedObject *) azcr_createInstanceForEntity: (NSEntityDescription *) entityDescription withDictionary: (id) objectData
{
	NSManagedObject *relatedObject = [NSEntityDescription insertNewObjectForEntityForName: [entityDescription name] inManagedObjectContext: [self managedObjectContext]];
	[relatedObject importValuesFromDictionary: objectData];
	
	return relatedObject;
}
- (NSManagedObject *) azcr_findObjectForRelationship: (NSRelationshipDescription *) relationshipInfo withData: (id) singleRelatedObjectData
{
	if ([singleRelatedObjectData isKindOfClass: [NSManagedObject class]])
	{
		NSEntityDescription *objectDataEntity = [(NSManagedObject *) singleRelatedObjectData entity];
		NSEntityDescription *destinationEntity = relationshipInfo.destinationEntity;
		
		if ([objectDataEntity isEqual: destinationEntity] || [objectDataEntity isKindOfEntity: destinationEntity])
			return singleRelatedObjectData;
		
		return nil;
	}
	else if ([singleRelatedObjectData isKindOfClass: [NSURL class]])
	{
		NSPersistentStoreCoordinator *psc = self.managedObjectContext.persistentStoreCoordinator;
		NSManagedObjectID *objectID = [psc managedObjectIDForURIRepresentation: singleRelatedObjectData];
		
		return [self.managedObjectContext existingObjectWithID: objectID error: nil];
	}
	else if ([singleRelatedObjectData isKindOfClass: [NSManagedObjectID class]])
	{
		return [self.managedObjectContext existingObjectWithID: singleRelatedObjectData error: nil];
	}
	
	id relatedValue = nil;
	
	NSEntityDescription *destination = relationshipInfo.destinationEntity;
	
	if ([singleRelatedObjectData isKindOfClass: [NSNumber class]] || [singleRelatedObjectData isKindOfClass: [NSString class]])
	{
		relatedValue = singleRelatedObjectData;
	}
	else if ([singleRelatedObjectData isKindOfClass: [NSDictionary class]])
	{
		NSString *destinationKey = [relationshipInfo.userInfo objectForKey: AZCoreRecordImportClassNameKey];
		NSString *destinationName = [singleRelatedObjectData objectForKey: destinationKey];
		if (destinationName)
		{
			NSEntityDescription *customDestination = [NSEntityDescription entityForName: destinationName inManagedObjectContext: self.managedObjectContext];
			if ([customDestination isKindOfEntity: destination]) destination = customDestination;
		}
		
		NSEntityDescription *destinationEntity = relationshipInfo.destinationEntity;
		NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey: AZCoreRecordImportRelationshipPrimaryKey] ?: [destinationEntity.userInfo valueForKey: AZCoreRecordImportRelationshipPrimaryKey] ?: azcr_primaryKeyNameFromString(relationshipInfo.destinationEntity.name);
		
		NSAttributeDescription *primaryKeyAttribute = [destinationEntity.attributesByName valueForKey: primaryKeyName];
		NSString *lookupKey = [primaryKeyAttribute.userInfo valueForKey: AZCoreRecordImportMapKey] ?: primaryKeyAttribute.name;

		relatedValue = [singleRelatedObjectData valueForKeyPath: lookupKey];
	}
	
	if (!relatedValue)
		return nil;

	Class managedObjectClass = NSClassFromString([destination managedObjectClassName]);
	NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey: AZCoreRecordImportRelationshipPrimaryKey];
	if (!primaryKeyName) primaryKeyName = azcr_primaryKeyNameFromString(relationshipInfo.destinationEntity.name);
	
	id object = [managedObjectClass findFirstWhere: primaryKeyName equals: relatedValue inContext: self.managedObjectContext];
	if (!object)
		object = [managedObjectClass createInContext: self.managedObjectContext];
	if ([singleRelatedObjectData isKindOfClass: [NSDictionary class]])
		[object updateValuesFromDictionary: singleRelatedObjectData];
	
	return object;
}

- (void) azcr_addObject: (NSManagedObject *) relatedObject forRelationship: (NSRelationshipDescription *) relationshipInfo
{
	NSAssert2(relatedObject, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), relationshipInfo.name);
	NSAssert2([relatedObject.entity isKindOfEntity: relationshipInfo.destinationEntity], @"Related object entity %@ must be same as destination entity %@", relatedObject.entity.name, relationshipInfo.destinationEntity.name);
	
	// Add related object to set
	NSString *key = relationshipInfo.name;
	if (relationshipInfo.isToMany)
	{
		if (relationshipInfo.isOrdered)
			[[self mutableOrderedSetValueForKey: key] addObject: relatedObject];
		else
			[[self mutableSetValueForKey: key] addObject: relatedObject];
	}
	else
	{
		[self setValue: relatedObject forKey: key];
	}
}
- (void) azcr_setAttributes: (NSDictionary *) attributes forDictionary: (NSDictionary *) objectData
{
	[attributes enumerateKeysAndObjectsUsingBlock: ^(NSString *attributeName, NSAttributeDescription *attributeInfo, BOOL *stop) {
		NSString *key = [attributeInfo.userInfo valueForKey: AZCoreRecordImportMapKey] ?: attributeInfo.name;
		if (!key.length)
			return;

		id value = [objectData valueForKeyPath: key];

		for (int i = 1; i < 10 && value == nil; ++i)
		{
			NSString *attributeName = [NSString stringWithFormat: @"%@.%d", AZCoreRecordImportMapKey, i];
			key = [attributeInfo.userInfo valueForKey: attributeName];
			value = [objectData valueForKeyPath: key];
		}

		NSAttributeType attributeType = attributeInfo.attributeType;
		NSString *desiredAttributeType = [attributeInfo.userInfo valueForKey: AZCoreRecordImportClassNameKey];

		if (desiredAttributeType && [desiredAttributeType hasSuffix: @"Color"])
		{
			value = azcr_colorFromString(value);
		}
		else if (attributeType == NSDateAttributeType)
		{
			if (![value isKindOfClass: [NSDate class]])
			{
				NSString *dateFormat = [attributeInfo.userInfo valueForKey: AZCoreRecordImportCustomDateFormat];
				value = azcr_dateFromString([value description], dateFormat);
			}

			value = azcr_dateAdjustForDST(value);
		}

		if (!value)	// If it just wasn't set, leave the default
			return;

		if (value == [NSNull null])	// if it was *explicitly* set to nil, set
			value = nil;

		[self setValue: value forKey: attributeName];
	}];
}
- (void) azcr_setRelationships: (NSDictionary *) relationships forDictionary: (NSDictionary *) relationshipData withBlock: (NSManagedObject *(^)(NSRelationshipDescription *, id)) setRelationship
{
	[relationships enumerateKeysAndObjectsUsingBlock: ^(NSString *relationshipName, NSRelationshipDescription *relationshipInfo, BOOL *stop) {
		NSString *lookupKey = [relationshipInfo.userInfo valueForKey: AZCoreRecordImportMapKey] ?: relationshipName;
		
		id relatedObjectData = [relationshipData valueForKeyPath: lookupKey];
		if (!relatedObjectData || [relatedObjectData isEqual: [NSNull null]]) 
			return;
		
		if (relationshipInfo.isToMany)
		{
			for (id singleRelatedObjectData in relatedObjectData)
			{
				NSManagedObject *obj = setRelationship(relationshipInfo, singleRelatedObjectData);
				[self azcr_addObject: obj forRelationship: relationshipInfo];
			}
		}
		else
		{
			NSManagedObject *obj = setRelationship(relationshipInfo, relatedObjectData);
			[self azcr_addObject: obj forRelationship: relationshipInfo];
		}
	}];
}

#pragma mark - Import from Dictionary

+ (instancetype) importFromDictionary: (id) objectData
{
	return [self importFromDictionary: objectData inContext: nil];
}
+ (instancetype) importFromDictionary: (id) objectData inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSManagedObject *managedObject = [self createInContext: context];
	[managedObject importValuesFromDictionary: objectData];
	return managedObject;
}

- (void) importValuesFromDictionary: (id) objectData
{
	@autoreleasepool
	{
		NSDictionary *attributes = self.entity.attributesByName;
		if (attributes.count)
		{
			[self azcr_setAttributes: attributes forDictionary: objectData];
		}
		
		NSDictionary *relationships = self.entity.relationshipsByName;
		if (relationships.count)
		{
			__weak NSManagedObject *weakSelf = self;
			[self azcr_setRelationships: relationships forDictionary: objectData withBlock: ^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData) {
				if ([objectData isKindOfClass: [NSDictionary class]])
				{
					NSEntityDescription *destination = relationshipInfo.destinationEntity;
					
					NSString *destinationKey = [relationshipInfo.userInfo objectForKey: AZCoreRecordImportClassNameKey];
					NSString *destinationName = [objectData objectForKey: destinationKey];
					
					if (destinationName)
					{
						NSManagedObjectContext *context = weakSelf.managedObjectContext;
						NSEntityDescription *customDestination = [NSEntityDescription entityForName: destinationName inManagedObjectContext: context];
						if ([customDestination isKindOfEntity: destination]) destination = customDestination;
					}
					
					return [weakSelf azcr_createInstanceForEntity: destination withDictionary: objectData];
				}
				
				return [weakSelf azcr_findObjectForRelationship: relationshipInfo withData: objectData];
			}];
		}
	}
}

#pragma mark - Update from Dictionary

+ (instancetype) updateFromDictionary: (id) objectData
{
	return [self updateFromDictionary: objectData inContext: nil];
}
+ (instancetype) updateFromDictionary: (id) objectData inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSEntityDescription *entity = [self entityDescriptionInContext: context];
	NSString *attributeKey = [entity.userInfo valueForKey: AZCoreRecordImportPrimaryAttributeKey] ?: azcr_primaryKeyNameFromString(entity.name);
	
	NSAttributeDescription *primaryAttribute = [entity.attributesByName valueForKey: attributeKey];
	NSAssert3(primaryAttribute, @"Unable to determine primary attribute for %@. Specify either an attribute named %@ or the primary key in userInfo named '%@'", entity.name, attributeKey, AZCoreRecordImportPrimaryAttributeKey);
	
	NSString *lookupKey = [primaryAttribute.userInfo valueForKey: AZCoreRecordImportMapKey] ?: primaryAttribute.name;
	id value = [objectData valueForKeyPath: lookupKey];
	
	NSManagedObject *managedObject = [self findFirstWhere: lookupKey equals: value inContext: context];
	if (!managedObject) managedObject = [self createInContext: context];
	
	[managedObject updateValuesFromDictionary: objectData];
	
	return managedObject;
}

- (void) updateValuesFromDictionary: (id) objectData
{
	@autoreleasepool
	{
		NSDictionary *attributes = self.entity.attributesByName;
		if (attributes.count)
		{
			[self azcr_setAttributes: attributes forDictionary: objectData];
		}
		
		NSDictionary *relationships = self.entity.relationshipsByName;
		if (relationships.count)
		{
			__weak NSManagedObject *weakSelf = self;
			[self azcr_setRelationships: relationships forDictionary: objectData withBlock: ^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData) {
				NSManagedObject *relatedObject = [weakSelf azcr_findObjectForRelationship: relationshipInfo withData: objectData];
				
				if (relatedObject)
				{
					if ([objectData isKindOfClass: [NSDictionary class]])
						[relatedObject importValuesFromDictionary: objectData];
					
					return relatedObject;
				}
				
				NSEntityDescription *destination = relationshipInfo.destinationEntity;
				
				if ([objectData isKindOfClass: [NSDictionary class]])
				{
					NSString *destinationKey = [relationshipInfo.userInfo objectForKey: AZCoreRecordImportClassNameKey];
					NSString *destinationName = [objectData objectForKey: destinationKey];
					
					if (destinationName)
					{
						NSManagedObjectContext *context = weakSelf.managedObjectContext;
						NSEntityDescription *customDestination = [NSEntityDescription entityForName: destinationName inManagedObjectContext: context];
						if ([customDestination isKindOfEntity: destination]) destination = customDestination;
					}
				}
				
				return [weakSelf azcr_createInstanceForEntity: destination withDictionary: objectData];
			}];
		}
	}
}

#pragma mark - Import from Array

+ (NSArray *) importFromArray: (NSArray *) listOfObjectData
{
	return [self importFromArray: listOfObjectData inContext: nil];
}
+ (NSArray *) importFromArray: (NSArray *) listOfObjectData inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	__block NSArray *objectIDs = nil;
	
	[context saveDataWithBlock: ^(NSManagedObjectContext *localContext) {
		NSMutableArray *objects = [NSMutableArray array];
		
		[listOfObjectData enumerateObjectsUsingBlock: ^(NSDictionary *objectData, NSUInteger idx, BOOL *stop) {
			[objects addObject: [self importFromDictionary: objectData inContext: localContext]];
		}];
		
		if ([context obtainPermanentIDsForObjects: objects error: NULL])
			objectIDs = [objects valueForKey: @"objectID"];
	}];
	
	return [self findAllWithPredicate: [NSPredicate predicateWithFormat: @"self IN %@", objectIDs] inContext: context];
}

#pragma mark - Update from Array

+ (NSArray *) updateFromArray: (NSArray *) listOfObjectData
{
	return [self updateFromArray: listOfObjectData inContext: nil];
}
+ (NSArray *) updateFromArray: (NSArray *) listOfObjectData inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	__block NSArray *objectIDs = nil;
	
	[context saveDataWithBlock: ^(NSManagedObjectContext *localContext) {
		NSMutableArray *objects = [NSMutableArray array];
		
		[listOfObjectData enumerateObjectsUsingBlock: ^(id objectData, NSUInteger idx, BOOL *stop) {
			[objects addObject: [self updateFromDictionary: objectData inContext: localContext]];
		}];
		
		if ([context obtainPermanentIDsForObjects: objects error: NULL])
			objectIDs = [objects valueForKey: @"objectID"];
	}];
	
	return [self findAllWithPredicate: [NSPredicate predicateWithFormat: @"self IN %@", objectIDs] inContext: context];
}

@end
