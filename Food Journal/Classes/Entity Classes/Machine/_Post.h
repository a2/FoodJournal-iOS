// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Post.h instead.

#import <CoreData/CoreData.h>


extern const struct PostAttributes {
	__unsafe_unretained NSString *contents;
	__unsafe_unretained NSString *date;
} PostAttributes;

extern const struct PostRelationships {
	__unsafe_unretained NSString *meals;
	__unsafe_unretained NSString *wordPressPosts;
} PostRelationships;

extern const struct PostFetchedProperties {
} PostFetchedProperties;

@class Meal;
@class WordPressPost;




@interface PostID : NSManagedObjectID {}
@end

@interface _Post : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (PostID*)objectID;





@property (nonatomic, strong) NSString* contents;



//- (BOOL)validateContents:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* date;



//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSOrderedSet *meals;

- (NSMutableOrderedSet*)mealsSet;




@property (nonatomic, strong) NSSet *wordPressPosts;

- (NSMutableSet*)wordPressPostsSet;





@end

@interface _Post (CoreDataGeneratedAccessors)

- (void)addMeals:(NSOrderedSet*)value_;
- (void)removeMeals:(NSOrderedSet*)value_;
- (void)addMealsObject:(Meal*)value_;
- (void)removeMealsObject:(Meal*)value_;

- (void)addWordPressPosts:(NSSet*)value_;
- (void)removeWordPressPosts:(NSSet*)value_;
- (void)addWordPressPostsObject:(WordPressPost*)value_;
- (void)removeWordPressPostsObject:(WordPressPost*)value_;

@end

@interface _Post (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveContents;
- (void)setPrimitiveContents:(NSString*)value;




- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;





- (NSMutableOrderedSet*)primitiveMeals;
- (void)setPrimitiveMeals:(NSMutableOrderedSet*)value;



- (NSMutableSet*)primitiveWordPressPosts;
- (void)setPrimitiveWordPressPosts:(NSMutableSet*)value;


@end
