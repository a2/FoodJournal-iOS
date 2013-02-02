//
//  FJPostsViewController.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/3/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJPostsViewController : UITableViewController

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)closeSettings:(UIStoryboardSegue *)segue;
- (IBAction)createPost:(id)sender;

@end
