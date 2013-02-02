//
//  NSManagedObject+AZCoreRecordImport.h
//  AZCoreRecord
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

/** Importing for Core Data.
 
 These utilities do their best to safely, securely, and efficiently import Core
 Data objects using NSDictionary and NSArray to do the bulk of the work. This
 allows you to simply import to your data model from JSON, XML, or HTTP requests
 without worrying about finding and keeping track of existing objects yourself.
 
 On the whole, the update methods are slower because they always look for
 existing objects for relationships. However, it is only recommended to import
 when you are sure the new objects (and all relationships they contain) aren't
 already in the model, unless you plan on writing yourself a grand old garbage
 collection/duplicate resolution algorithm.
 
 AZCoreRecord will use a number of user info keys on your entities, their
 attributes, and their relationships to import. They are as follows:
 
 *Entities*
 
 - `className` (`AZCoreRecordImportClassNameKey`): The value of this is used
 to determine what key in the dictionary should be used to determine the class
 name/entity name of the model the dictionary correlates to. This is especially
 useful for importing sub-entities in relationships.
 - `primaryAttribute` (`AZCoreRecordImportPrimaryAttributeKey`): The value for
 this key is used for comparing and locating model objects. If no value is
 provided for this key, AZCoreRecord will search for a property with the name
 `xID`, where `x` is the first letter of the entity name in lowercase.
 
 *Attributes*
 
 - `mappedKey` (`AZCoreRecordImportMapKey`): The value of this is used to
 determine what a key in the dictionary should be inserted into the model as. To
 set the property "lastModify" on an entity using a dictionary that has a key
 "lastModifiedDate", set `mappedKey` to "lastModifiedDate" on that attribute.
 - `className` (`AZCoreRecordImportClassNameKey`): Similar to its use at the
 entity level, this forces the class of the imported object into that of the
 value for this key. Note that it is recommended to use value transformers
 instead.
 - `dateFormat` (`AZCoreRecordImportCustomDateFormat`): For a date attribute,
 AZCoreRecord can automatically format a string into a date object. The value
 of this key is used in the date formatter. If it is not set,
 "yyyy-MM-dd'T'HH:mm:ss'Z'" (`AZCoreRecordImportDefaultDateFormat`) is used by
 default.
 
 *Relationships*
 
 - `mappedKey` (`AZCoreRecordImportMapKey`): Same as for an attribute.
 - `primaryKey` (`AZCoreRecordImportRelationshipPrimaryKey`): Compare to
 `primaryAttribute`. This key is used in relationships to define what objects to
 search for when associating different model objects using relationships in
 imported dictionaries.
 
 **/

extern NSString *const AZCoreRecordImportCustomDateFormat;
extern NSString *const AZCoreRecordImportDefaultDateFormat;

extern NSString *const AZCoreRecordImportMapKey;
extern NSString *const AZCoreRecordImportClassNameKey;

extern NSString *const AZCoreRecordImportPrimaryAttributeKey;
extern NSString *const AZCoreRecordImportRelationshipPrimaryKey;

@interface NSManagedObject (AZCoreRecordImport)

/** Imports values into a managed object by using
 the contents of a dictionary, creating new model
 objects for all relationships.
 
 @param objectData A dictionary of values.
 @see updateValuesFromDictionary:
 */
- (void) importValuesFromDictionary: (NSDictionary *) objectData;

/** Updates the values of a managed object using
 the contents of a dictionary by finding objects for
 relationships, creating them if not found, and 
 associating them.
 
 @param objectData A dictionary of values
 @see importValuesFromDictionary:
 */
- (void) updateValuesFromDictionary: (NSDictionary *) objectData;

/** Creates a new model object for the specified entity
 and sets its values using the contents of a dictionary
 in the default context.
 
 @see importFromDictionary:inContext:
 @see importValuesFromDictionary:
 @param data A dictionary of values;
 @return A new managed object.
 */
+ (instancetype) importFromDictionary: (NSDictionary *) data;

/** Creates a new model object for the specified entity
 and sets its values using the contents of a dictionary.
 
 @see importFromDictionary:
 @see importValuesFromDictionary:
 @param data A dictionary of values;
 @param context A managed object context.
 @return A new managed object.
 */
+ (instancetype) importFromDictionary: (NSDictionary *) data inContext: (NSManagedObjectContext *) context;

/** Finds, and if not found creates, a model object
 for the specified entity and sets its values using
 the contents of a dictionary in the default context.
 
 Remember that existing objects are discovered
 using the value of the attribute named xID, where
 x is the first letter of the entity name, or the
 value of the attribute named by the user-info
 key primaryAttribute.
 
 @see updateFromDictionary:inContext:
 @see updateValuesFromDictionary:
 @param objectData A dictionary of values.
 @return A managed object.
 */
+ (instancetype) updateFromDictionary: (NSDictionary *) objectData;

/** Finds, and if not found creates, a model object
 for the specified entity and sets its values using
 the contents of a dictionary in the given context.
 
 Remember that existing objects are discovered
 using the value of the attribute named xID, where
 x is the first letter of the entity name, or the
 value of the attribute named by the user-info
 key primaryAttribute.
 
 @see updateFromDictionary:inContext:
 @see updateValuesFromDictionary:
 @param objectData A dictionary of values.
 @param context A managed object context.
 @return A managed object.
 */
+ (instancetype) updateFromDictionary: (NSDictionary *) objectData inContext: (NSManagedObjectContext *) context;

/** Imports values into a Core Data model by
 creating new instances of the specified entity
 and sets their values using the given dictionaries
 in the defai;t context.
 
 @see importFromArray:inContext:
 @see importValuesFromDictionary:
 @param listOfObjectData An array of dictionaries.
 @return An array of new objects.
 */
+ (NSArray *) importFromArray: (NSArray *) listOfObjectData;

/** Imports values into a Core Data model by
 creating new instances of the specified entity
 and sets their values using the given dictionaries
 in the specified context.
 
 @see importFromArray:inContext:
 @see importValuesFromDictionary:
 @param context A managed object context.
 @param listOfObjectData An array of dictionaries.
 @return An array of updated managed objects.
 */
+ (NSArray *) importFromArray: (NSArray *) listOfObjectData inContext: (NSManagedObjectContext *) context;

/** Updates a Core Data model with an array of
 dictionary objects by locating objects, creating
 them if not found, and saving asynchronously on the
 main managed object context.
 
 Whereas importing will always create new model objects,
 updating will only create new model objects that
 cannot be found.
 
 @param listOfObjectData An array of dictionary objects.
 @see updateFromArray:inContext:
 @see updateValuesFromDictionary:
 @see updateFromDictionary:
 @return An array of updated managed objects.
 */
+ (NSArray *) updateFromArray: (NSArray *) listOfObjectData;

/** Updates a Core Data model with an array of
 dictionary objects by locating objects, and creating
 them if not found, on the given context.
 
 Remember that, while importing will always create new model objects,
 updating will only create new model objects that
 cannot be found.
 
 @param listOfObjectData An array of dictionary objects.
 @param localContext A managed object context that is preferably not the main one.
 @see updateFromArray:
 @see updateValuesFromDictionary:
 @see updateFromDictionary:inContext:
 @return An array of updated managed objects.
 */
+ (NSArray *) updateFromArray: (NSArray *) listOfObjectData inContext: (NSManagedObjectContext *) localContext;

@end
