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
    CGSize size = CGSizeMake(350, 350); // size of view in popover
    self.contentSizeForViewInPopover = size;
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
    //NSLog(@" %d",[degree intValue]);
    NSLog(@"%@",degree);
    NSArray * noteNames = [[NSArray alloc] initWithObjects:@"C",@"C♯",@"D",@"E♭",@"E",@"F",@"F♯",@"G",@"A♭",@"A",@"B♭",@"B", nil];
    NSLog(@"note: %@",[noteNames objectAtIndex:[degree intValue]]);
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
            float ratio = [numeratorField.text floatValue]/[denominatorField.text floatValue];
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
            float noteRatio = freq/[[[delegate getPitches] objectAtIndex:60+[delegate getScaleDegree]]floatValue];
            //float noteRatio = ratio;
            if (noteRatio < 1) {
                noteRatio *= 2;
            }
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
            float noteRatio = freq/[[[delegate getPitches] objectAtIndex:60+[delegate getScaleDegree]] floatValue];
            //float noteRatio = ratio;
            if (noteRatio < 1) {
                noteRatio *= 2;
            }
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
}

-(IBAction)cancelled:(id)sender {
    if ([pop isPopoverVisible]) {
        [pop dismissPopoverAnimated:YES];
    }
}

-(IBAction)saved:(id)sender {
    if (frequencyField.textColor == [UIColor redColor]) {
    } else {
        if (centsField.textColor != [UIColor redColor] && fabsf([centsField.text floatValue])<=50.0f) {
            //NSLog(@"%f",[centsField.text floatValue]);
            float freq = [frequencyField.text floatValue];
            [delegate SetNoteController:self didFinishWithFrequency:freq forDegree:[degree intValue]];
        }
    }
        
}

@end
