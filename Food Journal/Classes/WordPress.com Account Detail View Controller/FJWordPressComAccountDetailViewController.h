//
//  FJWordPressComAccountDetailViewController.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FJWordPressComAccountDetailViewController : UITableViewController

@property (strong, nonatomic) WordPressAccount *wordPressAccount;

- (IBAction)next:(id)sender;
- (IBAction)save:(id)sender;

@end
