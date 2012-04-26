//
//  LoadScaleController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadScaleControllerDelegate;

@interface LoadScaleController : UITableViewController
{
    id<LoadScaleControllerDelegate> delegate;
    NSMutableArray *scales;
}

@property (nonatomic, strong) id<LoadScaleControllerDelegate> delegate;

@end

@protocol LoadScaleControllerDelegate <NSObject>

- (void)LoadScaleController:(LoadScaleController *)scaleController didFinishWithSelection:(NSString*)selection;

@end
