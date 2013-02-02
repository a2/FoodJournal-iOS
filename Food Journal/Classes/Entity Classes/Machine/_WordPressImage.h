// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WordPressImage.h instead.

#import <CoreData/CoreData.h>


extern const struct WordPressImageAttributes {
	__unsafe_unretained NSString *attachmentId;
	__unsafe_unretained NSString *url;
} WordPressImageAttributes;

extern const struct WordPressImageRelationships {
	__unsafe_unretained NSString *account;
	__unsafe_unretained NSString *image;
} WordPressImageRelationships;

extern const struct WordPressImageFetchedProperties {
} WordPressImageFetchedProperties;

@class WordPressAccount;
@class Image;




@interface WordPressImageID : NSManagedObjectID {}
@end

@interface _WordPressImage : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WordPressImageID*)objectID;





@property (nonatomic, strong) NSNumber* attachmentId;



@property int64_t attachmentIdValue;
- (int64_t)attachmentIdValue;
- (void)setAttachmentIdValue:(int64_t)value_;

//- (BOOL)validateAttachmentId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* url;



//- (BOOL)validateUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) WordPressAccount *account;

//- (BOOL)validateAccount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) Image *image;

//- (BOOL)validateImage:(id*)value_ error:(NSError**)error_;





@end

@interface _WordPressImage (CoreDataGeneratedAccessors)

@end

@interface _WordPressImage (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveAttachmentId;
- (void)setPrimitiveAttachmentId:(NSNumber*)value;

- (int64_t)primitiveAttachmentIdValue;
- (void)setPrimitiveAttachmentIdValue:(int64_t)value_;




- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;





- (WordPressAccount*)primitiveAccount;
- (void)setPrimitiveAccount:(WordPressAccount*)value;



- (Image*)primitiveImage;
- (void)setPrimitiveImage:(Image*)value;


@end
