// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Food.h instead.

#import <CoreData/CoreData.h>


extern const struct FoodAttributes {
	__unsafe_unretained NSString *name;
} FoodAttributes;

extern const struct FoodRelationships {
	__unsafe_unretained NSString *meal;
} FoodRelationships;

extern const struct FoodFetchedProperties {
} FoodFetchedProperties;

@class Meal;



@interface FoodID : NSManagedObjectID {}
@end

@interface _Food : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (FoodID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Meal *meal;

//- (BOOL)validateMeal:(id*)value_ error:(NSError**)error_;





@end

@interface _Food (CoreDataGeneratedAccessors)

@end

@interface _Food (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (Meal*)primitiveMeal;
- (void)setPrimitiveMeal:(Meal*)value;


@end
