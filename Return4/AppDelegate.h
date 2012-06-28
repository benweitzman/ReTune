//
//  AppDelegate.h
//  Return4
//
//  Created by Ben Weitzman on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PGMidi.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    PGMidi                    *midi;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;


@end
