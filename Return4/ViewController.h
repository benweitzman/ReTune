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
    int currentOctave;
    //ALSource* source;
	//ALBuffer* buffer;
     PGMidi *midi;
    MidiParser *parser;
    double recordTimer;
    bool playing, stopped, paused, recording;
}
@property (strong) NSMutableArray* pitches;
@property (strong) NSMutableArray* ratios;
@property (strong) NSMutableArray* majorScale;
@property (strong) NSMutableArray* buffers;
@property (strong) NSArray* soundFiles;
@property (strong) NSMutableArray* recordedNotes;

@property (strong, nonatomic) IBOutlet UIButton *loadMidiButton;
@property (strong, nonatomic) LoadMidiController *ac;
@property (strong, nonatomic) UIPopoverController *pc;

@property (nonatomic,strong) IBOutlet UIButton    *playButton;


@property (nonatomic,strong) PGMidi *midi;
-(IBAction)buttonTriggered:(id)sender;
-(IBAction)stopMidi:(id)sender;
-(IBAction)playMidi:(id)sender;
-(IBAction)pauseMidi:(id)sender;
-(IBAction)recordMidi:(id)sender;
-(IBAction)loadMidi:(id)sender;
-(void)noteOn:(int)noteValue;


@end
