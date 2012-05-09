//
//  ViewController.m
//  Return4
//
//  Created by Ben Weitzman on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "PGMidi.h"
#import "iOSVersionDetection.h"
#import "MidiParser.h"
#import <QuartzCore/CAAnimation.h>
#import <CoreMIDI/CoreMIDI.h>
#import "LoadMidiController.h"
#import "LoadScaleController.h"

@interface ViewController () <PGMidiDelegate, PGMidiSourceDelegate, LoadMidiControllerDelegate, UIAlertViewDelegate, LoadScaleControllerDelegate, SetNoteControllerDelegate>
- (void) addString:(NSString*)string;
@end

@interface UIColor (UIColorCategory)
- (BOOL)isEqualToColor:(UIColor *)otherColor;
@end

@implementation UIColor (UIColorCategory)
- (BOOL)isEqualToColor:(UIColor *)otherColor {
    CGColorSpaceRef colorSpaceRGB = CGColorSpaceCreateDeviceRGB();
    
    UIColor *(^convertColorToRGBSpace)(UIColor*) = ^(UIColor *color) {
        if(CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) == kCGColorSpaceModelMonochrome) {
            const CGFloat *oldComponents = CGColorGetComponents(color.CGColor);
            CGFloat components[4] = {oldComponents[0], oldComponents[0], oldComponents[0], oldComponents[1]};
            return [UIColor colorWithCGColor:CGColorCreate(colorSpaceRGB, components)];
        } else
            return color;
    };
    
    UIColor *selfColor = convertColorToRGBSpace(self);
    otherColor = convertColorToRGBSpace(otherColor);
    CGColorSpaceRelease(colorSpaceRGB);
    
    return [selfColor isEqual:otherColor];
}
@end

@implementation ViewController
@synthesize buffers, pitches, ratios, soundFiles, majorScale, midi,recordedNotes;
@synthesize playButton;
@synthesize loadMidiButton, pc, ac, spc, sac, notePopover, noteViewController;
@synthesize pressRecognizer, tapRecognizer;
@synthesize sliders, frequencyLabels, centsLabels, ratioLabels;

@synthesize hotKey0,hotKey1,hotKey2,hotKey3,hotKey4,hotKey5,hotKey6,hotKey7,hotKey8,hotKey9,hotKey10,hotKey11, hotKeys, tempSlot0, tempSlot1,tempSlot2,tempSlots,tempScales,hotScales;

@synthesize rootNote;

- (NSString *) fractionFromFloat:(float)number {
    NSLog(@"solving for %f",number);
    float z = number;
    float dminus1 = 0;
    float d = 1;
    float n = 0;
    int i = 0;
    float tolerance = 0.0001;
    int iterations = 10;
    if (fabsf(z-roundf(z))<=tolerance) {
     return [NSString stringWithFormat:@"%d/1",(int)roundf(number)];   
    }
    for (i = 0;i<iterations;i++) {
        if (z-floorf(z) != 0 && fabsf(n/d-number)>tolerance) {
            z = 1/(z-floorf(z));
            float nextD = d*floorf(z)+dminus1;
            n = roundf(nextD*number);
            dminus1 = d;
            d = nextD;
        } else {
            break;
        }
        NSLog(@"%d/%d = %f",(int)n,(int)d,n/d);
       // 
    }
    if (i==iterations || log10f(n)>=3) {
        NSLog(@"%.4f",number);
        return [NSString stringWithFormat:@"%.4f",number];
    } else {
        NSLog(@"%d/%d",(int)n,(int)d);
        return [NSString stringWithFormat:@"%d/%d",(int)n,(int)d];
    }
}

- (bufferInfo) bufferFromPitch:(float)pitch {
    float minDifference = 1000000;
    NSString* minFileName = @"";
    float minRatio = 1;
    for (int i=0;i<[soundFiles count];i++) {
        File temp;
        [[soundFiles objectAtIndex:i] getValue:&temp];
        float diff = fabsf(pitch-temp.pitch);
        if (diff<minDifference) {
            minDifference = diff;
            minFileName = temp.filename;
            minRatio = pitch/temp.pitch;
        }
    }
    bufferInfo toReturn;
    toReturn.buffer = [[OpenALManager sharedInstance] 
                        bufferFromFile:minFileName];
    toReturn.scale = minRatio;
    return toReturn;
}

- (void) initSoundFiles {
    soundFiles = [[NSArray alloc] initWithObjects:
                  [NSValue value:&(File){@"P200 Piano A#2.caf",116.541} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#3.caf",233.082} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#4.caf",466.164} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#5.caf",932.328} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#7.caf",3729.32} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano C10.caf",16744.0f} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano C7.caf",2093.0f} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano D#8.caf",4978.03} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano D2.caf",73.4162} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano D3.caf",146.832} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano D4.caf",293.665} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano D5.caf",587.33} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano D6.caf",1174.66} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano F#2.caf",92.4986} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano F#3.caf",184.997} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano F#4.caf",369.994} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano F#5.caf",739.989} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano F#6.caf",1479.98} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano F#7.caf",2959.96} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano G#9.caf",13289.8} withObjCType:@encode(File)],
                  nil];
}

- (void) changeNote:(int) degree to:(float) pitch {
    NSLog(@"degree change: %d",degree);
    int degreeCopy = degree;
    while (degree < 127) {
        bufferInfo info = [self bufferFromPitch:pitch];
        [[pitches objectAtIndex:degree] release];
        [pitches replaceObjectAtIndex:degree withObject:[[NSNumber alloc] initWithFloat:pitch]];
        [[ratios objectAtIndex:degree] release];
        [ratios replaceObjectAtIndex:degree withObject:[[NSNumber alloc] initWithFloat:info.scale]];
        [buffers replaceObjectAtIndex:degree withObject:info.buffer];
        pitch *= 2;
        degree += 12;
    }
    float ratio = [[pitches objectAtIndex:degreeCopy+12] floatValue]/[[pitches objectAtIndex:currentScaleDegree+12] floatValue];
    int scaleDegree = degreeCopy-currentScaleDegree;
    if (scaleDegree < 0) {
        scaleDegree += 12;
        ratio *= 2;
    }
    [[scaleRatios objectAtIndex:scaleDegree] release];
    [scaleRatios replaceObjectAtIndex:scaleDegree withObject:[[NSNumber alloc] initWithFloat:ratio]];
}

- (void) initPitches {
    pitches = [[NSMutableArray alloc] init];
    for (int i=0;i<127;i++) {
        [pitches addObject:[[NSNumber alloc] initWithFloat:powf(2.0f,(i-69.0f)/12)*440]];
    }
    scaleRatios = [[NSMutableArray alloc] init]; 
    for (int i=0;i<12;i++) {
        float ratio = [[pitches objectAtIndex:i] floatValue]/[[pitches objectAtIndex:0] floatValue];
        [scaleRatios addObject:[[NSNumber alloc] initWithFloat:ratio]];
    }
    majorScale = [[NSMutableArray alloc] initWithArray:pitches copyItems:YES];

}

- (void) initBuffers {
    [buffers release];
    buffers = nil;
    //ratios = nil;
    if (channel != nil) {
        //[channel release];
    } else {
        channel = [[ALChannelSource alloc] initWithSources:32];
    }
    if (buffers == nil) {
        buffers = [[NSMutableArray alloc] init];
        for (int i=0;i<127;i++) {
            bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:i] floatValue]];
            [buffers addObject:info.buffer];
        }
    }
    for (int i=0;i<[ratios count];i++ ) {
        NSNumber * num = [ratios objectAtIndex:i];
        [num release];
    }
    [ratios release];
    ratios  = [[NSMutableArray alloc] initWithCapacity:127];
    NSLog(@"ratios size: %d",[ratios count]);
    
    //NSLog(@"A4: %f",[[pitches objectAtIndex:69] floatValue]);
    for (int i=0;i<127;i++) {
        bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:i] floatValue]];
        [ratios addObject:[[NSNumber alloc] initWithFloat:info.scale]];
        if (i/12 == 5) {
            UILabel * label =[frequencyLabels objectAtIndex:i%12];
            [label setText:[NSString stringWithFormat:@"%.2f", [[pitches objectAtIndex:i] floatValue]]];
            label = [centsLabels objectAtIndex:i%12];
            float ratio = [[pitches objectAtIndex:i] floatValue]/[[majorScale objectAtIndex:i] floatValue];
            float cents = roundf((1200*log2f(ratio))*10)/10;
            if (cents >= 0) {
                [label setText:[NSString stringWithFormat:@"+%.1f",fabsf(cents)]];
            } else {
                [label setText:[NSString stringWithFormat:@"%.1f",cents]];
            }
            label = [ratioLabels objectAtIndex:i%12];
            float noteRatio = [[pitches objectAtIndex:i] floatValue]/[[pitches objectAtIndex:(i/12)*12+currentScaleDegree] floatValue];
            if (noteRatio < 1) {
                noteRatio *= 2;
            }
            [label setText:[self fractionFromFloat:noteRatio]];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[self fractionFromFloat:0.263157894737];
    
    frequencyLabels = [[NSArray alloc] initWithArray:[frequencyLabels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 tag] < [obj2 tag]) return NSOrderedAscending;
        else if ([obj1 tag] > [obj2 tag]) return NSOrderedDescending;
        return NSOrderedSame;
    }]];
    
    centsLabels = [[NSArray alloc] initWithArray:[centsLabels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        ((UILabel*)obj1).textAlignment = UITextAlignmentCenter;
        ((UILabel*)obj2).textAlignment = UITextAlignmentCenter;
        if ([obj1 tag] < [obj2 tag]) return NSOrderedAscending;
        else if ([obj1 tag] > [obj2 tag]) return NSOrderedDescending;
        return NSOrderedSame;
    }]];
    
    ratioLabels = [[NSArray alloc] initWithArray:[ratioLabels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        ((UILabel*)obj1).textAlignment = UITextAlignmentCenter;
        ((UILabel*)obj2).textAlignment = UITextAlignmentCenter;
        if ([obj1 tag] < [obj2 tag]) return NSOrderedAscending;
        else if ([obj1 tag] > [obj2 tag]) return NSOrderedDescending;
        return NSOrderedSame;
    }]];
    
    sliders = [[NSArray alloc] initWithArray:[sliders sortedArrayUsingComparator:^NSComparisonResult(UISlider* obj1, UISlider* obj2) {
       /* obj1.transform = CGAffineTransformRotate(obj1.transform, 270.0/180*M_PI);
        obj2.transform = CGAffineTransformRotate(obj2.transform, 270.0/180*M_PI);*/
        if ([obj1 tag] < [obj2 tag]) return NSOrderedAscending;
        else if ([obj1 tag] > [obj2 tag]) return NSOrderedDescending;
        return NSOrderedSame;
    }]];
    for (int i=0;i<[sliders count];i++) {
        UISlider * slider = [sliders objectAtIndex:i];
        CGRect rect = slider.frame;
        slider.frame = CGRectMake(584.0f/12*i-50, 350, rect.size.width, rect.size.height);
        UITapGestureRecognizer * tapsRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSliderTap:)];
        tapsRecognizer.numberOfTapsRequired = 2;
        tapsRecognizer.numberOfTouchesRequired = 1;
        [slider addGestureRecognizer:tapsRecognizer];
        float centerX = slider.frame.origin.x+slider.frame.size.width/2;
        UILabel * label = [ratioLabels objectAtIndex:i];
        label.userInteractionEnabled = YES;
        rect = label.frame;
        UILongPressGestureRecognizer *labelPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLabelPress:)];
        labelPress.minimumPressDuration = 0.6;
        label.frame = CGRectMake(centerX-rect.size.width/2, 200, rect.size.width, rect.size.height);
        [label addGestureRecognizer:labelPress];
        label = [frequencyLabels objectAtIndex:i];
        label.userInteractionEnabled = YES;
        rect = label.frame;
        label.frame = CGRectMake(centerX-rect.size.width/2, 250, rect.size.width, rect.size.height);
        labelPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLabelPress:)];
        labelPress.minimumPressDuration = 0.6;
        [label addGestureRecognizer:labelPress];
        label = [centsLabels objectAtIndex:i];
        label.userInteractionEnabled = YES;
        rect = label.frame;
        label.frame = CGRectMake(centerX-rect.size.width/2,225, rect.size.width, rect.size.height);
        labelPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLabelPress:)];
        labelPress.minimumPressDuration = 0.6;
        [label addGestureRecognizer:labelPress];
        if ([slider.minimumTrackTintColor isEqualToColor:[UIColor blackColor]]) {
            /* black keys */
           //slider.frame = CGRectMake(584.0f/12*i-50, 330, rect.size.width, rect.size.height);
        }
        slider.transform = CGAffineTransformRotate(slider.transform, 270.0/180*M_PI);
    }
    
    device = [[ALDevice alloc] initWithDeviceSpecifier:nil];
    context = [ALContext contextOnDevice:device attributes:nil];
    [OpenALManager sharedInstance].currentContext = context;
    // Deal with interruptions for me!
    [OALAudioSession sharedInstance].handleInterruptions = YES;
    // We don’t want ipod music to keep playing since
    // we have our own bg music.
    [OALAudioSession sharedInstance].allowIpod = NO;
    // Mute all audio if the silent switch is turned on.
    [OALAudioSession sharedInstance].honorSilentSwitch = YES;
    // Take all 32 sources for this channel.
    // (we probably won’t use that many but what the heck!)
    channel = [[ALChannelSource alloc] initWithSources:127];
    channels = [[NSMutableArray alloc] init];
    //for (int i=0;i<127;i++) {
    //    [channels addObject:[[ALSoundSo
    //}
    [self initSoundFiles];
    [self initPitches];
    [self initBuffers];
    currentOctave = 0;
    playing = false;
    stopped = false;
    paused = false;
    recordTimer = -1;
    //NSLog(@"current time: %f",CACurrentMediaTime());
    recording = false;
    recordedNotes = [[NSMutableArray alloc] init];
    parser = [[MidiParser alloc] init];
    saving = false;
    loadingScale = false;
    changingPitch = false;
    currentScaleDegree = 0;
    
    tempScales = [[NSMutableArray alloc] initWithObjects:[[NSMutableArray alloc] init],
                                                         [[NSMutableArray alloc] init],
                                                         [[NSMutableArray alloc] init],nil];
    hotScales = [[NSMutableArray alloc] initWithObjects:[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init],[[NSMutableArray alloc] init], nil];
    scaleToSave = nil;
    
    hotKeys = [[NSMutableArray alloc] initWithObjects:hotKey0,hotKey1,hotKey2,hotKey3,hotKey4,hotKey5,hotKey6,hotKey7,hotKey8,hotKey9,hotKey10,hotKey11, nil];
    
    tempSlots = [[NSMutableArray alloc] initWithObjects:tempSlot0,tempSlot1,tempSlot2,nil];
    
    for (int i=0;i<[tempSlots count];i++) {
        pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTempPress:)];
        pressRecognizer.minimumPressDuration = 0.8;
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTempTap:)];
        tapRecognizer.numberOfTapsRequired = 2;
        tapRecognizer.numberOfTouchesRequired = 1;
        UIButton *tempSlot = [tempSlots objectAtIndex:i];
        [tempSlot addGestureRecognizer:pressRecognizer];
        [tempSlot addGestureRecognizer:tapRecognizer];
        [tempSlot setTitle:@"Press and hold\nto grab current\nscale" forState:UIControlStateNormal]; 
        [tempSlot setTitle:@"Press and hold\nto grab current\nscale" 
                forState:UIControlStateHighlighted]; 
        tempSlot.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];
        tempSlot.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        tempSlot.titleLabel.textAlignment = UITextAlignmentCenter;
    }
    // Add gesture recognizer to the view
    for (int i=0;i<[hotKeys count];i++) {
        pressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handlePress:)]; // Absolutely need ":" after handleTaps
    
    // The number of fingers that must be on the screen
        pressRecognizer.minimumPressDuration = 0.8;
        UIButton * hotKey = [hotKeys objectAtIndex:i];
        
        [hotKey setTitle:@"Press and hold\nto load a scale" forState:UIControlStateNormal]; 
        [hotKey setTitle:@"Press and hold\nto load a scale" 
                forState:UIControlStateHighlighted]; 
        hotKey.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];      
        hotKey.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        hotKey.titleLabel.textAlignment = UITextAlignmentCenter;
        [hotKey addGestureRecognizer:pressRecognizer];
    }
    UISlider * rootSlider = [sliders objectAtIndex:currentScaleDegree];
    rootSlider.enabled = false;
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)playTemp:(id)sender {
    UIButton * button = sender;
    if ([[tempScales objectAtIndex:button.tag] count] != 0) {
        for (int i=0;i<127;i++) {
            float lowPitch = [[[tempScales objectAtIndex:button.tag] objectAtIndex:i%12] floatValue];
            int octave = i/12;
            float newPitch = pow(2,octave)*lowPitch;
            //NSLog(@"degree: %d, octave: %d, oldPitch: %f, newPitch: %f",i%12,i/12+1,[[pitches objectAtIndex:i] floatValue], newPitch);
            [[pitches objectAtIndex:i] release];
            [pitches replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithFloat:newPitch]];
            if (octave == 0) {
                float ratio = newPitch/[[majorScale objectAtIndex:i] floatValue];
                float newValue = (log2f(ratio)*12+1)/2;
                UISlider *slider = [sliders objectAtIndex:i];
                NSLog(@"slider value: %f",slider.value);
                [slider setValue:newValue animated:YES];
            }
        }
        [self initBuffers];
    }
    
    //NSLog(@"playing temp slot %d",button.tag);
}
-(void)handleLabelPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UILabel *label= (UILabel *)sender.view;
        NSLog(@"launching on : %d", label.tag);
        if (label.tag != currentScaleDegree) {
        UIView *view = sender.view;
        if (noteViewController == nil && notePopover == nil) {
            noteViewController = [[SetNoteController alloc] initWithNibName:@"SetNoteController" bundle:nil];
            notePopover = [[UIPopoverController alloc] initWithContentViewController:noteViewController];
            noteViewController.delegate = self;
            noteViewController.pop = notePopover;
            noteViewController.degree = [[NSNumber alloc] initWithInt:label.tag];
            noteViewController.frequency = [pitches objectAtIndex:label.tag+60];
            float ratio = [[pitches objectAtIndex:label.tag+12] floatValue]/[[majorScale objectAtIndex:label.tag+12] floatValue];
            float cents = roundf((1200*log2f(ratio))*10)/10;
            noteViewController.cents = [NSNumber numberWithFloat:cents];
            
            float noteRatio = [[pitches objectAtIndex:label.tag] floatValue]/[[pitches objectAtIndex:currentScaleDegree] floatValue];
            if (noteRatio < 1) {
                noteRatio *= 2;
            }
            NSString *ratioString = [self fractionFromFloat:noteRatio];
            NSArray *parts = [ratioString componentsSeparatedByString:@"/"];
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            noteViewController.numerator = [f numberFromString:[parts objectAtIndex:0]];
            noteViewController.denominator = [f numberFromString:[parts objectAtIndex:1]];
            
            [notePopover presentPopoverFromRect:[view bounds] inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            //sac.button = (UIButton *)sender.view;
        }
        else if ([notePopover isPopoverVisible]) {
            [notePopover dismissPopoverAnimated:YES];
        }
        else {
            [notePopover release];
            [noteViewController release];
            noteViewController = [[SetNoteController alloc] initWithNibName:@"SetNoteController" bundle:nil];
            notePopover = [[UIPopoverController alloc] initWithContentViewController:noteViewController];
            noteViewController.delegate = self;
            noteViewController.pop = notePopover;
            noteViewController.degree = [[NSNumber alloc] initWithInt:label.tag];
            noteViewController.frequency = [pitches objectAtIndex:label.tag+60];
            float ratio = [[pitches objectAtIndex:label.tag+12] floatValue]/[[majorScale objectAtIndex:label.tag+12] floatValue];
            float cents = roundf((1200*log2f(ratio))*10)/10;
            noteViewController.cents = [NSNumber numberWithFloat:cents];
            
            float noteRatio = [[pitches objectAtIndex:label.tag] floatValue]/[[pitches objectAtIndex:currentScaleDegree] floatValue];
            if (noteRatio < 1) {
                noteRatio *= 2;
            }
            NSString *ratioString = [self fractionFromFloat:noteRatio];
            NSArray *parts = [ratioString componentsSeparatedByString:@"/"];
            NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
            [f setNumberStyle:NSNumberFormatterDecimalStyle];
            noteViewController.numerator = [f numberFromString:[parts objectAtIndex:0]];
            noteViewController.denominator = [f numberFromString:[parts objectAtIndex:1]];
            [notePopover presentPopoverFromRect:[view bounds] inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        }
    }
}

- (void)handleSliderTap:(UITapGestureRecognizer *)sender {
    UISlider *slider = (UISlider *)sender.view;
    [slider setValue:0.5 animated:YES];
    NSLog(@"%d",slider.tag);
    [self sliderChanged:slider];
}

- (void)handleTempTap:(UITapGestureRecognizer *)sender {
    UIView *view = sender.view;
    //UIButton *button = (UIButton *)sender.view;
    scaleToSave = [[NSMutableArray alloc] initWithArray:[tempScales objectAtIndex:view.tag ] copyItems:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save" message:@"Save your scale?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save Scale", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void) handleTempPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIView *view = sender.view;
        UIButton *button = (UIButton* )sender.view;
        NSMutableArray *currentScale = [[NSMutableArray alloc] init];
        for (int i=0;i<12;i++) {
            [currentScale addObject:[pitches objectAtIndex:i]];
        }
        [tempScales replaceObjectAtIndex:view.tag withObject:currentScale];
        [button setTitle:@"Tap to play\nDouble tap to save" forState:UIControlStateNormal]; 
        [button setTitle:@"Tap to play\nDouble tap to save" 
                  forState:UIControlStateHighlighted]; 
        //NSLog(@"load current scale to temp slot %d",view.tag);
    }
}

- (void) handlePress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIView *view = sender.view;
        NSLog(@"long press: %d",view.tag);
        if (sac == nil && spc == nil) {
            sac = [[LoadScaleController alloc] initWithNibName:@"LoadScaleController" bundle:nil];
            spc = [[UIPopoverController alloc] initWithContentViewController:sac];
            sac.delegate = self;
            sac.button = (UIButton *)sender.view;
        }
        if ([spc isPopoverVisible]) {
            [spc dismissPopoverAnimated:YES];
        }
        else {
            sac = nil;
            spc = nil;
            sac = [[LoadScaleController alloc] initWithNibName:@"LoadScaleController" bundle:nil];
            spc = [[UIPopoverController alloc] initWithContentViewController:sac];
            sac.delegate = self;
            sac.button = (UIButton *)sender.view;
            [spc presentPopoverFromRect:[view bounds] inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    IF_IOS_HAS_COREMIDI
    (
     [self addString:@"This iOS Version supports CoreMIDI"];
     )
    else
    {
        [self addString:@"You are running iOS before 4.2. CoreMIDI is not supported."];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES;
    }
    return NO;
}

- (void) attachToAllExistingSources
{
    for (PGMidiSource *source in midi.sources)
    {
        source.delegate = self;
    }
}

- (void) setMidi:(PGMidi*)m
{
    midi.delegate = nil;
    midi = m;
    midi.delegate = self;
    
    [self attachToAllExistingSources];
}

- (void) noteOff:(int)noteValue {
    if (noteValue>=0 && noteValue<127) {
        if (recording) {
            double currentTime = CACurrentMediaTime();
            int deltaTime = (int)(currentTime*1000-recordTimer*1000);
            NoteObject * recordedNote = [[NoteObject alloc] init];
            recordedNote.note = noteValue;
            recordedNote.time = deltaTime;
            recordedNote.noteOn = false;
            [recordedNotes addObject:recordedNote];
            recordTimer = currentTime;
        }
    }
}

- (void) noteOn:(int)noteValue {
    if (noteValue>=0 && noteValue<127) {
        if (recording) {
            double currentTime = CACurrentMediaTime();
            int deltaTime = (int)(currentTime*1000-recordTimer*1000);
            NoteObject * recordedNote = [[NoteObject alloc] init];
            recordedNote.note = noteValue;
            recordedNote.time = deltaTime;
            recordedNote.noteOn = true;
            [recordedNotes addObject:recordedNote];
            recordTimer = currentTime;
        }
        //float pitch = [[pitches objectAtIndex:noteValue] floatValue];
        while(loadingScale || changingPitch);
        ALBuffer* toPlay = [[self buffers] objectAtIndex:noteValue];
        NSLog(@"buffers count: %d, note value: %d, buffer: %@, ratio: %f",[buffers count],noteValue,toPlay, [[ratios objectAtIndex:noteValue] floatValue]);
            float pitchToPlay = [[ratios objectAtIndex:noteValue] floatValue];
            NSLog(@"%f",pitchToPlay);
            [channel play:toPlay gain:1.0f pitch:pitchToPlay pan:0.0f loop:FALSE];
        //channel = [[ALChannelSource alloc] initWithSources:32];
        /*} else {
            bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:noteValue] floatValue]];
            [buffers replaceObjectAtIndex:noteValue withObject:info.buffer];
            [ratios replaceObjectAtIndex:noteValue withObject:[[NSNumber alloc] initWithFloat:info.scale]];
            [channel play:info.buffer gain:1.0f pitch:info.scale pan:0.0f loop:FALSE];
        }*/
    }
}

- (IBAction) buttonTriggered:(id)sender {
    //NSLog(buffers);
    UIButton *button = (UIButton *)sender;
    //ALBuffer* lebuf = (ALBuffer *)[buffers objectsAtIndex:1];
    //float pitchToPlay = [[ratios objectAtIndex:button.tag+currentOctave] floatValue];
    int midiNote = 60+button.tag+12*currentOctave;
    NSLog(@"note: %d",midiNote);
    [self noteOn:midiNote];
    //[channel play:[[self buffers] objectAtIndex:button.tag] gain:1.0f pitch:pitchToPlay pan:0.0f loop:FALSE];
}



- (IBAction) sliderChanged:(id)sender {
    //[channel stop];
    changingPitch = true;
    UISlider *slider = (UISlider *)sender;
    float newRatio = powf(2.0f,(slider.value*2-1)/12);
    NSLog(@"new ratio: %f", newRatio);
    NSLog(@"major scale %f",[[majorScale objectAtIndex:slider.tag] floatValue]);
    float newPitch = newRatio*[[majorScale objectAtIndex:slider.tag] floatValue];
    NSLog(@"new pitch for degree %u: %f",slider.tag,newPitch);
    [self changeNote:slider.tag to:newPitch];
    NSLog(@"slider %d",slider.tag);
    UILabel * label = [frequencyLabels objectAtIndex:slider.tag];
    //NSLog(@"%d",[frequencyLabels count]);
    [label setText:[NSString stringWithFormat:@"%.2f",newPitch*(2<<4)]];
    label = [centsLabels objectAtIndex:slider.tag];
    [label setText:[NSString stringWithFormat:@"%.1f",1200*log2f(newRatio)]];
    label = [ratioLabels objectAtIndex:slider.tag];
    float displayRatio = newPitch*2/[[pitches objectAtIndex:12+currentScaleDegree] floatValue];
    if (displayRatio < 1) {
        displayRatio *= 2;
    }
    [label setText:[self fractionFromFloat:displayRatio]];
    //label = [ratioLabels objectAtIndex:(slider.tag+1)%12];
    //displayRatio = [[pitches objectAtIndex:12] floatValue]/(newPitch*2);
    //[label setText:[self fractionFromFloat:displayRatio]];
    changingPitch = false;
}

- (IBAction) octaveChanged:(id)sender {
    UIStepper *stepper = (UIStepper *)sender;
    //for (int i=0;i<[pitches count];i++) {
    //    [self changeNote:i to:[[pitches objectAtIndex:i] floatValue]*powf(2.0,(stepper.value-currentOctave))];  
    //}
    currentOctave = stepper.value;
}

-(const char *)BoolToString:(BOOL) b { return b ? "yes":"no"; }

-(NSString *) ToString:(PGMidiConnection *) connection
{
    return [NSString stringWithFormat:@"< PGMidiConnection: name=%@ isNetwork=%s >",
            connection.name, [self BoolToString:connection.isNetworkSession]];
}

- (void) addString:(NSString *)string {
    NSLog(@"%@",string);
}

- (void) midi:(PGMidi*)midi sourceAdded:(PGMidiSource *)source
{
    source.delegate = self;
    //[self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Source added: %@", [self ToString:source]]];
}

- (void) midi:(PGMidi*)midi sourceRemoved:(PGMidiSource *)source
{
    //[self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Source removed: %@", [ self ToString:source]]];
}

- (void) midi:(PGMidi*)midi destinationAdded:(PGMidiDestination *)destination
{
    //[self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Desintation added: %@", [self ToString:destination ]]];
}

- (void) midi:(PGMidi*)midi destinationRemoved:(PGMidiDestination *)destination
{
    //[self updateCountLabel];
    [self addString:[NSString stringWithFormat:@"Desintation removed: %@", [self ToString:destination]]];
}

-(NSString *) StringFromPacket:(const MIDIPacket *)packet
{
    // Note - this is not an example of MIDI parsing. I'm just dumping
    // some bytes for diagnostics.
    // See comments in PGMidiSourceDelegate for an example of how to
    // interpret the MIDIPacket structure.
    return [NSString stringWithFormat:@"  %u bytes: [%02x,%02x,%02x]",
            packet->length,
            (packet->length > 0) ? packet->data[0] : 0,
            (packet->length > 1) ? packet->data[1] : 0,
            (packet->length > 2) ? packet->data[2] : 0
            ];
}

- (void) midiSource:(PGMidiSource*)midi midiReceived:(const MIDIPacketList *)packetList
{
    [self performSelectorOnMainThread:@selector(addString:)
                           withObject:@"MIDI received:"
                        waitUntilDone:NO];
    
    const MIDIPacket *packet = &packetList->packet[0];
    for (int i = 0; i < packetList->numPackets; ++i)
    {
        //[self performSelectorOnMainThread:@selector(addString:)
        //                      withObject:[self StringFromPacket:packet]
        //                    waitUntilDone:NO];
        if (packet->length == 3) {
            if ((packet->data[0]&0xF0) == 0x90) {
                if (packet->data[2] != 0) {
                    [self noteOn:packet->data[1]];
                    NSLog(@"midi note: %d on",packet->data[1]);
                }
            }
        }
        packet = MIDIPacketNext(packet);
    }
}

-(void)startRecording {
    recordTimer = CACurrentMediaTime();
    recordedNotes = nil;
    recordedNotes = [[NSMutableArray alloc] init];
    recording = true;
}

-(void)stopRecording {
    recording = false;
    parser.events = nil;
    parser.events = [[NSMutableArray alloc] init];
    parser.ticksPerSecond = 480;
    parser.bpm = 120;
    for (int i=0;i<[recordedNotes count];i++) {
        NoteObject * currentNote = [recordedNotes objectAtIndex:i];
        NSLog(@"recorded note:%d at %d %d",currentNote.note,currentNote.time,currentNote.noteOn);
        currentNote.time *= parser.ticksPerSecond/1000;
        [parser.events addObject:currentNote];
    }
}

-(void)recordMidi:(id)sender {
    if (!recording) {
        [self startRecording];
    } else {
        [self stopRecording];
    }
}


-(void)stopMidi:(id)sender{
    stopped = true;
    paused = false;
    if (recording) {
        [self stopRecording];
    }
}

-(void)pauseMidi:(id)sender {
    paused = true;
    playButton.enabled = true;
}

- (IBAction)playMidi:(id)sender {
    UIButton *button = (UIButton*)sender;
    button.enabled = false;
    if (!playing) {
        playing = true;
        paused = false;
        stopped = false;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *events = parser.events;
            double ticksPerSecond = [parser ticksPerSecond];
            //int ticksPerSecond = [parser 
            for (int i=0;i<[events count];i++) {
                while (paused || loadingScale || changingPitch);
                if (stopped) break;
                NoteObject *currentNote = [events objectAtIndex:i];
                if (i==0) {
                    currentNote.time = 0;
                }
                [NSThread sleepForTimeInterval:(currentNote.time/ticksPerSecond)];
                while (paused || loadingScale || changingPitch);
                if (stopped) break;
                if (currentNote.noteOn) {
                    [self noteOn:currentNote.note];
                } else {
                    [self noteOff:currentNote.note];
                }
            } 
            NSLog(@"finished playing");
            playing = false;
            stopped = false;
            paused = false;
            button.enabled = true;
        });
    } else {
        paused = false;
    }
}

- (IBAction)saveMidi:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save" message:@"Save your midi file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
    //[alert release];
}

- (IBAction)loadMidi:(id)sender {
    
    if (ac == nil && pc == nil) {
        ac = [[LoadMidiController alloc] initWithNibName:@"LoadMidiController" bundle:nil];
        pc = [[UIPopoverController alloc] initWithContentViewController:ac];
        //ac.delegate = self;
        ac.delegate = self;
    }
    if ([pc isPopoverVisible]) {
        [pc dismissPopoverAnimated:YES];
    }
    else {
        ac = nil;
        pc = nil;
        ac = [[LoadMidiController alloc] initWithNibName:@"LoadMidiController" bundle:nil];
        pc = [[UIPopoverController alloc] initWithContentViewController:ac];
        //ac.delegate = self;
        ac.delegate = self;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save first" 
                                                        message:@"If you load a new midi file, any midi data that you have recorded and haven't saved will be deleted. Do you want to continue?"  
                                                       delegate:self 
                                              cancelButtonTitle:@"Cancel" 
                                              otherButtonTitles:@"Continue Without Saving",@"Save And Continue", nil];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if (title == @"Continue Without Saving") {
        [pc presentPopoverFromRect:[loadMidiButton bounds] inView:loadMidiButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else if (title == @"Save And Continue") {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Save" message:@"Save you midi file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
        saving = true;
    } else if (title == @"Save") {
        [self writeNotesToFile:[[alertView textFieldAtIndex:0] text]];
        if (saving) {
            saving = false;
            ac = nil;
            pc = nil;
            ac = [[LoadMidiController alloc] initWithNibName:@"LoadMidiController" bundle:nil];
            pc = [[UIPopoverController alloc] initWithContentViewController:ac];
            //ac.delegate = self;
            ac.delegate = self;
            [pc presentPopoverFromRect:[loadMidiButton bounds] inView:loadMidiButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    } else if (title == @"Save Scale" ) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *file = [documentsDirectory stringByAppendingPathComponent:[[[alertView textFieldAtIndex:0] text] stringByAppendingPathExtension:@"scale"]];
        NSLog(@"%@",file);
        [scaleToSave writeToFile:file atomically:YES];
    }
}

-(void)LoadScaleController:(LoadScaleController *)scaleController didFinishWithSelection:(NSString *)selection {
    NSMutableArray *loadedScale = [[NSMutableArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:selection ofType: @"scale"]];
    if ([loadedScale count] == 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        loadedScale = nil;
        loadedScale = [[NSMutableArray alloc] initWithContentsOfFile:[NSBundle pathForResource:selection ofType:@"scale" inDirectory:documentsDirectory]];
    }
    for (int i=0;i<[loadedScale count];i++) {
       // NSLog(@"%f",[[loadedScale objectAtIndex:i] floatValue]);
    }
    UIButton *button = scaleController.button;
    [button setTitle:selection forState:UIControlStateNormal]; 
    [button setTitle:selection forState:UIControlStateHighlighted];
    NSLog(@"%d",button.tag);
    NSLog(@"%@",loadedScale);
    [[hotScales objectAtIndex:button.tag] release];
    [hotScales replaceObjectAtIndex:button.tag withObject:[[NSMutableArray alloc] initWithArray:loadedScale copyItems:YES]];
    NSLog(@"%@",[hotScales objectAtIndex:button.tag]);
    [spc dismissPopoverAnimated:YES];
    NSLog(@"%@",pitches);
    [loadedScale release];
}

- (void)LoadMidiController:(LoadMidiController *)midiController didFinishWithSelection:(NSString*)selection {
    NSLog(@"%@",selection);
    [pc dismissPopoverAnimated:YES];
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:selection ofType: @"mid"]];
    if ([data length] == 0) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        data = nil;
        data = [[NSData alloc] initWithContentsOfFile:[NSBundle pathForResource:selection ofType:@"mid" inDirectory:documentsDirectory]];
    }
	NSMutableArray * byteArray = [[NSMutableArray alloc] init];
    for (int i=0;i<[data length];i++) {
        NSRange range = NSMakeRange(i,1);
        char dataBuffer;
        [data getBytes:&dataBuffer range:range];
        [byteArray addObject:[[NSNumber alloc] initWithUnsignedInt:dataBuffer]];
    }
    
    [parser parseData:data];
    NSLog(@"ticks per second: %f",parser.ticksPerSecond);
    [byteArray release];
}

-(NSEnumerator *)convertToVLQ:(int)value {
    NSMutableArray *bytes = [[NSMutableArray alloc] init];
    char out = value&0x7F;
    [bytes addObject:[[NSNumber alloc] initWithChar:out]];
    while ((value>>=7) != 0) {
        out = (value&0x7F)|0x80;
        [bytes addObject:[[NSNumber alloc] initWithChar:out]];
    }
    return [bytes reverseObjectEnumerator];
}

- (void)writeNotesToFile:(NSString *)file {
    int ticksPerBeat = parser.ticksPerSecond/(float)parser.bpm*60;
    char header[22] = {'M','T','h','d',
                    0x00,0x00,0x00,0x06,
                    0x00,0x00,
                    0x00,0x01,
                    (ticksPerBeat&0xFF00)<<8,ticksPerBeat&0xFF,
                    'M','T','r','k',
                    0x00,0xff,0x00,0x90};
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writeFile = [documentsDirectory stringByAppendingPathComponent:[file stringByAppendingPathExtension:@"mid"]];
    NSMutableData *data = [NSMutableData dataWithLength:0];
    [data appendBytes:&header length:sizeof(header)];
    int tempo = 60000000.0f/parser.bpm;
    char metaTime[7] = {0x00, 0xFF,0x51,0x03,(tempo>>16)&0xff,(tempo>>8)&0xff,tempo&0xff};
    [data appendBytes:&metaTime length:7];
    for (int i=0;i<[parser.events count];i++) {
        NoteObject *currentNote = [parser.events objectAtIndex:i];
        int time = currentNote.time;
        
        NSEnumerator *bytes = [self convertToVLQ:time];
        NSNumber *byte;
        while ((byte = [bytes nextObject])) {
            char out = [byte charValue]&0xff;
            [data appendBytes:&out length:1];
        }
        [bytes release];
        if (currentNote.noteOn) {
            NSLog(@"saving note: %x",currentNote.note&0xff);
            char midiEvent[3] = {0x90,(char)(currentNote.note)&0xff,0x7f}; 
            [data appendBytes:&midiEvent length:3];

        } else {
            char midiEvent[3] = {0x80,(char)(currentNote.note)&0xff,0x00}; 
            [data appendBytes:&midiEvent length:3];
        
        }
    }
    
    [data writeToFile:writeFile atomically:YES];
    NSLog(@"%@",writeFile);
}

-(IBAction)changeRootNote:(id)sender {
    if (!loadingScale) {
        [channel stop];
        loadingScale = true;
    UISlider * rootSlider = [sliders objectAtIndex:currentScaleDegree];
    rootSlider.enabled = true;
    UISegmentedControl * segmented = sender;
    NSLog(@"selected %d",segmented.selectedSegmentIndex);
    currentScaleDegree = segmented.selectedSegmentIndex;
    rootSlider = [sliders objectAtIndex:currentScaleDegree];
    rootSlider.enabled = false;
    float baseNote = [[majorScale objectAtIndex:currentScaleDegree] floatValue];
    for (int i = currentScaleDegree;i<127;i++) {
        float lowPitch = [[scaleRatios objectAtIndex:(i-currentScaleDegree)%12] floatValue]*baseNote;
        if (i%12<currentScaleDegree) {
            lowPitch /= 2;
        }
        int octave = i/12;
        float newPitch = pow(2,octave)*lowPitch;
        [[pitches objectAtIndex:i] release];
        [pitches replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithFloat:newPitch]];
        if (octave == 3) {
            float ratio = newPitch/[[majorScale objectAtIndex:i] floatValue];
            float newValue = (log2f(ratio)*12+1)/2;
            UISlider *slider = [sliders objectAtIndex:i%12];
            NSLog(@"slider value: %f",slider.value);
            [slider setValue:newValue animated:YES];
        }

    }
    [self initBuffers];
        loadingScale = false;
    }
}

-(IBAction)loadScale:(id)sender {
    
    UIButton * button = sender;
    if (!loadingScale) {
    //NSLog(@"%d",button.tag);
    NSMutableArray *newScale = [hotScales objectAtIndex:button.tag];
    //NSLog(@"%@",newScale);
    loadingScale = true;
    //[buffers release];
    if ([newScale count] != 0) {
        [channel stop];
        for (int i=0;i<127;i++) {
            //NSLog(@"%@",newScale);
            float lowPitch = [[newScale objectAtIndex:i%12] floatValue];
            int octave = i/12;
            float newPitch = pow(2,octave)*lowPitch;
            //NSLog(@"degree: %d, octave: %d, oldPitch: %f, newPitch: %f",i%12,i/12+1,[[pitches objectAtIndex:i] floatValue], newPitch);
            [[pitches objectAtIndex:i] release];
            [pitches replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithFloat:newPitch]];
        }
        for (int i=0;i<12;i++) {
            [[scaleRatios objectAtIndex:i] release];
            [scaleRatios replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithFloat:[[pitches objectAtIndex:i] floatValue]/[[pitches objectAtIndex:0] floatValue]]];
        }
        //[self initBuffers];
        loadingScale = false;
        [self changeRootNote:rootNote];
    }
        loadingScale = false;
    NSLog(@"%@",pitches);
    }
    //[midi release];
    //PGMidi* midiTemp = [[PGMidi alloc] init];
    //[midiTemp enableNetwork:YES];
    //[self setMidi:midiTemp];
    //viewController.midi = midi;
}

-(NSMutableArray *) getEqual {
    return [[NSMutableArray alloc] initWithArray:majorScale copyItems:YES];
}

-(NSMutableArray *) getPitches {
    return [[NSMutableArray alloc] initWithArray:pitches copyItems:YES];
}

-(float) getScaleDegree {
    return currentScaleDegree;
}


@end
