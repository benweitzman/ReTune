//
//  MidiParser.h
//  Return4
//
// By Michael McCloskey
// http://stackoverflow.com/questions/7193695/reading-midi-files-on-ios
// Modified by Ben Weitzman

#import <Foundation/Foundation.h>

typedef enum tagMidiTimeFormat
{
    MidiTimeFormatTicksPerBeat,
    MidiTimeFormatFramesPerSecond
} MidiTimeFormat;

@interface NoteObject : NSObject

@property (nonatomic) int time;
@property (nonatomic) int note;
@property (nonatomic) bool noteOn;
    
@end

@interface MidiParser : NSObject 
{
    NSMutableString *log;
    NSData *data;
    NSUInteger offset;
    
    UInt16 format;
    UInt16 trackCount;
    MidiTimeFormat timeFormat;
    
    UInt16 ticksPerBeat;
    UInt16 framesPerSecond;
    UInt16 ticksPerFrame;
    double ticksPerSecond;
    UInt32 bpm;
    
    NSMutableArray *events;
}

@property (nonatomic, strong) NSMutableString *log;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic) double ticksPerSecond;
@property (nonatomic) UInt32 bpm;


@property (readonly) UInt16 format;
@property (readonly) UInt16 trackCount;
@property (readonly) MidiTimeFormat timeFormat;

- (BOOL) parseData: (NSData *) midiData;

@end
