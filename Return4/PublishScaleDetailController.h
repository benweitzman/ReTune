//
//  PublishScaleDetailController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"
#import "RegisterViewController.h"

@interface PublishScaleDetailController : UITableViewController <UITextFieldDelegate>
{
    NSString* authorName;
    NSString* description;
    
    UITextField* scaleNameField;
    UITextField* authorNameField;
    UIPlaceHolderTextView* descriptionField;
    UITableViewCell *authorCell;
}

@property (strong) NSArray *scaleToSend;
@property (strong) NSString* scaleName;  

- (NSString *) sha1:(NSString *)input;
@end
