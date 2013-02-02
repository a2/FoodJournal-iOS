#import "Image.h"

@interface Image ()

@end

@implementation Image

#if 0
- (void)awakeFromFetch
{
	[super awakeFromFetch];
	
	UIImage *anImage = self.image.fixOrientation;
	UIImage *largeThumbnailImage = [anImage imageScaledToFitSize:CGSizeMake(FJImageLargeThumbnailHeight, CGFLOAT_MAX)];
	self.largeThumbnailImageData = UIImageJPEGRepresentation(largeThumbnailImage, 0.7);
	
	UIImage *smallThumbnailImage = [anImage imageCroppedToFitSize:FJImageSmallThumbnailSize];
	self.smallThumbnailImageData = UIImageJPEGRepresentation(smallThumbnailImage, 0.7);
	
	[self.managedObjectContext save];
}
#endif

#pragma mark - Image Accessors

+ (NSSet *)keyPathsForValuesAffectingImage
{
	return [NSSet setWithObject:ImageAttributes.imageData];
}

- (UIImage *)image
{
	return [UIImage imageWithData:self.imageData];
}

- (void)setImage:(UIImage *)anImage
{
	anImage = anImage.fixOrientation;
	self.imageData = UIImageJPEGRepresentation(anImage, 0.7);
	
	UIImage *largeThumbnailImage = [anImage imageScaledToFitSize:CGSizeMake(FJImageLargeThumbnailHeight, CGFLOAT_MAX)];
	self.largeThumbnailImageData = UIImageJPEGRepresentation(largeThumbnailImage, 0.7);
	
	UIImage *smallThumbnailImage = [anImage imageCroppedToFitSize:FJImageSmallThumbnailSize];;
	self.smallThumbnailImageData = UIImageJPEGRepresentation(smallThumbnailImage, 0.7);
}

#pragma mark - Large Thumbnail Image Accessors

+ (NSSet *)keyPathsForValuesAffectingLargeThumbnailImage
{
	return [NSSet setWithObjects:ImageAttributes.imageData, ImageAttributes.largeThumbnailImageData, nil];
}

- (UIImage *)largeThumbnailImage
{
	if (!self.largeThumbnailImageData.length && self.imageData.length)
	{
		UIImage *largeThumbnailImage = [self.image.fixOrientation imageScaledToFitSize:CGSizeMake(FJImageLargeThumbnailHeight, CGFLOAT_MAX)];
		self.largeThumbnailImageData = UIImageJPEGRepresentation(largeThumbnailImage, 0.7);
		return largeThumbnailImage;
	}
	
	return [UIImage imageWithData:self.largeThumbnailImageData];
}

#pragma mark - Small Thumbnail Image Accessors

+ (NSSet *)keyPathsForValuesAffectingSmallThumbnailImage
{
	return [NSSet setWithObjects:ImageAttributes.imageData, ImageAttributes.smallThumbnailImageData, nil];
}

- (UIImage *)smallThumbnailImage
{
	if (!self.smallThumbnailImageData.length && self.imageData.length)
	{
		UIImage *smallThumbnailImage = [self.image.fixOrientation imageCroppedToFitSize:FJImageSmallThumbnailSize];
		self.smallThumbnailImageData = UIImageJPEGRepresentation(smallThumbnailImage, 0.7);
		return smallThumbnailImage;
	}
	
	return [UIImage imageWithData:self.smallThumbnailImageData];
}

@end
