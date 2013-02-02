//
//  FJMealDetailViewController.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/4/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJMealDetailViewController.h"
#import "FJMealDetailViewImageCell.h"
#import "FJMealDetailViewTextFieldCell.h"

typedef NS_ENUM(NSInteger, FJMealDetailViewSection)
{
	FJMealDetailViewSectionName,
	FJMealDetailViewSectionImages,
	FJMealDetailViewSectionFoods,
	FJMealDetailViewSectionCount
};

static NSString *FJImageCellIdentifier = @"ImageCell";
static NSString *FJNoFoodCellIdentifier = @"NoFoodCell";
static NSString *FJNoImageCellIdentifier = @"NoImageCell";
static NSString *FJTextFieldCellIdentifier = @"TextFieldCell";

#import "FJWordPressAPIClient.h"

@interface FJMealDetailViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addFoodButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addImageButtonItem;

@end

@implementation FJMealDetailViewController

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
	imagePicker.sourceType = sourceType;
	
	[self presentViewController:imagePicker animated:YES completion:NULL];
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[self.navigationItem setHidesBackButton:editing animated:YES];
	[self.navigationController setToolbarHidden:editing animated:YES];
}
- (void)setRightBarButtonItemShowsContinue:(UITextField *)textField
{
	if (textField)
	{
		UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Continue", nil) style:UIBarButtonItemStyleDone target:textField action:@selector(resignFirstResponder)];
		[self.navigationItem setRightBarButtonItem:item animated:YES];
	}
	else
	{
		[self.navigationItem setRightBarButtonItem:self.editButtonItem animated:YES];
	}
}

#pragma mark - Actions

- (IBAction)createFood:(id)sender
{
	[self.tableView beginUpdates];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.meal.foods.count inSection:FJMealDetailViewSectionFoods];
	[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	if (!self.meal.foods.count)
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:FJMealDetailViewSectionFoods]] withRowAnimation:UITableViewRowAnimationAutomatic];
	
	[[Food createInContext:self.meal.managedObjectContext] setMeal:self.meal];
	[self.meal.managedObjectContext save];
	
	[self.tableView endUpdates];
	
	[self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];

	FJMealDetailViewTextFieldCell *cell = A2_STATIC_CAST(FJMealDetailViewTextFieldCell, [self.tableView cellForRowAtIndexPath:indexPath]);
	[cell.textField becomeFirstResponder];
}
- (IBAction)createImage:(id)sender
{
	BOOL canTakePictures = [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera];
	BKBlock takePicture = ^{
		[self presentImagePickerWithSourceType: UIImagePickerControllerSourceTypeCamera];
	};
	
	BOOL canSelectPictures = [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary];
	BKBlock selectPicture = ^{
		[self presentImagePickerWithSourceType: UIImagePickerControllerSourceTypePhotoLibrary];
	};
	
	if (canTakePictures && canSelectPictures)
	{
		UIActionSheet *actionSheet = [UIActionSheet actionSheetWithTitle: nil];
		
		if (canTakePictures) [actionSheet addButtonWithTitle: NSLocalizedString(@"Take Photo", @"Button text") handler: takePicture];
		if (canSelectPictures) [actionSheet addButtonWithTitle: NSLocalizedString(@"Choose Photo", @"Button text") handler: selectPicture];
		
		[actionSheet setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) handler:nil];
		[actionSheet showFromBarButtonItem:sender animated:YES];
	}
	else if (canTakePictures)
		takePicture();
	else if (canSelectPictures)
		selectPicture();
}

#pragma mark - Image Picker Controller

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self.tableView beginUpdates];
	
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.meal.images.count inSection:FJMealDetailViewSectionImages]] withRowAnimation:UITableViewRowAnimationAutomatic];
	if (!self.meal.images.count)
		[self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:FJMealDetailViewSectionImages]] withRowAnimation:UITableViewRowAnimationAutomatic];
	
	UIImage *originalImage = info[UIImagePickerControllerOriginalImage];;
	[self.meal.managedObjectContext saveDataInBackgroundWithBlock:^(NSManagedObjectContext *context) {
		Image *image = [Image createInContext:context];
		image.meal = [self.meal inContext:context];
		image.image = originalImage;
	} completion:^{
		[self.tableView endUpdates];
	}];
	
	if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
		UIImageWriteToSavedPhotosAlbum(originalImage, nil, NULL, NULL);
}

#pragma mark - Table View Data Source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case FJMealDetailViewSectionName:
			return NO;
			break;
			
		case FJMealDetailViewSectionImages:
			return self.meal.images.count > 0;
			break;
			
		case FJMealDetailViewSectionFoods:
			return self.meal.foods.count > 0;
			break;
			
		default:
			return NO;
			break;
	}
}
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case FJMealDetailViewSectionName:
			return NO;
			break;
			
		case FJMealDetailViewSectionImages:
			return self.meal.images.count > 0;
			break;
			
		case FJMealDetailViewSectionFoods:
			return self.meal.foods.count > 0;
			break;
			
		default:
			return NO;
			break;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return FJMealDetailViewSectionCount;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section)
	{
		case FJMealDetailViewSectionName:
			return 1;
			break;
			
		case FJMealDetailViewSectionImages:
			return MAX(1, self.meal.images.count);
			break;
			
		case FJMealDetailViewSectionFoods:
			return MAX(1, self.meal.foods.count);
			break;
			
		default:
			return -1;
			break;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case FJMealDetailViewSectionName:
		{
			FJMealDetailViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:FJTextFieldCellIdentifier forIndexPath:indexPath];
			cell.textField.delegate = self;
			cell.textField.placeholder = NSLocalizedString(@"(No Name)", nil);
			cell.textField.text = self.meal.name;
			return cell;
			break;
		}
			
		case FJMealDetailViewSectionImages:
			if (self.meal.images.count)
			{
				Image *image = self.meal.images[indexPath.row];
				FJMealDetailViewImageCell *cell = [tableView dequeueReusableCellWithIdentifier:FJImageCellIdentifier forIndexPath:indexPath];
				cell.foodImageView.image = image.largeThumbnailImage;
				return cell;
			}
			else
			{
				return [tableView dequeueReusableCellWithIdentifier:FJNoImageCellIdentifier forIndexPath:indexPath];
			}
			break;
			
		case FJMealDetailViewSectionFoods:
			if (self.meal.foods.count)
			{
				Food *food = self.meal.foods[indexPath.row];
				FJMealDetailViewTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:FJTextFieldCellIdentifier forIndexPath:indexPath];
				cell.textField.delegate = self;
				cell.textField.placeholder = NSLocalizedString(@"Food", nil);
				cell.textField.text = food.name;
				return cell;
			}
			else
			{
				return [tableView dequeueReusableCellWithIdentifier:FJNoFoodCellIdentifier forIndexPath:indexPath];
			}
			break;
			
		default:
			return nil;
			break;
	}
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (editingStyle) {
		case UITableViewCellEditingStyleInsert:
			switch (indexPath.section)
			{
				case FJMealDetailViewSectionImages:
					[self createImage:[tableView cellForRowAtIndexPath:indexPath]];
					break;
					
				case FJMealDetailViewSectionFoods:
					[self createFood:[tableView cellForRowAtIndexPath:indexPath]];
					break;
					
				default:
					break;
			}
			break;
			
		case UITableViewCellEditingStyleDelete:
			[self.tableView beginUpdates];
			
			switch (indexPath.section)
			{
				case FJMealDetailViewSectionImages:
					[self.meal.images[indexPath.row] delete];
					break;
					
				case FJMealDetailViewSectionFoods:
					[self.meal.foods[indexPath.row] delete];
					break;
					
				default:
					break;
			}
			[self.meal.managedObjectContext save];
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			if ((indexPath.section == FJMealDetailViewSectionImages && !self.meal.images.count) || (indexPath.section == FJMealDetailViewSectionFoods && !self.meal.foods.count))
				[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
			
			[self.tableView endUpdates];
			break;
			
		default:
			break;
	}
}
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSParameterAssert(sourceIndexPath.section == destinationIndexPath.section);
	
	NSMutableOrderedSet *objects;
	if (sourceIndexPath.section == FJMealDetailViewSectionImages)
		objects = self.meal.imagesSet;
	else if (sourceIndexPath.section == FJMealDetailViewSectionFoods)
		objects = self.meal.foodsSet;

	[objects moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:sourceIndexPath.row] toIndex:destinationIndexPath.row];
	[self.meal.managedObjectContext save];
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == FJMealDetailViewSectionImages && self.meal.images.count)
		return 160.0;
	else
		return tableView.rowHeight;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (proposedDestinationIndexPath.section < sourceIndexPath.section)
	{
		return [NSIndexPath indexPathForRow:0 inSection:sourceIndexPath.section];
	}
	else if (proposedDestinationIndexPath.section > sourceIndexPath.section)
	{
		return [NSIndexPath indexPathForRow:[tableView numberOfRowsInSection:sourceIndexPath.section] - 1 inSection:sourceIndexPath.section];
	}
	
	return proposedDestinationIndexPath;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case FJMealDetailViewSectionName:
			return NSLocalizedString(@"Meal Name", nil);
			break;
			
		case FJMealDetailViewSectionImages:
			return NSLocalizedString(@"Images", nil);
			break;
			
		case FJMealDetailViewSectionFoods:
			return NSLocalizedString(@"Food", nil);
			break;
			
		default:
			return nil;
			break;
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case FJMealDetailViewSectionImages:
			if (self.meal.images.count)
				return UITableViewCellEditingStyleDelete;
			break;
			
		case FJMealDetailViewSectionFoods:
			if (self.meal.foods.count)
				return UITableViewCellEditingStyleDelete;
			break;
			
		default:
			break;
	}
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if ([cell respondsToSelector:@selector(textField)])
		[[(FJMealDetailViewTextFieldCell *)cell textField] becomeFirstResponder];
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	UITableViewCell *cell;
	for (UIView *view = textField; cell == nil && view != nil; view = view.superview)
		if ([view isKindOfClass:[UITableViewCell class]])
			cell = A2_STATIC_CAST(UITableViewCell, view);
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	NSIndexPath *nextIndexPath;
	
	if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:0]])
	{
		if (!self.meal.foods.count)
		{
			[textField resignFirstResponder];
			return YES;
		}
		
		nextIndexPath = [NSIndexPath indexPathForRow:0 inSection:FJMealDetailViewSectionFoods];
	}
	else
	{
		nextIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:FJMealDetailViewSectionFoods];
	}
	
	if ([self.tableView numberOfRowsInSection:nextIndexPath.section] <= nextIndexPath.row)
	{
		if (textField.text.length)
			[self createFood:cell];
		return YES;
	}
	
	[self.tableView scrollToRowAtIndexPath:nextIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
	
	UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
	if ([nextCell isKindOfClass:[FJMealDetailViewTextFieldCell class]])
		[A2_STATIC_CAST(FJMealDetailViewTextFieldCell, nextCell).textField becomeFirstResponder];
	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(setRightBarButtonItemShowsContinue:) withObject:textField afterDelay:0.1];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[self performSelector:@selector(setRightBarButtonItemShowsContinue:) withObject:nil afterDelay:0.1];
	
	UITableViewCell *cell;
	for (UIView *view = textField; cell == nil && view != nil; view = view.superview)
		if ([view isKindOfClass:[UITableViewCell class]])
			cell = A2_STATIC_CAST(UITableViewCell, view);
	
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
	if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:FJMealDetailViewSectionName]])
	{
		if (textField.text.length)
			self.meal.name = textField.text;
		else
			self.meal.name = nil;
		[self.meal.managedObjectContext save];
	}
	else if (indexPath.section == FJMealDetailViewSectionFoods)
	{
		Food *food = self.meal.foods[indexPath.row];
		if (textField.text.length)
		{
			food.name = textField.text;
			[self.meal.managedObjectContext save];
		}
		else
		{
			[self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
		}
	}
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.addFoodButtonItem.title = nil;
	self.addFoodButtonItem.image = [UIImage imageWithPDFNamed:@"FJGlyphishFood.pdf" atHeight:FJToolbarButtonItemImageHeight];
	self.addFoodButtonItem.landscapeImagePhone = [UIImage imageWithPDFNamed:@"FJGlyphishFood.pdf" atHeight:FJToolbarButtonItemLandscapeImageHeight];

	self.addImageButtonItem.title = nil;
	self.addImageButtonItem.image = [UIImage imageWithPDFNamed:@"FJGlyphishPicture.pdf" atHeight:FJToolbarButtonItemImageHeight];
	self.addImageButtonItem.landscapeImagePhone = [UIImage imageWithPDFNamed:@"FJGlyphishPicture.pdf" atHeight:FJToolbarButtonItemLandscapeImageHeight];
}
- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.navigationController setToolbarHidden:NO animated:YES];
}

@end
