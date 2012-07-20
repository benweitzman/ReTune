//
//  InfoController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InfoController : UIViewController
{
    NSUserDefaults *userSettings;
}

@property(nonatomic, strong) IBOutlet UISlider *rangeSlider;
@property(nonatomic, strong) IBOutlet UILabel *rangeLabel;

- (IBAction) backButtonClick:(id) sender;
- (void)rangeChanged:(id)sender;

@end
