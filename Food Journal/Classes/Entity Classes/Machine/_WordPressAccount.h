// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WordPressAccount.h instead.

#import <CoreData/CoreData.h>
#import "Account.h"

extern const struct WordPressAccountAttributes {
	__unsafe_unretained NSString *blogId;
	__unsafe_unretained NSString *hasToken;
	__unsafe_unretained NSString *xmlrpcUrl;
} WordPressAccountAttributes;

extern const struct WordPressAccountRelationships {
	__unsafe_unretained NSString *wordPressImages;
	__unsafe_unretained NSString *wordPressPosts;
} WordPressAccountRelationships;

extern const struct WordPressAccountFetchedProperties {
} WordPressAccountFetchedProperties;

@class WordPressImage;
@class WordPressPost;





@interface WordPressAccountID : NSManagedObjectID {}
@end

@interface _WordPressAccount : Account {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WordPressAccountID*)objectID;





@property (nonatomic, strong) NSNumber* blogId;



@property int64_t blogIdValue;
- (int64_t)blogIdValue;
- (void)setBlogIdValue:(int64_t)value_;

//- (BOOL)validateBlogId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* hasToken;



@property BOOL hasTokenValue;
- (BOOL)hasTokenValue;
- (void)setHasTokenValue:(BOOL)value_;

//- (BOOL)validateHasToken:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* xmlrpcUrl;



//- (BOOL)validateXmlrpcUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *wordPressImages;

- (NSMutableSet*)wordPressImagesSet;




@property (nonatomic, strong) NSSet *wordPressPosts;

- (NSMutableSet*)wordPressPostsSet;





@end

@interface _WordPressAccount (CoreDataGeneratedAccessors)

- (void)addWordPressImages:(NSSet*)value_;
- (void)removeWordPressImages:(NSSet*)value_;
- (void)addWordPressImagesObject:(WordPressImage*)value_;
- (void)removeWordPressImagesObject:(WordPressImage*)value_;

- (void)addWordPressPosts:(NSSet*)value_;
- (void)removeWordPressPosts:(NSSet*)value_;
- (void)addWordPressPostsObject:(WordPressPost*)value_;
- (void)removeWordPressPostsObject:(WordPressPost*)value_;

@end

@interface _WordPressAccount (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitiveBlogId;
- (void)setPrimitiveBlogId:(NSNumber*)value;

- (int64_t)primitiveBlogIdValue;
- (void)setPrimitiveBlogIdValue:(int64_t)value_;




- (NSNumber*)primitiveHasToken;
- (void)setPrimitiveHasToken:(NSNumber*)value;

- (BOOL)primitiveHasTokenValue;
- (void)setPrimitiveHasTokenValue:(BOOL)value_;




- (NSString*)primitiveXmlrpcUrl;
- (void)setPrimitiveXmlrpcUrl:(NSString*)value;





- (NSMutableSet*)primitiveWordPressImages;
- (void)setPrimitiveWordPressImages:(NSMutableSet*)value;



- (NSMutableSet*)primitiveWordPressPosts;
- (void)setPrimitiveWordPressPosts:(NSMutableSet*)value;


@end
