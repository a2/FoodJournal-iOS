//
//  FJMealDetailViewTextFieldCell.h
//  Food Journal
//
//  Created by Alexsander Akers on 2/4/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJMealDetailViewTextFieldCell.h"

@implementation FJMealDetailViewTextFieldCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	[super setEditing:editing animated:animated];
	[self.textField resignFirstResponder];
	self.textField.enabled = !editing;
}
- (void)setTextField:(UITextField *)aTextField
{
	_textField = aTextField;
	[aTextField removeFromSuperview];
	[self.contentView addSubview:aTextField];
}
- (void)updateConstraints
{
	[super updateConstraints];
	
	[self.textField removeConstraints:self.textField.constraints];
	
	NSDictionary *views = NSDictionaryOfVariableBindings(_textField);
	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(space)-[_textField]-(space)-|" options:kNilOptions metrics:@{@"space": @11.0} views:views]];
	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_textField]|" options:kNilOptions metrics:nil views:views]];
}



@end
