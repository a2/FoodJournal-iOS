//
//  FJSettingsViewController.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/2/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJSelfHostedWordPressAccountDetailViewController.h"
#import "FJSettingsViewController.h"
#import "FJWordPressComAccountDetailViewController.h"

static NSString *const FJAccountCellIdentifier = @"AccountCell";
static NSString *const FJAddAccountCellIdentifier = @"AddAccountCell";
static NSString *const FJAddAccountSegueIdentifier = @"AddAccount";
static NSString *const FJEditWordPressComAccountDetailsSegueIdentifier = @"EditWordPressComAccountDetails";
static NSString *const FJEditSelfHostedWordPressAccountDetailsSegueIdentifier = @"EditSelfHostedWordPressAccountDetails";

@interface FJSettingsViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation FJSettingsViewController

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[Account entityName]];
	
	// Set the batch size to a suitable number.
	fetchRequest.fetchBatchSize = 20;
	
	// Set the sort descriptors
	NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:AccountAttributes.title ascending:YES selector:@selector(localizedStandardCompare:)];
	fetchRequest.sortDescriptors = @[titleSortDescriptor];
	
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Accounts"];
	aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	[aFetchedResultsController performFetch];
	
	return _fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)closeAddAccount:(UIStoryboardSegue *)segue
{
	
}

#pragma mark - Table View Data Source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return NO if you do not want the specified item to be editable.
	return NO;
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	// The table view should not be re-orderable.
	return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
		{
			id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
			return sectionInfo.numberOfObjects + 1;
			break;
		}
			
		default:
			return -1;
			break;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return NSLocalizedString(@"Accounts", nil);
			break;
			
		default:
			return nil;
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 0:
			if (indexPath.row < self.fetchedResultsController.fetchedObjects.count)
			{
				UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FJAccountCellIdentifier forIndexPath:indexPath];
				[self tableView:tableView configureCell:cell atIndexPath:indexPath];
				return cell;
			}
			else
			{
				return [tableView dequeueReusableCellWithIdentifier:FJAddAccountCellIdentifier forIndexPath:indexPath];
			}
			break;
			
		default:
			break;
	}
	
	return nil;
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	Account *account = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = account.title;
	cell.detailTextLabel.text = account.url;
	
	if ([[account.class entityName] isEqualToString: [WordPressAccount entityName]])
	{
		CGFloat height = (3./4.) * tableView.rowHeight;
		cell.imageView.highlightedImage = [UIImage imageWithPDFNamed:@"FJWordPressLogoNoTextHighlighted.pdf" atHeight:height];
		cell.imageView.image = [UIImage imageWithPDFNamed:@"FJWordPressLogoNoText.pdf" atHeight:height];
	}
	else
	{
		cell.imageView.highlightedImage = nil;
		cell.imageView.image = nil;
	}
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 0:
			if (indexPath.row < self.fetchedResultsController.fetchedObjects.count)
				return 66.0;
			else
				return tableView.rowHeight;
			break;
			
		default:
			return tableView.rowHeight;
			break;
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 0:
			if (indexPath.row < self.fetchedResultsController.fetchedObjects.count)
				return UITableViewCellEditingStyleDelete;
			else
				return UITableViewCellEditingStyleInsert;
			break;
			
		default:
			return UITableViewCellEditingStyleNone;
			break;
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row >= self.fetchedResultsController.fetchedObjects.count)
		return;
	
	Account *account = [self.fetchedResultsController objectAtIndexPath:indexPath];
	NSEntityDescription *wordPressAccountEntity = [WordPressAccount entityDescriptionInContext:self.managedObjectContext];
	if ([account.entity isKindOfEntity:wordPressAccountEntity])
	{
		NSURL *url = [NSURL URLWithString:account.url];
		if ([url.host hasSuffix:@".wordpress.com"])
			[self performSegueWithIdentifier:FJEditWordPressComAccountDetailsSegueIdentifier sender:[tableView cellForRowAtIndexPath:indexPath] context:account];
		else
			[self performSegueWithIdentifier:FJEditSelfHostedWordPressAccountDetailsSegueIdentifier sender:[tableView cellForRowAtIndexPath:indexPath] context:account];
	}
}

#pragma mark - Fetched Results Controller Delegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
}
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	switch (type)
	{
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
	switch (type)
	{
		case NSFetchedResultsChangeInsert:
			[self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeDelete:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
			
		case NSFetchedResultsChangeUpdate:
			[self tableView:self.tableView configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			break;
			
		case NSFetchedResultsChangeMove:
			[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView beginUpdates];
}

#pragma mark - View Lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:FJEditWordPressComAccountDetailsSegueIdentifier])
	{
		FJWordPressComAccountDetailViewController *accountDetail = A2_STATIC_CAST(FJWordPressComAccountDetailViewController, segue.destinationViewController);
		accountDetail.wordPressAccount = A2_STATIC_CAST(WordPressAccount, segue.context);
	}
	else if ([segue.identifier isEqualToString:FJEditSelfHostedWordPressAccountDetailsSegueIdentifier])
	{
		FJSelfHostedWordPressAccountDetailViewController *accountDetail = A2_STATIC_CAST(FJSelfHostedWordPressAccountDetailViewController, segue.destinationViewController);
		accountDetail.wordPressAccount = A2_STATIC_CAST(WordPressAccount, segue.context);
	}
	else
	{
		[super prepareForSegue:segue sender:sender];
	}
}

@end
