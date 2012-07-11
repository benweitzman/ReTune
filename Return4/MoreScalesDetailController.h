//
//  MoreScalesDetailController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 7/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreScalesDetailController : UIViewController


@property (strong, nonatomic) IBOutlet UILabel *authorLabel, *scaleNameLabel;
@property (strong, nonatomic) IBOutlet UITextView *descriptionView;
@property (strong, nonatomic) NSMutableDictionary *scale;

-(IBAction)downloadScale:(id)sender; 
@end
