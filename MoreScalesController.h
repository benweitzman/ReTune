//
//  MoreScalesController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreScalesController : UIViewController <UITableViewDataSource, UITableViewDelegate>

{
    NSMutableArray *scales;
}

@property (strong, nonatomic) UITableView *scalesTable;

@end
