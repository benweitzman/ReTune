//
//  SetNoteController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SetNoteController.h"

@implementation SetNoteController

@synthesize header, delegate, degree, frequency, cents, numerator, denominator;
@synthesize numeratorField, denominatorField, centsField, frequencyField, pop;
@synthesize intervalControl, intervalField;
@synthesize save, cancel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    userSettings = [NSUserDefaults standardUserDefaults];
    CGSize size = CGSizeMake(446, 350); // size of view in popover
    self.contentSizeForViewInPopover = size;

    self.view.backgroundColor = [UIColor colorWithPatternImage: [UIImage imageNamed:@"diamond_upholstery.png"]];
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                           resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageDisabled = [[UIImage imageNamed:@"orangeButton.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    [save setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [save setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [save setBackgroundImage:buttonImageDisabled forState:UIControlStateDisabled];
    [cancel setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [cancel setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    cancel.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];      
    save.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];
    [intervalControl addTarget:self action:@selector(intervalChanged:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    //NSLog(@" %d",[degree intValue]);
    NSLog(@"%@",degree);
    noteNames = [[NSArray alloc] initWithObjects:@"C",@"C♯",@"D",@"E♭",@"E",@"F",@"F♯",@"G",@"A♭",@"A",@"B♭",@"B", nil];
    NSLog(@"note: %@",[noteNames objectAtIndex:[degree intValue]]);
    [intervalControl setEnabled:NO forSegmentAtIndex:[degree intValue]];
    [intervalControl setSelectedSegmentIndex:[delegate getScaleDegree]];
    currentInterval = 0;
    [intervalField setText:[NSString stringWithFormat:@"Ratio to %@ in the key of %@",[intervalControl titleForSegmentAtIndex:intervalControl.selectedSegmentIndex],[noteNames objectAtIndex:[delegate getScaleDegree]]]];
    [header setText:[NSString stringWithFormat:@"Changing note: %@",[noteNames objectAtIndex:[degree intValue]]]];
    [numeratorField setText:[NSString stringWithFormat:@"%d",[numerator intValue]]];
    [denominatorField setText:[NSString stringWithFormat:@"%d",[denominator intValue]]];
    [centsField setText:[NSString stringWithFormat:@"%.1f",[cents floatValue]]];
    [frequencyField setText:[NSString stringWithFormat:@"%.2f",[frequency floatValue]]];
    [super viewWillAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (BOOL) textIsValidFloat:(NSString* )text {
   // return [text isMatchedByRegex:@"^(?:|0|[1-9]\\d*)(?:\\.\\d*)?$"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^-?\\d+(\\.\\d+)?$" options:0 error:NULL];
    NSString *str = text;
    //NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) textIsValidInt:(NSString* )text {
    // return [text isMatchedByRegex:@"^(?:|0|[1-9]\\d*)(?:\\.\\d*)?$"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+$" options:0 error:NULL];
    NSString *str = text;
    //NSTextCheckingResult *match = [regex firstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
    if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
        return YES;
    } else {
        return NO;
    }
}


-(IBAction)inputChanged:(id)sender {
    UITextField *field = sender;
    if (field == numeratorField || field == denominatorField) {
        if ([self textIsValidInt:[field text]] && [field.text floatValue] != 0) {
            [field setTextColor:[UIColor blackColor]];
            float intervalRatio = [numeratorField.text floatValue]/[denominatorField.text floatValue];
            float ratio = intervalRatio*[[[delegate scaleRatios] objectAtIndex:(int)(intervalControl.selectedSegmentIndex-[delegate getScaleDegree]+12)%12] floatValue];
            float freq = ratio*[[[delegate getPitches] objectAtIndex:[delegate getScaleDegree]+60] floatValue];
            [frequencyField setText:[NSString stringWithFormat:@"%.2f",freq]];
            ratio = freq/[[[delegate getEqual] objectAtIndex:([degree floatValue]+60)] floatValue];
            float tcents = 1200*log2(ratio);
            [centsField setText:[NSString stringWithFormat:@"%.1f",tcents]];
        } else {
            [field setTextColor:[UIColor redColor]];
        }
    } else if (field == centsField) {
        if ([self textIsValidFloat:[field text]]) {
            [field setTextColor:[UIColor blackColor]];
            float tcents = [field.text floatValue];
            float ratio = powf(2.0f,tcents/1200.0);
            NSLog(@"ratio %f",ratio);
            float freq = ratio*[[[delegate getEqual] objectAtIndex:[degree floatValue]+60] floatValue];
            [frequencyField setText:[NSString stringWithFormat:@"%.2f",freq]];
            float tonicRatio = freq/[[[delegate getPitches] objectAtIndex:60+[delegate getScaleDegree]]floatValue];
            //float noteRatio = ratio;
            if (tonicRatio < 1) {
                tonicRatio *= 2;
            }
            float noteRatio = tonicRatio/[[[delegate scaleRatios] objectAtIndex:intervalControl.selectedSegmentIndex] floatValue];
            NSLog(@"note ratio: %f",noteRatio);
            NSString *ratioString = [delegate fractionFromFloat:noteRatio];
            NSArray *parts = [ratioString componentsSeparatedByString:@"/"];
            if ([parts count] == 2) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [numeratorField setText: [NSString stringWithFormat:@"%d",[[f numberFromString:[parts objectAtIndex:0]] intValue]]];
            [denominatorField setText:[NSString stringWithFormat:@"%d", [[f numberFromString:[parts objectAtIndex:1]] intValue]]];
            }
        } else {
            [field setTextColor:[UIColor redColor]];
        }
    } else if (field == frequencyField) {
        if ([self textIsValidFloat:[field text]]) {
            [field setTextColor:[UIColor blackColor]];
            float freq = [field.text floatValue];
            float centsRatio = freq/[[[delegate getEqual] objectAtIndex:[degree intValue]+60] floatValue];
            float tcents = log2f(centsRatio)*1200;
            [centsField setText:[NSString stringWithFormat:@"%.1f",tcents]];
            float tonicRatio = freq/[[[delegate getPitches] objectAtIndex:60+[delegate getScaleDegree]] floatValue];
            //float noteRatio = ratio;
            if (tonicRatio < 1) {
                tonicRatio *= 2;
            }
            float noteRatio = tonicRatio/[[[delegate scaleRatios] objectAtIndex:intervalControl.selectedSegmentIndex] floatValue];
            NSLog(@"note ratio: %f",noteRatio);
            NSString *ratioString = [delegate fractionFromFloat:noteRatio];
            NSArray *parts = [ratioString componentsSeparatedByString:@"/"];
            if ([parts count] == 2) {
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            [numeratorField setText: [NSString stringWithFormat:@"%d",[[f numberFromString:[parts objectAtIndex:0]] intValue]]];
            [denominatorField setText:[NSString stringWithFormat:@"%d", [[f numberFromString:[parts objectAtIndex:1]] intValue]]];
            }
        } else {
            [field setTextColor:[UIColor redColor]];
        }
    }
    NSArray *fields = [NSArray arrayWithObjects:numeratorField,denominatorField,centsField,frequencyField, nil];
    bool anyred = false;
    for (int i=0;i<[fields count];i++) {
        if (((UITextField *)[fields objectAtIndex:i]).textColor == [UIColor redColor]) {
            anyred = true;
        }
    }
    if (fabs([centsField.text floatValue])>[userSettings floatForKey:@"Slider Range"]) anyred = true;
    [save setEnabled:!anyred];
}

-(IBAction)cancelled:(id)sender {
    if ([pop isPopoverVisible]) {
        [pop dismissPopoverAnimated:YES];
    }
}

-(IBAction)saved:(id)sender {
    if (frequencyField.textColor == [UIColor redColor]) {
    } else {
        if (centsField.textColor != [UIColor redColor]) {
            //NSLog(@"%f",[centsField.text floatValue]);
            float freq = [frequencyField.text floatValue];
            [delegate SetNoteController:self didFinishWithFrequency:freq forDegree:[degree intValue]];
        }
    }        
}

-(IBAction)intervalChanged:(id)sender {
    [intervalField setText:[NSString stringWithFormat:@"Ratio to %@ in the key of %@",[intervalControl titleForSegmentAtIndex:intervalControl.selectedSegmentIndex],[noteNames objectAtIndex:[delegate getScaleDegree]]]];
    float fromIntervalRatio = [numeratorField.text floatValue]/[denominatorField.text floatValue];
    float ratioToTonic = fromIntervalRatio*[[[delegate scaleRatios] objectAtIndex:currentInterval] floatValue];
    float intervalRatio = ratioToTonic/[[[delegate scaleRatios] objectAtIndex:(int)(intervalControl.selectedSegmentIndex-[delegate getScaleDegree]+12)%12] floatValue];
    currentInterval = (intervalControl.selectedSegmentIndex-(int)[delegate getScaleDegree]+12)%12;
    NSLog(@"%f",intervalRatio);
    NSString *ratioString = [delegate fractionFromFloat:intervalRatio];
    NSArray *parts = [ratioString componentsSeparatedByString:@"/"];
    if ([parts count] == 2) {
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        [numeratorField setText: [NSString stringWithFormat:@"%d",[[f numberFromString:[parts objectAtIndex:0]] intValue]]];
        [denominatorField setText:[NSString stringWithFormat:@"%d", [[f numberFromString:[parts objectAtIndex:1]] intValue]]];
    }

}

@end
