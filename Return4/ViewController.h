//
//  ViewController.h
//  Return4
//
//  Created by Ben Weitzman on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjectAL.h"
#import <Foundation/Foundation.h>
#import "MidiParser.h"
#import "LoadMidiController.h"
#import "LoadScaleController.h"

@class PGMidi;

typedef struct {
    __unsafe_unretained NSString* filename;
    float pitch;
} File;

typedef struct {
    __unsafe_unretained ALBuffer* buffer;
    float scale;
} bufferInfo;


@interface ViewController : UIViewController
{
    ALDevice* device;
    ALContext* context;
    ALChannelSource* channel;
    NSMutableArray *channels;
    int currentOctave;
    //ALSource* source;
	//ALBuffer* buffer;
     PGMidi *midi;
    MidiParser *parser;
    double recordTimer;
    bool saving;
    bool playing, stopped, paused, recording;
    NSMutableArray *scaleToSave;
}
@property (strong) NSMutableArray* pitches;
@property (strong) NSMutableArray* ratios;
@property (strong) NSMutableArray* majorScale;
@property (strong) NSMutableArray* buffers;
@property (strong) NSArray* soundFiles;
@property (strong) NSMutableArray* recordedNotes;

@property (strong, nonatomic) IBOutlet UIButton *loadMidiButton;
@property (strong, nonatomic) LoadMidiController *ac;
@property (strong, nonatomic) LoadScaleController *sac;
@property (strong, nonatomic) UIPopoverController *pc, *spc;

@property (nonatomic,strong) IBOutlet UIButton    *playButton;
@property (nonatomic, retain) UILongPressGestureRecognizer * pressRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic,strong) IBOutlet UIButton *hotKey0,*hotKey1,*hotKey2,*hotKey3,*hotKey4,*hotKey5,*hotKey6,*hotKey7,*hotKey8,*hotKey9,*hotKey10,*hotKey11,*tempSlot0,*tempSlot1,*tempSlot2;

@property (nonatomic, retain) IBOutletCollection(UISlider) NSArray* sliders;
@property (nonatomic, retain) IBOutletCollection(UILabel) NSArray* frequencyLabels;

@property (nonatomic, strong) NSMutableArray *hotKeys,*tempSlots,*tempScales,*hotScales;


@property (nonatomic,strong) PGMidi *midi;
-(IBAction)buttonTriggered:(id)sender;
-(IBAction)stopMidi:(id)sender;
-(IBAction)playMidi:(id)sender;
-(IBAction)pauseMidi:(id)sender;
-(IBAction)recordMidi:(id)sender;
-(IBAction)loadMidi:(id)sender;
-(IBAction)saveMidi:(id)sender;
-(IBAction)loadScale:(id)sender;
-(IBAction)playTemp:(id)sender;
-(void)noteOn:(int)noteValue;

-(void)writeNotesToFile:(NSString *)file;

-(void)handleTempPress:(UILongPressGestureRecognizer *)sender;



@end
