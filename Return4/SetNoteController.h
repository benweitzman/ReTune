//
//  SetNoteController.h
//  Retune4.3
//
//  Created by Ben Weitzman on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetNoteControllerDelegate;

@interface SetNoteController : UIViewController  <UIPickerViewDataSource, UIPickerViewDelegate>
{
    id<SetNoteControllerDelegate> delegate;
    int currentInterval;
    NSUserDefaults *userSettings;
    NSArray *noteNames;
}

@property (nonatomic, strong) NSNumber * frequency;
@property (nonatomic, strong) NSNumber * cents;
@property (nonatomic, strong) NSNumber * numerator, *denominator;
@property (nonatomic, strong) NSNumber * degree;
@property (nonatomic, strong) UIPopoverController *pop;
@property (nonatomic, strong) IBOutlet UISegmentedControl *intervalControl;
@property (nonatomic, strong) IBOutlet UILabel *header,*intervalField;
@property (nonatomic, strong) IBOutlet UITextField *numeratorField, *denominatorField, *centsField, *frequencyField;
@property (nonatomic, strong) IBOutlet UIButton *save, *cancel;
@property (nonatomic, strong) IBOutlet UIPickerView *intervalPicker;
@property (nonatomic, strong) id<SetNoteControllerDelegate> delegate;

-(IBAction)inputChanged:(id)sender;
-(IBAction)cancelled:(id)sender;
-(IBAction)saved:(id)sender;
-(IBAction)intervalChanged:(id)sender;
- (IBAction)textFieldDidBeginEditing:(UITextField *)textField;
- (IBAction)textFieldDidEndEditing:(UITextField *)textField;

@end

@protocol SetNoteControllerDelegate <NSObject>


-(NSString *) fractionFromFloat:(float)number;
-(NSMutableArray *)getPitches;
-(NSMutableArray *)scaleRatios;
-(float)getScaleDegree;
-(NSMutableArray *)getEqual;
- (void)SetNoteController:(SetNoteController *)setNoteController didFinishWithFrequency:(float) frequency forDegree:(int) degree;

@end
