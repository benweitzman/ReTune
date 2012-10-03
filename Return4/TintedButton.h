//
//  TintedButton.h
//  ReTune
//
//  Created by Ben Weitzman on 8/27/12.
//
//

#import <UIKit/UIKit.h>

@class PassthroughView;

@interface TintedButton : UIButton {
    PassthroughView *tintView;
}

@property (nonatomic, assign) UIColor *tint;

@end
