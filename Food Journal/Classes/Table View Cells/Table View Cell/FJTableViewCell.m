//
//  FJTableViewCell.m
//  Food Journal
//
//  Created by Alexsander Akers on 2/4/13.
//  Copyright (c) 2013 Pandamonia LLC. All rights reserved.
//

#import "FJTableViewCell.h"

@implementation FJTableViewCell

- (void)awakeFromNib
{
	[self.constraints.copy each:^(NSLayoutConstraint *constraint) {
		[self removeConstraint:constraint];
		
		id firstItem = [constraint.firstItem isEqual:self] ? self.contentView : constraint.firstItem;
		id secondItem = [constraint.secondItem isEqual:self] ? self.contentView : constraint.secondItem;
		NSLayoutConstraint *newConstraint = [NSLayoutConstraint constraintWithItem:firstItem attribute:constraint.firstAttribute relatedBy:constraint.relation toItem:secondItem attribute:constraint.secondAttribute multiplier:constraint.multiplier constant:constraint.constant];
		
		[self addConstraint:newConstraint];
	}];
}

@end
