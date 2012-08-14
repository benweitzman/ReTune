//
//  InfoController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomScroller :UIScrollView
@end

@interface InfoController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSUserDefaults *userSettings;
    NSDictionary *instrumentList;
    NSIndexPath *checkedPath;
    int currentPage;
    bool tabBarSelect;
}

@property(nonatomic, strong) IBOutlet UISlider *rangeSlider, *hertzSlider;
@property(nonatomic, strong) IBOutlet UILabel *rangeLabel, *hertzLabel;
@property(nonatomic, strong) IBOutlet UISegmentedControl *methodControl;
@property(nonatomic, strong) IBOutlet UITableView *instrumentsTable;
@property (strong, nonatomic) IBOutlet CustomScroller *pageScroller;
@property (strong, nonatomic) IBOutlet UITabBar *tabBar;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *subViews;

- (IBAction) backButtonClick:(id) sender;
- (void)rangeChanged:(id)sender;
- (void)methodChanged:(id)sender;
- (void)hertzChanged:(id)sender;

@end
