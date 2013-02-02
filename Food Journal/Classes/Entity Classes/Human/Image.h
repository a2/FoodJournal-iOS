#import "_Image.h"

@interface Image : _Image

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic, readonly) UIImage *largeThumbnailImage;
@property (strong, nonatomic, readonly) UIImage *smallThumbnailImage;

@end
