//
//  MoreScalesController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MoreScalesController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

{
    NSMutableArray *scales;
    NSMutableArray *scalesCopy;
    bool searching;
    UISearchBar * searchBar;
    NSMutableString *currentPull;
    UITableViewCell *loadingCell;
    bool loadingMore;
    bool shouldLoadMore;
    int  currentPage;
}

@property (strong, nonatomic) UITableView *scalesTable;
@property (strong, nonatomic) IBOutlet UISegmentedControl *typeControl, *directionControl;

- (void)goToDetailPageWithScale:(NSDictionary *)scale;
- (BOOL) disablesAutomaticKeyboardDismissal;
- (void) loadMorePages;

@end
