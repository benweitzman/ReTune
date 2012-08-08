//
//  UITextViewTableViewCell.m
//  ReTune
//
//  Created by Ben Weitzman on 8/7/12.
//
//

#import "UITextViewTableViewCell.h"

@implementation UITextViewTableViewCell

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    // Set top of textLabel to top of cell
    CGRect newFrame = self.textLabel.frame;
    newFrame.origin.y = CGRectGetMinY (self.contentView.bounds);
    newFrame.size.height = 45;
    [self.textLabel setFrame:newFrame];
    
    // Set top of detailTextLabel to bottom of textLabel
    newFrame = self.detailTextLabel.frame;
    newFrame.origin.y = CGRectGetMaxY (self.textLabel.frame);
    [self.detailTextLabel setFrame:newFrame];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
