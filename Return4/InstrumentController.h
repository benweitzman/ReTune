//
//  InstrumentController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InstrumentControllerDelegate;


@interface InstrumentController : UITableViewController
{
    id<InstrumentControllerDelegate> delegate;
    NSMutableArray *instruments;
}

@property (nonatomic, strong) id<InstrumentControllerDelegate> delegate;

@end


@protocol InstrumentControllerDelegate <NSObject>

- (void)InstrumentController:(InstrumentController *)instrumentController didFinishWithSelection:(NSString*)selection;

@end