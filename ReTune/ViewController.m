//
//  ViewController.m
//  ReTune
//
//  Created by Ben Weitzman on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
@synthesize buffers, pitches, ratios, soundFiles, majorScale;

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
    toReturn.buffer = [[[OpenALManager sharedInstance] 
                          bufferFromFile:minFileName] retain];
    toReturn.scale = minRatio;
    return toReturn;
}

- (void) initSoundFiles {
    soundFiles = [[NSArray alloc] initWithObjects:
                  [NSValue value:&(File){@"P200 Piano A#2.caf",116.541} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#3.caf",233.082} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#4.caf",466.164} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#5.caf",932.328} withObjCType:@encode(File)],
                  [NSValue value:&(File){@"P200 Piano A#7.caf",1864.66} withObjCType:@encode(File)],
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
    bufferInfo info = [self bufferFromPitch:pitch];
    [pitches replaceObjectAtIndex:degree withObject:[NSNumber numberWithFloat:pitch]];
    [ratios replaceObjectAtIndex:degree withObject:[[NSNumber alloc] initWithFloat:info.scale]];
    [buffers replaceObjectAtIndex:degree withObject:info.buffer];
}

- (void) initBuffers {
    buffers = [[NSMutableArray alloc] init];
    ratios  = [[NSMutableArray alloc] init];
    pitches = [[NSMutableArray alloc] init];
    for (int i=0;i<24;i++) {
        [pitches addObject:[NSNumber numberWithFloat:powf(2.0f,(i-9.0f)/12)*440]];
    }
    for (int i=0;i<[pitches count];i++) {
        bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:i] floatValue]];
        [buffers addObject:info.buffer];
        [ratios addObject:[[NSNumber alloc] initWithFloat:info.scale]];
    }
    majorScale = [[NSMutableArray alloc] initWithArray:pitches copyItems:YES];
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
    device = [[ALDevice deviceWithDeviceSpecifier:nil] retain];
    context = [[ALContext contextOnDevice:device attributes:nil] retain];
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
    channel = [[ALChannelSource channelWithSources:32] retain];
    [self initSoundFiles];
    [self initBuffers];
    currentOctave = 50;
	// Do any additional setup after loading the view, typically from a nib.
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
    return YES;
}

- (IBAction) buttonTriggered:(id)sender {
    //NSLog(buffers);
    UIButton *button = (UIButton *)sender;
    //ALBuffer* lebuf = (ALBuffer *)[buffers objectsAtIndex:1];
    float pitchToPlay = [[ratios objectAtIndex:button.tag] floatValue];
    [channel play:[[self buffers] objectAtIndex:button.tag] gain:1.0f pitch:pitchToPlay pan:0.0f loop:FALSE];
}

- (IBAction) sliderChanged:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float newRatio = powf(2.0f,(slider.value*2-1)/12);
    NSLog(@"new ratio: %f", newRatio);
    NSLog(@"major scale %f",[[majorScale objectAtIndex:slider.tag] floatValue]);
    float newPitch = newRatio*[[majorScale objectAtIndex:slider.tag] floatValue];
    NSLog(@"new pitch for degree %u: %f",slider.tag,newPitch);
    [self changeNote:slider.tag to:newPitch];
    if (slider.tag+12 < [pitches count]) {
        [self changeNote:slider.tag+12 to:newPitch*2];
    }
}

- (IBAction) octaveChanged:(id)sender {
    UIStepper *stepper = (UIStepper *)sender;
    for (int i=0;i<[pitches count];i++) {
        [self changeNote:i to:[[pitches objectAtIndex:i] floatValue]*powf(2.0,(stepper.value-currentOctave))];  
    }
    currentOctave = stepper.value;
}

@end
