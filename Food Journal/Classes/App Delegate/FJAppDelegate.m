//
//  FJAppDelegate.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJAppDelegate.h"
#import "FJWordPressAPIClient.h"
#import "FJPostsViewController.h"

@implementation FJAppDelegate

#pragma mark - Application Delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Configure AZCoreRecordManager
	[AZCoreRecordManager setErrorHandler:^(NSError *error) {
		NSLog(@"Error = %@", error);
	}];
	
	AZCoreRecordManager *crm = [AZCoreRecordManager defaultManager];
	crm.stackShouldAutoMigrateStore = YES;
	
	// Configure view controllers
	UINavigationController *navigationController = A2_STATIC_CAST(UINavigationController, self.window.rootViewController);
	FJPostsViewController *controller = A2_STATIC_CAST(FJPostsViewController, navigationController.topViewController);
	controller.managedObjectContext = [NSManagedObjectContext defaultContext];
	
    return YES;
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [FJWordPressAPIClient handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}
- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}
- (void)applicationWillTerminate:(UIApplication *)application
{
	
}

@end
