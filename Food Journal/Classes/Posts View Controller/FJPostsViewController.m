//
//  FJPostsViewController.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/3/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJMealsViewController.h"
#import "FJPostsViewController.h"
#import "FJSettingsViewController.h"
#import "FJWordPressAPIClient.h"

static NSString *const FJPostCellIdentifier = @"PostCell";
static NSString *const FJShowMealsForPostSegueIdentifier = @"ShowMealsForPost";
static NSString *const FJShowSettingsSegueIdentifier = @"ShowSettings";

@interface FJPostsViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation FJPostsViewController

- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController)
		return _fetchedResultsController;
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[Post entityName]];
	
	// Set the batch size to a suitable number.
	fetchRequest.fetchBatchSize = 20;
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc] initWithKey:PostAttributes.date ascending:NO];
	[fetchRequest setSortDescriptors:@[dateSortDescriptor]];
	
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Posts"];
	aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;
	
	[aFetchedResultsController performFetch];
	
	return _fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)closeSettings:(UIStoryboardSegue *)segue
{
	
}
- (IBAction)createPost:(id)sender
{
	NSDate *now = [NSDate date];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%@ <= %K AND %K <= %@", now.dateByMovingToBeginningOfDay, PostAttributes.date, PostAttributes.date, now.dateByMovingToEndOfDay];
	
	Post *existingPost = [Post findFirstWithPredicate:predicate inContext:self.managedObjectContext];
	NSIndexPath *indexPath;
	
	if (existingPost)
	{
		indexPath = [self.fetchedResultsController indexPathForObject:existingPost];
	}
	else
	{
		[self.managedObjectContext saveDataWithBlock:^(NSManagedObjectContext *context) {
			Post *post = [Post createInContext:context];
			post.date = now;
		}];
		
		indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	}
	
	[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
	
	double delayInSeconds = 0.3;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	});
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

#pragma mark - Table View Data Source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return NO if you do not want the specified item to be editable.
	return YES;
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	// The table view should not be re-orderable.
	return NO;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return self.fetchedResultsController.sections.count;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
	return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FJPostCellIdentifier forIndexPath:indexPath];
	[self tableView:tableView configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
	cell.textLabel.text = [NSDateFormatter localizedStringFromDate:post.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
	
	NSUInteger mealsCount = post.meals.count;
	if (mealsCount == 1)
		cell.detailTextLabel.text = NSLocalizedString(@"1 meal", nil);
	else
		cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d meals", nil), mealsCount];
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self.fetchedResultsController.managedObjectContext saveDataWithBlock:^(NSManagedObjectContext *context) {
			[[self.fetchedResultsController objectAtIndexPath:indexPath] deleteInContext:context];
		}];
	}
}

#pragma mark - Table View Delegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

#pragma mark - View Lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:FJShowSettingsSegueIdentifier])
	{
		UINavigationController *navigationController = A2_STATIC_CAST(UINavigationController, segue.destinationViewController);
		FJSettingsViewController *settings = A2_STATIC_CAST(FJSettingsViewController, navigationController.viewControllers[0]);
		settings.managedObjectContext = self.managedObjectContext;
	}
	else if ([segue.identifier isEqualToString:FJShowMealsForPostSegueIdentifier])
	{
		UITableViewCell *cell = A2_STATIC_CAST(UITableViewCell, sender);
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
		Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
		
		FJMealsViewController *meals = A2_STATIC_CAST(FJMealsViewController, segue.destinationViewController);
		meals.post = post;
	}
	else
	{
		[super prepareForSegue:segue sender:sender];
	}
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.navigationItem.leftBarButtonItem.title = nil;
	self.navigationItem.leftBarButtonItem.image = [UIImage imageWithPDFNamed:@"FJGlyphishSettings.pdf" atHeight:FJNavigationBarButtonItemImageHeight];
	self.navigationItem.leftBarButtonItem.landscapeImagePhone = [UIImage imageWithPDFNamed:@"FJGlyphishSettings.pdf" atHeight:FJNavigationBarButtonItemLandscapeImageHeight];

}

@end
