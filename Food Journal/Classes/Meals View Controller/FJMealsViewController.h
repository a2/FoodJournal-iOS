//
//  FJMealsViewController.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/4/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJMealsViewController : UITableViewController

@property (strong, nonatomic) Post *post;

- (IBAction)closeSettings:(UIStoryboardSegue *)segue;
- (IBAction)createMeal:(id)sender;
- (IBAction)performAction:(id)sender;

@end
