// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to WordPressPost.h instead.

#import <CoreData/CoreData.h>


extern const struct WordPressPostAttributes {
	__unsafe_unretained NSString *postId;
	__unsafe_unretained NSString *url;
} WordPressPostAttributes;

extern const struct WordPressPostRelationships {
	__unsafe_unretained NSString *account;
	__unsafe_unretained NSString *post;
} WordPressPostRelationships;

extern const struct WordPressPostFetchedProperties {
} WordPressPostFetchedProperties;

@class WordPressAccount;
@class Post;




@interface WordPressPostID : NSManagedObjectID {}
@end

@interface _WordPressPost : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (WordPressPostID*)objectID;





@property (nonatomic, strong) NSNumber* postId;



@property int64_t postIdValue;
- (int64_t)postIdValue;
- (void)setPostIdValue:(int64_t)value_;

//- (BOOL)validatePostId:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* url;



//- (BOOL)validateUrl:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) WordPressAccount *account;

//- (BOOL)validateAccount:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) Post *post;

//- (BOOL)validatePost:(id*)value_ error:(NSError**)error_;





@end

@interface _WordPressPost (CoreDataGeneratedAccessors)

@end

@interface _WordPressPost (CoreDataGeneratedPrimitiveAccessors)


- (NSNumber*)primitivePostId;
- (void)setPrimitivePostId:(NSNumber*)value;

- (int64_t)primitivePostIdValue;
- (void)setPrimitivePostIdValue:(int64_t)value_;




- (NSString*)primitiveUrl;
- (void)setPrimitiveUrl:(NSString*)value;





- (WordPressAccount*)primitiveAccount;
- (void)setPrimitiveAccount:(WordPressAccount*)value;



- (Post*)primitivePost;
- (void)setPrimitivePost:(Post*)value;


@end
