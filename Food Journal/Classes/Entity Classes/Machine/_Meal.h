// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Meal.h instead.

#import <CoreData/CoreData.h>


extern const struct MealAttributes {
	__unsafe_unretained NSString *name;
} MealAttributes;

extern const struct MealRelationships {
	__unsafe_unretained NSString *foods;
	__unsafe_unretained NSString *images;
	__unsafe_unretained NSString *post;
} MealRelationships;

extern const struct MealFetchedProperties {
} MealFetchedProperties;

@class Food;
@class Image;
@class Post;



@interface MealID : NSManagedObjectID {}
@end

@interface _Meal : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MealID*)objectID;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet *foods;

- (NSMutableOrderedSet*)foodsSet;




@property (nonatomic, strong) NSOrderedSet *images;

- (NSMutableOrderedSet*)imagesSet;




@property (nonatomic, strong) Post *post;

//- (BOOL)validatePost:(id*)value_ error:(NSError**)error_;





@end

@interface _Meal (CoreDataGeneratedAccessors)

- (void)addFoods:(NSOrderedSet*)value_;
- (void)removeFoods:(NSOrderedSet*)value_;
- (void)addFoodsObject:(Food*)value_;
- (void)removeFoodsObject:(Food*)value_;

- (void)addImages:(NSOrderedSet*)value_;
- (void)removeImages:(NSOrderedSet*)value_;
- (void)addImagesObject:(Image*)value_;
- (void)removeImagesObject:(Image*)value_;

@end

@interface _Meal (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (NSMutableOrderedSet*)primitiveFoods;
- (void)setPrimitiveFoods:(NSMutableOrderedSet*)value;



- (NSMutableOrderedSet*)primitiveImages;
- (void)setPrimitiveImages:(NSMutableOrderedSet*)value;



- (Post*)primitivePost;
- (void)setPrimitivePost:(Post*)value;


@end
