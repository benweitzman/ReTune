//
//  TintedButton.m
//  ReTune
//
//  Created by Ben Weitzman on 8/27/12.
//
//

#import "TintedButton.h"
#import <QuartzCore/QuartzCore.h>

@interface PassthroughView : UIView
@end

@implementation PassthroughView
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return NO;
}
@end

@implementation TintedButton
@synthesize tintColor;

-(void)setup {
    tintView = [[PassthroughView alloc] initWithFrame:[self bounds]];
    [self addSubview:tintView];
    [[self titleLabel] removeFromSuperview];
    [tintView addSubview:[self titleLabel]];
    [tintView setBackgroundColor:[UIColor clearColor]];
    [self setTintColor:[UIColor clearColor]];
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [self setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [self setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [self.layer setCornerRadius:5.0f];
    [self.layer setMasksToBounds:YES];
}

-(id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

-(void) setTintColor:(UIColor *)_tintColor {
    tintColor = _tintColor;
    [tintView setBackgroundColor:_tintColor];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
