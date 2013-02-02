// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Image.h instead.

#import <CoreData/CoreData.h>


extern const struct ImageAttributes {
	__unsafe_unretained NSString *imageData;
	__unsafe_unretained NSString *largeThumbnailImageData;
	__unsafe_unretained NSString *smallThumbnailImageData;
} ImageAttributes;

extern const struct ImageRelationships {
	__unsafe_unretained NSString *meal;
	__unsafe_unretained NSString *wordPressImages;
} ImageRelationships;

extern const struct ImageFetchedProperties {
} ImageFetchedProperties;

@class Meal;
@class WordPressImage;





@interface ImageID : NSManagedObjectID {}
@end

@interface _Image : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ImageID*)objectID;





@property (nonatomic, strong) NSData* imageData;



//- (BOOL)validateImageData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* largeThumbnailImageData;



//- (BOOL)validateLargeThumbnailImageData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSData* smallThumbnailImageData;



//- (BOOL)validateSmallThumbnailImageData:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Meal *meal;

//- (BOOL)validateMeal:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *wordPressImages;

- (NSMutableSet*)wordPressImagesSet;





@end

@interface _Image (CoreDataGeneratedAccessors)

- (void)addWordPressImages:(NSSet*)value_;
- (void)removeWordPressImages:(NSSet*)value_;
- (void)addWordPressImagesObject:(WordPressImage*)value_;
- (void)removeWordPressImagesObject:(WordPressImage*)value_;

@end

@interface _Image (CoreDataGeneratedPrimitiveAccessors)


- (NSData*)primitiveImageData;
- (void)setPrimitiveImageData:(NSData*)value;




- (NSData*)primitiveLargeThumbnailImageData;
- (void)setPrimitiveLargeThumbnailImageData:(NSData*)value;




- (NSData*)primitiveSmallThumbnailImageData;
- (void)setPrimitiveSmallThumbnailImageData:(NSData*)value;





- (Meal*)primitiveMeal;
- (void)setPrimitiveMeal:(Meal*)value;



- (NSMutableSet*)primitiveWordPressImages;
- (void)setPrimitiveWordPressImages:(NSMutableSet*)value;


@end
