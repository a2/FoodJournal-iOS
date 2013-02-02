//
//  FJAddWordPressAccountViewController.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/3/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJAddWordPressAccountViewController.h"
#import "FJWordPressAPIClient.h"

static NSString *const FJAddWordPressComBlogSegueIdentifier = @"AddWordPressComBlog";
static NSString *const FJCloseAddAccountSegueIdentifier = @"CloseAddAccount";

@interface FJAddWordPressAccountViewController ()

@end

@implementation FJAddWordPressAccountViewController

#pragma mark - Notification Center Observation

- (void) wordPressAPIDidAuthenticateWithSSO:(NSNotification *)note
{
	NSDictionary *userInfo = note.userInfo;
	NSURL *blogUrl = userInfo[FJWordPressAPIBlogURLUserInfoKey];
	NSString *token = userInfo[FJWordPressAPITokenUserInfoKey];
	
	[WordPressAccount validateAndCreateAccountWithURL:blogUrl token:token completion:^(WordPressAccount *account) {
		if (account)
			[self performSegueWithIdentifier:FJCloseAddAccountSegueIdentifier sender:self];
	}];
}
- (void) wordPressAPIDidFailToAuthenticateWithSSO:(NSNotification *)note
{
	[self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 0:
			switch (indexPath.row)
			{
				case 1:
#error Fill in WordPress.com API credentials
					if ([FJWordPressAPIClient isSSOAvailable])
						[FJWordPressAPIClient authenticateWithClientID:nil secret:nil redirectURI:@"http://pandamonia.us/" callback:@"x-pandamonia-foodjournal"];
					else
						[self performSegueWithIdentifier:FJAddWordPressComBlogSegueIdentifier sender:[tableView cellForRowAtIndexPath:indexPath]];
					break;
					
				default:
					break;
			}
			break;
			
		case 1:
			[UIApp openURL:[NSURL URLWithString:@"http://wordpress.com/signup"]];
			[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
			break;
			
		default:
			break;
	}
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordPressAPIDidAuthenticateWithSSO:) name:FJWordPressAPIDidAuthenticateWithSSONotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordPressAPIDidFailToAuthenticateWithSSO:) name:FJWordPressAPIDidFailToAuthenticateWithSSONotification object:nil];
}

@end
