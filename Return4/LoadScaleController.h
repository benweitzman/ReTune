//
//  LoadScaleController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadScaleControllerDelegate;

typedef enum {
    DisplayAll,
    DisplayStandard,
    DisplayUser
} TableDisplayType;

@interface LoadScaleController : UITableViewController <UISearchBarDelegate>
{
    id<LoadScaleControllerDelegate> delegate;
    NSMutableArray *scales;
    NSMutableDictionary *scaleCats;
    NSMutableDictionary *scaleCopy;
    bool searching;
    TableDisplayType displayMode;
}

@property (nonatomic, strong) id<LoadScaleControllerDelegate> delegate;
@property (nonatomic, strong) UIButton* button;

- (IBAction)doPublish:(id)sender;

@end

@protocol LoadScaleControllerDelegate <NSObject>

- (void)LoadScaleController:(LoadScaleController *)scaleController didFinishWithSelection:(NSString*)selection;
- (void)LoadScaleController:(LoadScaleController *)scaleController didPublishAScaleWithName:(NSString *)scaleName;

@end
