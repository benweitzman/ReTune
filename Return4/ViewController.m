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
#import "InstrumentController.h"
#import "MoreScalesController.h"
#import "PublishScaleController.h"
#import "PublishScaleDetailController.h"
#import "JSONKit.h"

@interface ViewController () <PGMidiDelegate, PGMidiSourceDelegate, LoadMidiControllerDelegate, UIAlertViewDelegate, LoadScaleControllerDelegate, SetNoteControllerDelegate, InstrumentControllerDelegate>
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
@synthesize buffers, pitches, ratios, soundFiles, majorScale, midi,recordedNotes, loopBuffers;
@synthesize playButton, pauseButton, stopButton, loadButton, saveButton, recordButton;
@synthesize loadMidiButton, pc, ac, spc, sac, notePopover, noteViewController, infoViewController;
@synthesize pressRecognizer, tapRecognizer;
@synthesize sliders, frequencyLabels, centsLabels, ratioLabels, buttons;
@synthesize instrumentViewController, instrumentButton, publishButton;
@synthesize hotKey0,hotKey1,hotKey2,hotKey3,hotKey4,hotKey5,hotKey6,hotKey7,hotKey8,hotKey9,hotKey10,hotKey11, hotKeys, tempSlot0, tempSlot1,tempSlot2,tempSlots,tempScales,hotScales;
@synthesize rootNote;

- (NSString *) fractionFromFloat:(float)number {
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
    }
    if (i==iterations || log10f(n)>=3) {
        return [NSString stringWithFormat:@"%.4f",number];
    } else {
        return [NSString stringWithFormat:@"%d/%d",(int)n,(int)d];
    }
}

- (bufferInfo) bufferFromPitch:(float)pitch {
    float minDifference = 1000000;
    NSString* minFileName = @"";
    float minRatio = 1;
    int minIndex = 0;
    for (int i=0;i<[instrument count];i++) {
        NSDictionary *temp = (NSDictionary *)[instrument objectAtIndex:i];
        int midiNote = (int)[[temp valueForKey:@"Midi Note"] intValue];
        float tempPitch = (440.0f / 32) * (powf(2.0f,(midiNote - 9)/12.0f));
        float diff = fabsf(pitch-tempPitch);
        if (diff<=minDifference) {
            minDifference = diff;
            minFileName = (NSString *)[temp valueForKey:@"Sound File"];
            minRatio = pitch/tempPitch;
            minIndex = i;
        }
    }
    bufferInfo toReturn;
    toReturn.buffer = [[OpenALManager sharedInstance] 
                        bufferFromFile:minFileName];
    NSDictionary *minFile = (NSDictionary *)[instrument objectAtIndex:minIndex];
    if ([minFile valueForKey:@"Loop Start"] != nil) {
        toReturn.loop = TRUE;
        toReturn.loopStart = [[minFile valueForKey:@"Loop Start"] intValue];
        toReturn.loopEnd = [[minFile valueForKey:@"Loop End"] intValue];
    }
    toReturn.scale = minRatio;
    return toReturn;
}

- (void) changeNote:(int) degree to:(float) pitch {
    int degreeCopy = degree;
    while (degree < 127) {
        bufferInfo info = [self bufferFromPitch:pitch];
        float oldPitch = [[pitches objectAtIndex:degree] floatValue];
        [[pitches objectAtIndex:degree] release];
        [pitches replaceObjectAtIndex:degree withObject:[[NSNumber alloc] initWithFloat:pitch]];
        [[ratios objectAtIndex:degree] release];
        [ratios replaceObjectAtIndex:degree withObject:[[NSNumber alloc] initWithFloat:info.scale]];
        if (!info.loop) {
            [buffers replaceObjectAtIndex:degree withObject:info.buffer];
            [loopBuffers replaceObjectAtIndex:degree withObject:[NSNull null]];
        } else {
            [buffers replaceObjectAtIndex:degree withObject:[info.buffer sliceWithName:nil offset:0 size:info.loopStart]];
            [loopBuffers replaceObjectAtIndex:degree withObject:[info.buffer sliceWithName:nil offset:info.loopStart size:info.loopEnd-info.loopStart]];
        }
        
        float differenceRatio = pitch/oldPitch;
        ALSource *source = (ALSource *)[sources objectAtIndex:degree];
        ALSource *loopSource = (ALSource *)[loopSources objectAtIndex:degree];
        if (source.playing || loopSource.playing) {
            source.pitch *= differenceRatio;
            loopSource.pitch *= differenceRatio;
        }
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
    sources = nil;
    pitches = [[NSMutableArray alloc] init];
    sources = [[NSMutableArray alloc] init];
    loopSources = [[NSMutableArray alloc] init];
    fadingOut = [[NSMutableArray alloc] init];
    for (int i=0;i<127;i++) {
        [pitches addObject:[[NSNumber alloc] initWithFloat:powf(2.0f,(i-69.0f)/12)*440]];
        [sources addObject:[[ALSource alloc] init]];
        [loopSources addObject:[[ALSource alloc] init]];
        [fadingOut addObject:[[NSNumber alloc] initWithBool:NO]];
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
    [loopBuffers release];
    buffers = nil;
    loopBuffers = nil;
    //ratios = nil;
    if (buffers == nil) {
        buffers = [[NSMutableArray alloc] init];
        loopBuffers = [[NSMutableArray alloc] init];
        for (int i=0;i<127;i++) {
            bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:i] floatValue]];
            if (!info.loop) {
                [buffers addObject:info.buffer];
                [loopBuffers addObject:[NSNull null]];
            } else {
                [buffers addObject:[info.buffer sliceWithName:nil offset:0 size:info.loopStart]];
                [loopBuffers addObject:[info.buffer sliceWithName:nil offset:info.loopStart size:info.loopEnd-info.loopStart]];
            }
        }
    }
    for (int i=0;i<[ratios count];i++ ) {
        [[ratios objectAtIndex:i] release];
    }
    [ratios release];
    ratios  = [[NSMutableArray alloc] initWithCapacity:127];
    
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
    userSettings = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 [NSNumber numberWithFloat:50],@"Slider Range",
                                 [NSNumber numberWithFloat:0],@"Key Switch Method",
                                 [NSNumber numberWithFloat:440],@"A Hertz",
                                 @"YamCF3",@"Default Instrument",
                                 nil];
    [userSettings registerDefaults:appDefaults];
    tuningOffset = 0;
#ifdef macroIsFree
    NSLog(@"free version");
#else
    NSLog(@"paid version");
#endif
    UIImage *patternImage = [UIImage imageNamed:@"diamond_upholstery.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:patternImage];
    //[self fractionFromFloat:0.263157894737];
    NSString *path = [[NSBundle mainBundle] pathForResource:[userSettings stringForKey:@"Default Instrument"] ofType:@"sound"];
    // Build the array from the plist  
    instrument = [[NSArray alloc] initWithContentsOfFile:path];
    
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
    
    buttons = [[NSArray alloc] initWithArray:[buttons sortedArrayUsingComparator:^NSComparisonResult(UISlider* obj1, UISlider* obj2) {
        /* obj1.transform = CGAffineTransformRotate(obj1.transform, 270.0/180*M_PI);
         obj2.transform = CGAffineTransformRotate(obj2.transform, 270.0/180*M_PI);*/
        if ([obj1 tag] < [obj2 tag]) return NSOrderedAscending;
        else if ([obj1 tag] > [obj2 tag]) return NSOrderedDescending;
        return NSOrderedSame;
    }]];
    
    for (int i=0;i<[buttons count];i++) {
        [[buttons objectAtIndex:i] addTarget:self action:@selector(buttonReleased:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
    }
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

    [self initPitches];
    [self initBuffers];
    currentOctave = 0;
    playing = false;
    stopped = false;
    paused = false;
    recordTimer = -1;
    recording = false;
    recordedNotes = [[NSMutableArray alloc] init];
    parser = [[MidiParser alloc] init];
    saving = false;
    loadingScale = false;
    changingPitch = false;
    loadingInstrument = false;
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
        [tempSlot setTitle:@"Press and hold\nto grab current\nscale" forState: UIControlStateHighlighted];
        tempSlot.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];
        tempSlot.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        tempSlot.titleLabel.textAlignment = UITextAlignmentCenter;
    }
    
    instrumentButton.titleLabel.textAlignment = UITextAlignmentCenter;
    publishButton.titleLabel.textAlignment = UITextAlignmentCenter;

    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    // Set the background for any states you plan to use
    // Add gesture recognizer to the view
    for (int i=0;i<[hotKeys count];i++) {
        pressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handlePress:)]; // Absolutely need ":" after handleTaps
    
    // The number of fingers that must be on the screen
        pressRecognizer.minimumPressDuration = 0.8;
        UIButton * hotKey = [hotKeys objectAtIndex:i];
        
        [hotKey setTitle:@"Press and hold\nto load a scale" forState:UIControlStateNormal];
        [hotKey setTitle:@"Press and hold\nto load a scale" forState:UIControlStateHighlighted]; 
        hotKey.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];      
        hotKey.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        hotKey.titleLabel.textAlignment = UITextAlignmentCenter;
        [hotKey addGestureRecognizer:pressRecognizer];
        [hotKey setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [hotKey setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
        
    }
    NSArray *controlButtons = [NSArray arrayWithObjects: playButton, pauseButton, stopButton, loadButton, saveButton, recordButton, tempSlot0, tempSlot1,tempSlot2, instrumentButton,  nil];
    for (int i=0;i<[controlButtons count];i++) {
        UIButton *button = [controlButtons objectAtIndex:i];
        [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [button setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    }
    [playButton setBackgroundImage:buttonImage forState:UIControlStateDisabled];
    UISlider * rootSlider = [sliders objectAtIndex:currentScaleDegree];
    rootSlider.enabled = false;
}

- (IBAction)playTemp:(id)sender {
    UIButton * button = sender;
    if ([[tempScales objectAtIndex:button.tag] count] != 0) {
        for (int i=0;i<127;i++) {
            float lowPitch = [[[tempScales objectAtIndex:button.tag] objectAtIndex:i%12] floatValue];
            int octave = i/12;
            float newPitch = pow(2,octave)*lowPitch;
            [[pitches objectAtIndex:i] release];
            [pitches replaceObjectAtIndex:i withObject:[[NSNumber alloc] initWithFloat:newPitch]];
            if (octave == 0) {
                float ratio = newPitch/[[majorScale objectAtIndex:i] floatValue];
                float newValue = (log2f(ratio)*12+1)/2;
                UISlider *slider = [sliders objectAtIndex:i];
                [slider setValue:newValue animated:YES];
            }
        }
        [self initBuffers];
    }    
}
-(void)handleLabelPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UILabel *label= (UILabel *)sender.view;
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
    }
}

- (void) handlePress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        UIView *view = sender.view;
        if ([spc isPopoverVisible]) {
            [spc dismissPopoverAnimated:YES];
        }
        else {
            sac = nil;
            spc = nil;
            sac = [[LoadScaleController alloc] initWithNibName:@"LoadScaleController" bundle:nil];
            sac.delegate = self;
            sac.button = (UIButton *)sender.view;
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:sac];
            UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"All Scales",@"Standard Scales",@"User Scales",nil]];
            [segmentedControl addTarget:sac action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            //segmentedControl.frame = CGRectMake(0, 0, 320, 30);
            [segmentedControl setSelectedSegmentIndex:0];
            [segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
            segmentedControl.frame = CGRectMake(0.0f, 5.0f, 320.0f, 30.0f);
            
            UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
            
            NSArray *theToolbarItems = [NSArray arrayWithObjects:item, nil];
            [sac setToolbarItems:theToolbarItems];
            navController.toolbarHidden = NO;
            sac.title = @"Select A Scale";
            UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithTitle:@"Get more scales" style:UIBarButtonItemStylePlain target:self action:@selector(getMoreScales)];
            [sac.navigationItem setRightBarButtonItem:moreButton];
            //[sac setToolbarItems:theToolbarItems];
            spc = [[UIPopoverController alloc] initWithContentViewController:navController];
            //[spc.contentViewController setToolbarItems:theToolbarItems];
            //[navController.navigationBar.topItem setTitleView:segmentedControl];
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
    float sliderRange = [userSettings floatForKey:@"Slider Range"];
    float sliderMin = 0.5-(sliderRange/200);
    float sliderMax = 0.5+(sliderRange/200);
    for (int i=0;i<[sliders count];i++) {
        UISlider * slider = [sliders objectAtIndex:i];
        [slider setMinimumValue:sliderMin];
        [slider setMaximumValue:sliderMax];
    }
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

-(void)finishFade:(ALSource *)source {
    [source stop];
}

- (void) noteOff:(int)noteValue {
    if (noteValue>=0 && noteValue<127) {
        ALSource * source = [sources objectAtIndex:noteValue];
        ALSource *loopSource = [loopSources objectAtIndex:noteValue];
        if (source.playing || loopSource.playing) {
            [[fadingOut objectAtIndex:noteValue] release];
            [fadingOut replaceObjectAtIndex:noteValue withObject:[[NSNumber alloc] initWithBool:YES]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                float timeDone = 0;
                float duration = 0.2;
                float timeStep = 0.0001;
                float valStep = source.gain*timeStep/duration;
                float loopStep = loopSource.gain*timeStep/duration;
                while (timeDone < duration) {
                    if (![[fadingOut objectAtIndex:noteValue] boolValue]) break;
                    source.gain -= valStep;
                    loopSource.gain -= loopStep;
                    [NSThread sleepForTimeInterval:timeStep];
                    timeDone += timeStep;
                }
                if ([[fadingOut objectAtIndex:noteValue] boolValue]) {
                    [source stop];
                    [loopSource stop];
                }
                //source.gain = 1;
            });
            
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
}

- (void) finishFadeIn:(ALSource*)source {
    
}

- (void) noteOn:(int)noteValue withVelocity:(int)velocity {
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
        while(loadingScale || changingPitch);
        float pitchToPlay = [[ratios objectAtIndex:noteValue] floatValue];
        [[fadingOut objectAtIndex:noteValue] release];
        [fadingOut replaceObjectAtIndex:noteValue withObject:[[NSNumber alloc] initWithBool:NO]];
        ALSource * source = [sources objectAtIndex:noteValue];
        [source stop];
        source.gain = velocity/127.0f;
        source.pitch = pitchToPlay;
        [source play:[buffers objectAtIndex:noteValue]];
        if ([loopBuffers objectAtIndex:noteValue] != (id)[NSNull null]) {
            ALSource *loopSource = [loopSources objectAtIndex:noteValue];
            [loopSource stop];
            loopSource.gain = 0;
            loopSource.pitch = source.pitch;
            [loopSource play:[loopBuffers objectAtIndex:noteValue] loop:YES];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                float timeDone = 0;
                float duration = [(ALBuffer*)[buffers objectAtIndex:noteValue] duration]-.4;
                float timeStep = 0.0001;
                float valStep = source.gain*timeStep/duration;
                float loopStep = valStep;
                while (timeDone < duration) {
                    if ([[fadingOut objectAtIndex:noteValue] boolValue]) break;
                    source.gain -= valStep;
                    loopSource.gain += loopStep;
                    [NSThread sleepForTimeInterval:timeStep];
                    timeDone += timeStep;
                }
                /*if ([[fadingOut objectAtIndex:noteValue] boolValue]) {
                    [source stop];
                    [loopSource stop];
                }*/
                //source.gain = 1;
            });
        }
        /*
        [source play];*/
        //[[sources objectAtIndex:noteValue] play:toPlay gain:velocity/127.0f pitch:pitchToPlay pan:0.0f loop:FALSE];
    }
}

- (IBAction) buttonTriggered:(id)sender {
    UIButton *button = (UIButton *)sender;
    int midiNote = 60+button.tag+12*currentOctave;
    [self noteOn:midiNote withVelocity:127];
}

- (IBAction)buttonReleased:(id)sender {
    UIButton *button = (UIButton *)sender;
    int midiNote = 60+button.tag+12*currentOctave;
    [self noteOff:midiNote];
}

- (IBAction)sliderChanged:(id)sender withPrecision:(bool)precision 
{
    changingPitch = true;
    UISlider *slider = (UISlider *)sender;
    if (!precision) {
        slider.value = round(slider.value/.005)*.005;
    }
    float newRatio = powf(2.0f,(slider.value*2-1)/12);
    float newPitch = newRatio*[[majorScale objectAtIndex:slider.tag] floatValue];
    [self changeNote:slider.tag to:newPitch];
    UILabel * label = [frequencyLabels objectAtIndex:slider.tag];
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
    //[label setText:[self fractionFromFloat:displayRatio]]
    changingPitch = false;
}

- (IBAction) sliderChanged:(id)sender {
    return [self sliderChanged:sender withPrecision:false];
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
                    [self noteOn:packet->data[1] withVelocity:packet->data[2]];
                } else {
                    [self noteOff:packet->data[1]];
                }
            } else if ((packet->data[0]&0xF0) == 0x80) {
                [self noteOff:packet->data[1]];
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

-(void) stopAllNotes {
    for (int i=0;i<127;i++) {
        [self noteOff:i];
    }
}


-(void)stopMidi:(id)sender{
    stopped = true;
    paused = false;
    if (recording) {
        [self stopRecording];
    }
    playButton.enabled = true;
    [self stopAllNotes];
}

-(void)pauseMidi:(id)sender {
    paused = true;
    playButton.enabled = true;
    [self stopAllNotes];
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
                while (paused || loadingScale || changingPitch || loadingInstrument);
                if (stopped) break;
                NoteObject *currentNote = [events objectAtIndex:i];
                if (i==0) {
                    currentNote.time = 0;
                }
                [NSThread sleepForTimeInterval:(currentNote.time/ticksPerSecond)];
                while (paused || loadingScale || changingPitch || loadingInstrument);
                if (stopped) break;
                if (currentNote.noteOn) {
                    [self noteOn:currentNote.note withVelocity:currentNote.velocity];
                } else {
                    [self noteOff:currentNote.note];
                }
            } 
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

- (void) closeLoadMidi {
    [ac dismissModalViewControllerAnimated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if (title == @"Continue Without Saving") {
        //[pc presentPopoverFromRect:[loadMidiButton bounds] inView:loadMidiButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        ac.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        UINavigationController *navController = [[UINavigationController alloc]
                                                 initWithRootViewController:ac];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(closeLoadMidi)];
        [ac.navigationItem setRightBarButtonItem:backButton];
        ac.title = @"Load a midi file";
        [self presentModalViewController:navController animated:YES];
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
            //ac.delegate = self;
            ac.delegate = self;
            ac.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            UINavigationController *navController = [[UINavigationController alloc]
                                                     initWithRootViewController:ac];
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
            UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(closeLoadMidi)];
            [ac.navigationItem setRightBarButtonItem:backButton];
            ac.title = @"Load a midi file";
            [self presentModalViewController:navController animated:YES];
        }
    } else if (title == @"Save Scale" ) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *file = [documentsDirectory stringByAppendingPathComponent:[[[alertView textFieldAtIndex:0] text] stringByAppendingPathExtension:@"scale"]];
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
    UIButton *button = scaleController.button;
    [button setTitle:selection forState:UIControlStateNormal]; 
    [button setTitle:selection forState:UIControlStateHighlighted];
    [[hotScales objectAtIndex:button.tag] release];
    [hotScales replaceObjectAtIndex:button.tag withObject:[[NSMutableArray alloc] initWithArray:loadedScale copyItems:YES]];
    [spc dismissPopoverAnimated:YES];
    [loadedScale release];
}

- (void)LoadMidiController:(LoadMidiController *)midiController didFinishWithSelection:(NSString*)selection {
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
    [byteArray release];
    [midiController dismissModalViewControllerAnimated:YES];
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
            char midiEvent[3] = {0x90,(char)(currentNote.note)&0xff,0x7f}; 
            [data appendBytes:&midiEvent length:3];

        } else {
            char midiEvent[3] = {0x80,(char)(currentNote.note)&0xff,0x00}; 
            [data appendBytes:&midiEvent length:3];
        
        }
    }
    
    [data writeToFile:writeFile atomically:YES];
}

-(IBAction)changeRootNote:(id)sender {
    if (!loadingScale) {
        loadingScale = true;
        UISlider * rootSlider = [sliders objectAtIndex:currentScaleDegree];
        rootSlider.enabled = true;
        UISegmentedControl * segmented = sender;
        currentScaleDegree = segmented.selectedSegmentIndex;
        rootSlider = [sliders objectAtIndex:currentScaleDegree];
        rootSlider.enabled = false;
        float baseNote;
        switch ([userSettings integerForKey:@"Key Switch Method"]) {
            case 0:
                baseNote = [[majorScale objectAtIndex:currentScaleDegree] floatValue];
                break;
            case 1:
                baseNote = [[pitches objectAtIndex:currentScaleDegree] floatValue];
                break;
            case 2:
                baseNote = ([userSettings floatForKey:@"A Hertz"]/[[scaleRatios objectAtIndex:(21-currentScaleDegree)%12] floatValue])/(1<<5);
                break;
        }
        tuningOffset = log2f(baseNote/[[majorScale objectAtIndex:currentScaleDegree] floatValue])*1200;
        for (int i = 0;i<127;i++) {
            float lowPitch = [[scaleRatios objectAtIndex:(i-currentScaleDegree+12)%12] floatValue]*baseNote;
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
    NSMutableArray *newScale = [hotScales objectAtIndex:button.tag];
    loadingScale = true;
    //[buffers release];
    if ([newScale count] != 0) {
        for (int i=0;i<127;i++) {
            float lowPitch = [[newScale objectAtIndex:i%12] floatValue];
            int octave = i/12;
            float newPitch = pow(2,octave)*lowPitch;
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
    }
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

-(void)SetNoteController:(SetNoteController *)setNoteController didFinishWithFrequency:(float)frequency forDegree:(int)degree
{
    [self changeNote:degree to:frequency/(1<<5)];
    [notePopover dismissPopoverAnimated:YES];
    UISlider *slider = [sliders objectAtIndex:degree];
    float ratio = frequency/[[majorScale objectAtIndex:degree+60] floatValue];
    float newValue = (log2f(ratio)*12+1)/2;
    [slider setValue:newValue animated:YES];
    [self sliderChanged:slider withPrecision:YES];
}

-(void)InstrumentController:(InstrumentController *)instrumentController didFinishWithSelection:(NSString *)selection {
    loadingInstrument = true;
    NSString *path = [[NSBundle mainBundle] pathForResource:selection ofType:@"sound"];
    instrument = [[NSArray alloc] initWithContentsOfFile:path];
    [self initBuffers];
    [instrumentController dismissModalViewControllerAnimated:YES];
    loadingInstrument = false;
}

-(IBAction)showInfo:(id)sender {
    infoViewController = [[InfoController alloc] initWithNibName:@"InfoController" bundle:nil];
    infoViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    //infoViewController.userSettings = userSettings;
    //infoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    //navigationController.navigationItem;
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:infoViewController];
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    infoViewController.title = @"Settings and Info";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:infoViewController action:@selector(cancel)];
    [infoViewController.navigationItem setRightBarButtonItem:backButton];
    UIBarButtonItem *settingsSaveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:infoViewController action:@selector(save)];
    [infoViewController.navigationItem setLeftBarButtonItem:settingsSaveButton];
    [self presentModalViewController:navController animated:YES];
}

-(IBAction)selectInstrument:(id)sender {
    instrumentViewController = [[InstrumentController alloc] initWithNibName:@"InstrumentController" bundle:nil];
    instrumentViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    instrumentViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    instrumentViewController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc]
                                             initWithRootViewController:instrumentViewController];
    
    //navController.navigationItem.title = @"Select an instrument";
    //[instrumentViewController setTitle:@"Select an instrument"];
  
    //navController.navigationItem.backBarButtonItem = backButton;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:navController animated:YES];
    
}

-(IBAction)publishScale:(id)sender {
    PublishScaleController *publishController = [[PublishScaleController alloc] initWithNibName:@"PublishScaleController" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:publishController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:navController animated:YES];
}


-(void) getMoreScales {
    if ([spc isPopoverVisible]) {
        [spc dismissPopoverAnimated:YES];
        MoreScalesController * moreViewController = [[MoreScalesController alloc] initWithNibName:@"MoreScalesController" bundle:nil];
        moreViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        moreViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:moreViewController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentModalViewController:navController animated:YES];
    }
}

- (void)LoadScaleController:(LoadScaleController *)scaleController didPublishAScaleWithName:(NSString *)scaleName {
    if ([spc isPopoverVisible]) {
        [spc dismissPopoverAnimated:YES];
        PublishScaleController *publishController = [[PublishScaleController alloc] initWithNibName:@"PublishScaleController" bundle:nil];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:publishController];
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        PublishScaleDetailController *publishDetailController = [[PublishScaleDetailController alloc] initWithNibName:@"PublishScaleDetailController" bundle:nil];
        publishDetailController.modalPresentationStyle = UIModalPresentationFormSheet;
        publishDetailController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        navController.modalPresentationStyle = UIModalPresentationFormSheet;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        publishDetailController.scaleToSend = [[NSArray alloc] initWithContentsOfFile:[NSBundle pathForResource:scaleName ofType:@"scale" inDirectory:documentsDirectory]];
        publishDetailController.scaleName = scaleName;
        [navController pushViewController:publishDetailController animated:NO];
        [self presentModalViewController:navController animated:YES];

    }
}



@end
