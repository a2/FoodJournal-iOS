//
//  FJAddAccountViewController.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJAddAccountViewController.h"

@interface FJAddAccountViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *wordPressLogoImageView;

@end

@implementation FJAddAccountViewController

#pragma mark - Table View Data Source

#pragma mark - Table view Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.wordPressLogoImageView.highlightedImage = [UIImage imageWithPDFNamed:@"FJWordPressLogoHighlighted.pdf" atHeight:66.0];
	self.wordPressLogoImageView.image = [UIImage imageWithPDFNamed:@"FJWordPressLogo.pdf" atHeight:66.0];
}

@end
