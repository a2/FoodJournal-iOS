//
//  UIImage+Tint.m
//
//  Created by Matt Gemmell on 04/07/2010.
//  Copyright 2010 Instinctive Code.
//

#import "UIImage+Tint.h"

extern void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale) WEAK_IMPORT_ATTRIBUTE;

@implementation UIImage (MGTint)

- (UIImage *)imageTintedWithColor:(UIColor *)color
{
	// This method is designed for use with template images, i.e. solid-coloured mask-like images.
	return [self imageTintedWithColor:color fraction:0.0 blendMode:kCGBlendModeDestinationIn]; // default to a fully tinted mask of the image.
}
- (UIImage *)imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction
{
	return [self imageTintedWithColor:color fraction:fraction blendMode:kCGBlendModeDestinationIn];
}
- (UIImage *)imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction blendMode:(CGBlendMode)blendMode
{
	if (color) {
		// Construct new image the same size as this one.
		UIGraphicsBeginImageContextWithOptions([self size], NO, 0.0); // 0.0 for scale means "scale for device's main screen".
		
		CGRect rect = CGRectZero;
		rect.size = [self size];
		
		// Composite tint color at its own opacity.
		[color set];
		UIRectFill(rect);
		
		// Mask tint color-swatch to this image's opaque mask.
		// We want behaviour like NSCompositeDestinationIn on Mac OS X.
		[self drawInRect:rect blendMode:blendMode alpha:1.0];
		
		// Finally, composite this image over the tinted mask at desired opacity.
		if (fraction > 0.0) {
			// We want behaviour like NSCompositeSourceOver on Mac OS X.
			[self drawInRect:rect blendMode:kCGBlendModeSourceAtop alpha:fraction];
		}
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		
		return image;
	}
	
	return self;
}

@end
