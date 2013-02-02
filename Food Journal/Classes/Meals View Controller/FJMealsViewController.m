//
//  FJMealsViewController.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/4/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJMealDetailViewController.h"
#import "FJMealsViewController.h"
#import "FJSettingsViewController.h"
#import "FJWordPressAPIClient.h"

static void *FJMealsViewControllerPostMealsKVOContext = &FJMealsViewControllerPostMealsKVOContext;

static NSString *const FJDisplayMealDetailsSegueIdentifier = @"DisplayMealDetails";
static NSString *const FJMealCellIdentifier = @"MealCell";
static NSString *const FJShowSettingsSegueIdentifier = @"ShowSettings";

@interface FJMealsViewController ()

@property (nonatomic) BOOL shouldIgnoreKVONotifications;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addMealButtonItem;

- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation FJMealsViewController

- (BOOL)checkForAccounts
{
	if (![WordPressAccount count])
	{
		UIAlertView *alertView = [UIAlertView alertViewWithTitle:NSLocalizedString(@"No Accounts", nil) message:NSLocalizedString(@"You cannot share this post until you upload it to an account. Would you like to configure your accounts?", nil)];
		[alertView setCancelButtonWithTitle:NSLocalizedString(@"Not Now", nil) handler:nil];
		[alertView addButtonWithTitle:NSLocalizedString(@"Settings", nil) handler:^{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self performSegueWithIdentifier:FJShowSettingsSegueIdentifier sender:self];
			});
		}];
		[alertView show];
		return NO;
	}
	
	return YES;
}

- (void)dealloc
{
	self.post = nil;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == FJMealsViewControllerPostMealsKVOContext)
	{
		if (self.shouldIgnoreKVONotifications)
			return;
		
		if ([change[NSKeyValueChangeNotificationIsPriorKey] boolValue])
		{
			[self.tableView beginUpdates];
			return;
		}
		
		NSKeyValueChange changeKind;
		[change[NSKeyValueChangeKindKey] getValue:&changeKind];
		
		NSIndexSet *changedIndexes = change[NSKeyValueChangeIndexesKey];
		NSMutableArray *changedIndexPaths = [NSMutableArray arrayWithCapacity:changedIndexes.count];
		[changedIndexes each:^(NSUInteger index) {
			[changedIndexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
		}];
		
		switch (changeKind)
		{
			case NSKeyValueChangeInsertion:
				[self.tableView insertRowsAtIndexPaths:changedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
				break;
				
			case NSKeyValueChangeRemoval:
				[self.tableView deleteRowsAtIndexPaths:changedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
				break;
				
			case NSKeyValueChangeReplacement:
				[self.tableView reloadRowsAtIndexPaths:changedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
				break;
				
			case NSKeyValueChangeSetting:
				[self.tableView reloadData];
				break;
		}
		
		[self.tableView endUpdates];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}
- (void)setPost:(Post *)aPost
{
	if (_post)
	{
		[_post removeObserver:self forKeyPath:PostRelationships.meals context:FJMealsViewControllerPostMealsKVOContext];
	}
	
	_post = aPost;
	
	if (_post)
	{
		[_post addObserver:self forKeyPath:PostRelationships.meals options:NSKeyValueObservingOptionPrior context:FJMealsViewControllerPostMealsKVOContext];
		
		self.title = [NSDateFormatter localizedStringFromDate:_post.date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
		
		NSString *backTitle = [NSDateFormatter localizedStringFromDate:_post.date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
		self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:backTitle style:UIBarButtonItemStyleBordered target:nil action:NULL];
	}
}

#pragma mark - Actions

- (IBAction)closeSettings:(UIStoryboardSegue *)segue
{
	
}
- (IBAction)createMeal:(id)sender
{
	[[Meal createInContext:self.post.managedObjectContext] setPost:self.post];
	[self.post.managedObjectContext save];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.post.meals.count - 1 inSection:0];
	[self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
	
	double delayInSeconds = 0.3;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	});
}
- (IBAction)performAction:(id)sender
{
	if (![self checkForAccounts])
		return;

	BKBlock uploadHandler = ^{
		NSFetchRequest *fetchRequest = [WordPressAccount requestAllInContext:self.post.managedObjectContext];
		NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:AccountAttributes.title ascending:YES selector:@selector(localizedStandardCompare:)];
		fetchRequest.sortDescriptors = @[titleSortDescriptor];
		NSError *error;
		NSArray *accounts = [self.post.managedObjectContext executeFetchRequest:fetchRequest error:&error];
		
		NSString *title = NSLocalizedString(@"Choose an account to which to upload this post.", nil);
		UIActionSheet *actionSheet = [UIActionSheet actionSheetWithTitle:title];
		
		[accounts each:^(WordPressAccount *account) {
			[actionSheet addButtonWithTitle:account.title handler:^{
				DZProgressController *progressController = [[DZProgressController alloc] init];
				progressController.label.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
				progressController.label.text = NSLocalizedStringWithDefaultValue(@"Uploading...", nil, [NSBundle mainBundle], @"Uploading…", nil);
				[progressController show];
				
				[[FJWordPressAPIClient clientWithAccount:account] uploadPost:self.post withCompletion:^(WordPressPost *wordPressPost, NSError *error) {
					[progressController hide];
				}];
			}];
		}];
		
		[actionSheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
		[actionSheet showFromToolbar:self.navigationController.toolbar];
	};
	
	if (self.post.wordPressPosts.count)
	{
		UIActionSheet *actionSheet = [UIActionSheet actionSheetWithTitle:nil];
		[actionSheet addButtonWithTitle:NSLocalizedString(@"Upload Post", nil) handler:uploadHandler];
		[actionSheet addButtonWithTitle:NSLocalizedString(@"Share Post", nil) handler:^{
			NSSet *accountsSet = [self.post.wordPressPosts map:^id(WordPressPost *wordPressPost) {
				return wordPressPost.account;
			}];
			
			NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:AccountAttributes.title ascending:YES selector:@selector(localizedStandardCompare:)];
			NSArray *accountsArray = [accountsSet sortedArrayUsingDescriptors:@[titleSortDescriptor]];
			
			NSString *title = NSLocalizedString(@"Choose an account whose post URL to share.", nil);;
			UIActionSheet *actionSheet = [UIActionSheet actionSheetWithTitle:title];
			
			[accountsArray each:^(WordPressAccount *account) {
				[actionSheet addButtonWithTitle:account.title handler:^{
					WordPressPost *wordPressPost = [self.post.wordPressPosts match:^BOOL(WordPressPost *wordPressPost) {
						return [wordPressPost.account isEqual:account];
					}];
					
					NSString *dateString = [[FJWordPressAPIClient postTitleDateFormatter] stringFromDate:self.post.date];
					NSString *postTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ on %@", nil), dateString, account.title];
					
					UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[postTitle, [NSURL URLWithString:wordPressPost.url]] applicationActivities:nil];
					[self presentViewController:activityViewController animated:YES completion:nil];
				}];
			}];
			
			[actionSheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
			[actionSheet showFromToolbar:self.navigationController.toolbar];
		}];
		[actionSheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
		[actionSheet showFromToolbar:self.navigationController.toolbar];
	}
	else
	{
		uploadHandler();
	}
}

#pragma mark - Table View Delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.post.meals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FJMealCellIdentifier forIndexPath:indexPath];
	[self tableView:tableView configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[self.post.managedObjectContext saveDataWithBlock:^(NSManagedObjectContext *context) {
			[self.post.meals[indexPath.row] deleteInContext:context];
		}];
	}
}
- (void)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
	Meal *meal = self.post.meals[indexPath.row];
	if (meal.name.length)
	{
		cell.textLabel.text = meal.name;
	}
	else
	{
		static NSString *noName;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			noName = NSLocalizedString(@"(No Name)", nil);
		});
		
		cell.textLabel.text = noName;
	}
	
	NSMutableString *subtitle = [NSMutableString string];
	
	NSUInteger foodsCount = meal.foods.count;
	if (foodsCount)
	{
		if (foodsCount == 1)
			[subtitle appendString:NSLocalizedString(@"1 food item", nil)];
		else
			[subtitle appendFormat:NSLocalizedString(@"%d food items", nil), foodsCount];
	}
	
	NSUInteger imagesCount = meal.images.count;
	if (imagesCount)
	{
		if (subtitle.length)
			[subtitle appendString:@", "];
		
		if (imagesCount == 1)
			[subtitle appendString:NSLocalizedString(@"1 image", nil)];
		else
			[subtitle appendFormat:NSLocalizedString(@"%d images", nil), imagesCount];
	}
	
	cell.detailTextLabel.text = subtitle;
	
	if (meal.images.count)
		cell.imageView.image = [meal.images[0] smallThumbnailImage];
	else
		cell.imageView.image = nil;
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	if ([sourceIndexPath isEqual:destinationIndexPath])
		return;
	
	self.shouldIgnoreKVONotifications = YES;
	
	[self.post.mealsSet moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:sourceIndexPath.row] toIndex:destinationIndexPath.row];
	[self.post.managedObjectContext save];
	
	self.shouldIgnoreKVONotifications = NO;
}

#pragma mark - Table View Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	return proposedDestinationIndexPath;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

#pragma mark - View Lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:FJDisplayMealDetailsSegueIdentifier])
	{
		UITableViewCell *cell = A2_STATIC_CAST(UITableViewCell, sender);
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
		Meal *meal = self.post.meals[indexPath.row];
		
		FJMealDetailViewController *mealDetail = A2_STATIC_CAST(FJMealDetailViewController, segue.destinationViewController);
		mealDetail.meal = meal;
	}
	else if ([segue.identifier isEqualToString:FJShowSettingsSegueIdentifier])
	{
		UINavigationController *navigationController = A2_STATIC_CAST(UINavigationController, segue.destinationViewController);
		FJSettingsViewController *settings = A2_STATIC_CAST(FJSettingsViewController, navigationController.viewControllers[0]);
		settings.managedObjectContext = self.post.managedObjectContext;
	}
	else
	{
		[super prepareForSegue:segue sender:sender];
	}
}
- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.addMealButtonItem.title = nil;
	self.addMealButtonItem.image = [UIImage imageWithPDFNamed:@"FJGlyphishForkKnife.pdf" atHeight:FJToolbarButtonItemImageHeight];
	self.addMealButtonItem.landscapeImagePhone = [UIImage imageWithPDFNamed:@"FJGlyphishForkKnife.pdf" atHeight:FJToolbarButtonItemLandscapeImageHeight];
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.tableView reloadData];
}

@end
