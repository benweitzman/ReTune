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
#import "SetNoteController.h"
#import "InfoController.h"
#import "InstrumentController.h"

@class PGMidi;

typedef struct {
    __unsafe_unretained NSString* filename;
    float pitch;
} File;

typedef struct {
    __unsafe_unretained ALBuffer* buffer;
    float scale;
    bool loop;
    int loopStart;
    int loopEnd;
} bufferInfo;


@interface ViewController : UIViewController <UIScrollViewDelegate, UITabBarDelegate>
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
    bool loadingScale, changingPitch, loadingInstrument;
    int currentScaleDegree;
    NSMutableArray *scaleRatios;
    NSMutableArray *sources, *fadingOut, *loopSources;
    NSArray *instrument;
    NSUserDefaults *userSettings;
    float tuningOffset;
    NSMutableDictionary *bufferFiles;
    int currentPage;
    bool keyboardLocked;
    bool tabBarSelect;
}
@property (strong) NSMutableArray* pitches;
@property (strong) NSMutableArray* ratios;
@property (strong) NSMutableArray* majorScale;
@property (strong) NSMutableArray* buffers, *loopBuffers;
@property (strong) NSArray* soundFiles;
@property (strong) NSMutableArray* recordedNotes;
@property (strong) NSMutableArray* scaleRatios;

@property (strong, nonatomic) IBOutlet UIButton *loadMidiButton;
@property (strong, nonatomic) LoadMidiController *ac;
@property (strong, nonatomic) LoadScaleController *sac;
@property (strong, nonatomic) SetNoteController *noteViewController;
@property (strong, nonatomic) InfoController *infoViewController;
@property (strong, nonatomic) InstrumentController *instrumentViewController;
@property (strong, nonatomic) UIPopoverController *pc, *spc, *notePopover;

@property (nonatomic,strong) IBOutlet UIButton    *playButton, *pauseButton, *stopButton, *recordButton, *loadButton, *saveButton;
@property (nonatomic, retain) UILongPressGestureRecognizer * pressRecognizer;
@property (nonatomic, retain) UITapGestureRecognizer *tapRecognizer;

@property (nonatomic,strong) IBOutlet UIButton *hotKey0,*hotKey1,*hotKey2,*hotKey3,*hotKey4,*hotKey5,*hotKey6,*hotKey7,*hotKey8,*hotKey9,*hotKey10,*hotKey11,*tempSlot0,*tempSlot1,*tempSlot2;

@property (nonatomic, strong) IBOutlet UIButton *instrumentButton, *publishButton;

@property (nonatomic, strong) IBOutlet UISegmentedControl *rootNote;

@property (nonatomic, retain) IBOutletCollection(UISlider) NSArray* sliders;
@property (nonatomic, retain) IBOutletCollection(UILabel) NSArray* frequencyLabels;
@property (nonatomic, retain) IBOutletCollection(UILabel) NSArray* centsLabels, *ratioLabels;
@property (nonatomic, retain) IBOutletCollection(UIButton) NSArray* buttons;
@property (nonatomic, retain) IBOutletCollection(UIView) NSArray* subViews;

@property (nonatomic, strong) NSMutableArray *hotKeys,*tempSlots,*tempScales,*hotScales;

@property (strong, nonatomic) IBOutlet UIScrollView *pageScroller;

@property (strong, nonatomic) IBOutlet UITabBar *tabBar;

@property (nonatomic,strong) PGMidi *midi;
-(IBAction)buttonTriggered:(id)sender;
-(IBAction)buttonReleased:(id)sender;
-(IBAction)sliderChanged:(id)sender;
-(IBAction)sliderChanged:(id)sender withPrecision:(bool)precision;
-(IBAction)stopMidi:(id)sender;
-(IBAction)playMidi:(id)sender;
-(IBAction)pauseMidi:(id)sender;
-(IBAction)recordMidi:(id)sender;
-(IBAction)loadMidi:(id)sender;
-(IBAction)saveMidi:(id)sender;
-(IBAction)loadScale:(id)sender;
-(IBAction)playTemp:(id)sender;
-(IBAction)changeRootNote:(id)sender;
-(IBAction)showInfo:(id)sender;
-(IBAction)selectInstrument:(id)sender;
-(IBAction)publishScale:(id)sender;
-(void)noteOn:(int)noteValue withVelocity:(int)velocity;
-(void)finishFade:(ALSource *)source; 
-(void)writeNotesToFile:(NSString *)file;
-(void)getMoreScales;

-(void)handleTempPress:(UILongPressGestureRecognizer *)sender;
-(void)handleLabelPress:(UILongPressGestureRecognizer *)sender;



@end
