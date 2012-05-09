//
//  SetNoteController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetNoteControllerDelegate;

@interface SetNoteController : UIViewController 
{
    id<SetNoteControllerDelegate> delegate;
}

@property (nonatomic, strong) NSNumber * frequency;
@property (nonatomic, strong) NSNumber * cents;
@property (nonatomic, strong) NSNumber * numerator, *denominator;
@property (nonatomic, strong) NSNumber * degree;
@property (nonatomic, strong) UIPopoverController *pop;
@property (nonatomic, strong) IBOutlet UILabel *header;
@property (nonatomic, strong) IBOutlet UITextField *numeratorField, *denominatorField, *centsField, *frequencyField ;
@property (nonatomic, strong) id<SetNoteControllerDelegate> delegate;

-(IBAction)inputChanged:(id)sender;
-(IBAction)cancelled:(id)sender;

@end

@protocol SetNoteControllerDelegate <NSObject>

-(NSMutableArray *)getPitches;
-(float)getScaleDegree;
-(NSMutableArray *)getEqual;
- (void)SetNoteController:(SetNoteController *)setNoteController didFinishWithFrequency:(float) frequency forDegree:(int) degree;

@end
