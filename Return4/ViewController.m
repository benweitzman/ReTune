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
#import <CoreMIDI/CoreMIDI.h>

@interface ViewController () <PGMidiDelegate, PGMidiSourceDelegate>
- (void) addString:(NSString*)string;
@end


@implementation ViewController
@synthesize buffers, pitches, ratios, soundFiles, majorScale, midi;

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
    while (degree < 127) {
        bufferInfo info = [self bufferFromPitch:pitch];
        [pitches replaceObjectAtIndex:degree withObject:[NSNumber numberWithFloat:pitch]];
        [ratios replaceObjectAtIndex:degree withObject:[[NSNumber alloc] initWithFloat:info.scale]];
        [buffers replaceObjectAtIndex:degree withObject:info.buffer];
        pitch *= 2;
        degree += 12;
    }
}

- (void) initPitches {
    pitches = [[NSMutableArray alloc] init];
    for (int i=0;i<127;i++) {
        [pitches addObject:[NSNumber numberWithFloat:powf(2.0f,(i-69.0f)/12)*440]];
    }
}

- (void) initBuffers {
    buffers = [[NSMutableArray alloc] init];
    ratios  = [[NSMutableArray alloc] init];
    
    NSLog(@"A4: %f",[[pitches objectAtIndex:69] floatValue]);
    for (int i=0;i<127;i++) {
        if (i>=0 && i<127) {
            bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:i] floatValue]];
            [buffers addObject:info.buffer];
            [ratios addObject:[[NSNumber alloc] initWithFloat:info.scale]];
        } else {
            [buffers addObject:[NSNull null]];
            [ratios addObject:[NSNull null]];
        }
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
    channel = [[ALChannelSource alloc] initWithSources:32];
    [self initSoundFiles];
    [self initPitches];
    [self initBuffers];
    currentOctave = 0;
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource: @"Bass_sample2" ofType: @"mid"]];
	NSMutableArray * byteArray = [[NSMutableArray alloc] init];
    for (int i=0;i<[data length];i++) {
        NSRange range = NSMakeRange(i,1);
        char dataBuffer;
        [data getBytes:&dataBuffer range:range];
        [byteArray addObject:[[NSNumber alloc] initWithUnsignedInt:dataBuffer]];
    }
    MidiParser *parser = [[MidiParser alloc] init];
    [parser parseData:data];
    //NSLog(@"%@",[parser log]);
    NSMutableArray *noteOns = parser.noteOns;
    //int ticksPerSecond = [parser 
    for (int i=0;i<[noteOns count];i++) {
        NoteObject *currentNote = [noteOns objectAtIndex:i];
        [NSThread sleepForTimeInterval:(currentNote.time/480.0f)];
        [self noteOn:currentNote.note];
    }
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
    return YES;
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

- (void) noteOn:(int)noteValue {
    if (noteValue>=0 && noteValue<127) {
        //float pitch = [[pitches objectAtIndex:noteValue] floatValue];
        ALBuffer* toPlay = [[self buffers] objectAtIndex:noteValue];
        if (toPlay != [NSNull null]) {
            float pitchToPlay = [[ratios objectAtIndex:noteValue] floatValue];
            [channel play:toPlay gain:1.0f pitch:pitchToPlay pan:0.0f loop:FALSE];
        } else {
            bufferInfo info = [self bufferFromPitch:[[pitches objectAtIndex:noteValue] floatValue]];
            [buffers replaceObjectAtIndex:noteValue withObject:info.buffer];
            [ratios replaceObjectAtIndex:noteValue withObject:[[NSNumber alloc] initWithFloat:info.scale]];
            [channel play:info.buffer gain:1.0f pitch:info.scale pan:0.0f loop:FALSE];
        }
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
    UISlider *slider = (UISlider *)sender;
    float newRatio = powf(2.0f,(slider.value*2-1)/12);
    NSLog(@"new ratio: %f", newRatio);
    NSLog(@"major scale %f",[[majorScale objectAtIndex:slider.tag] floatValue]);
    float newPitch = newRatio*[[majorScale objectAtIndex:slider.tag] floatValue];
    NSLog(@"new pitch for degree %u: %f",slider.tag,newPitch);
    [self changeNote:slider.tag to:newPitch];
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
                [self noteOn:packet->data[1]];
                
            }
        }
        packet = MIDIPacketNext(packet);
    }
}


@end
