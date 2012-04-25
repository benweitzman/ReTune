//
//  LoadMidiController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadMidiControllerDelegate;

@interface LoadMidiController : UITableViewController
{
    id<LoadMidiControllerDelegate> delegate;
    NSMutableArray *midiFiles;
}

@property (nonatomic, strong) id<LoadMidiControllerDelegate> delegate;

@end

@protocol LoadMidiControllerDelegate <NSObject>

- (void)LoadMidiController:(LoadMidiController *)midiController didFinishWithSelection:(NSString*)selection;

@end
