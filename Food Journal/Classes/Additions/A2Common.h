//
//  A2Common.h
//
//  Created by Alexsander Akers on 9/4/11.
//  Copyright (c) 2011-2012 Pandamonia LLC. All rights reserved.
//

#define A2Log(format, ...) NSLog(@"%s <line %d> " format, __PRETTY_FUNCTION__, __LINE__, ## __VA_ARGS__)

#define A2LogError(error) A2Log(@"Error = %@", (error))
#define A2LogException(exception) A2Log(@"Exception = %@", (exception))

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

	#define A2DependsDevice(iphone, ipad) ([UIDevice isPhone] ? (iphone) : (ipad))
	#define A2DependsOrient(io, port, land) (UIInterfaceOrientationIsPortrait(io) ? (port) : (land))
	#define A2DependsBoth(io, iphonePort, iphoneLand, ipadPort, ipadLand) (A2DependsOrient(io, A2DependsDevice((iphonePort), (ipadPort)), A2DependsDevice((iphoneLand), (ipadLand))))

#endif

#define A2_SYNTHESIZE_SINGLETON(className, methodName) \
\
+ (className *) methodName \
{ \
	static className *methodName; \
	static dispatch_once_t onceToken; \
	dispatch_once(&onceToken, ^{ \
		methodName = [[className alloc] init]; \
	}); \
\
	return methodName; \
}

NS_INLINE id A2DynamicCastSupport(Class cls, id object)
{
	NSCAssert(cls, @"Nil class");
	return [object isKindOfClass: cls] ? object : nil;
}

NS_INLINE id A2StaticCastSupport(Class cls, id object)
{
	id value = nil;
	if (object)
	{
		value = A2DynamicCastSupport(cls, object);
		NSCAssert2(value, @"Could not cast %@ to class %@", object, NSStringFromClass(cls));
	}
	
	return value;
}

#ifndef A2_STATIC_CAST
	#if DEBUG
		#define A2_STATIC_CAST(type, object) ((type *) A2StaticCastSupport([type class], object))
	#else
		#define A2_STATIC_CAST(type, object) ((type *) (object))
	#endif
#endif

#ifndef A2_DYNAMIC_CAST
	#define A2_DYNAMIC_CAST(type, object) A2DynamicCastSupport([type class], object)
#endif
