//
//  MidiParser.m
//  Return4
//
//  Created by Ben Weitzman on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MidiParser.h"

#define kFileCorrupt @"File is corrupt"
#define kInvalidHeader @"Invalid MIDI header"
#define kInvalidTrackHeader @"Invalid Track header"

#define MAIN_HEADER_SIZE 6

#define META_SEQUENCE_NUMBER    0x0
#define META_TEXT_EVENT         0x1
#define META_COPYRIGHT_NOTICE   0x2
#define META_TRACK_NAME         0x3
#define META_INSTRUMENT_NAME    0x4
#define META_LYRICS             0x5
#define META_MARKER             0x6
#define META_CUE_POINT          0x7
#define META_CHANNEL_PREFIX     0x20
#define META_END_OF_TRACK       0x2f
#define META_SET_TEMPO          0x51
#define META_SMPTE_OFFSET       0x54
#define META_TIME_SIGNATURE     0x58
#define META_KEY_SIGNATURE      0x59
#define META_SEQ_SPECIFIC       0x7f

#define CHANNEL_NOTE_OFF        0x8
#define CHANNEL_NOTE_ON         0x9
#define CHANNEL_NOTE_AFTERTOUCH 0xA
#define CHANNEL_CONTROLLER      0xB
#define CHANNEL_PROGRAM_CHANGE  0xC
#define CHANNEL_AFTERTOUCH      0xD
#define CHANNEL_PITCH_BEND      0xE

#define MICRO_PER_MINUTE        60000000

@implementation NoteObject

@synthesize time, note, noteOn;

@end

@implementation MidiParser

@synthesize log,events;

@synthesize format;
@synthesize trackCount;
@synthesize timeFormat;
@synthesize ticksPerSecond;
@synthesize bpm;


- (UInt32) readDWord
{
    UInt32 value = 0;
    [data getBytes:&value range:NSMakeRange(offset, sizeof(value))];
    value = CFSwapInt32BigToHost(value);
    offset += sizeof(value);
    return value;
}

- (UInt16) readWord
{
    UInt16 value = 0;
    [data getBytes:&value range:NSMakeRange(offset, sizeof(value))];
    value = CFSwapInt16BigToHost(value);
    offset += sizeof(value);
    return value;
}

- (UInt8) readByte
{
    UInt8 value = 0;
    [data getBytes:&value range:NSMakeRange(offset, sizeof(value))];
    offset += sizeof(value);
    return value;
}

- (UInt8) readByteAtRelativeOffset: (UInt32) o
{
    UInt8 value = 0;
    [data getBytes:&value range:NSMakeRange(offset + o, sizeof(value))];
    return value;
}

- (UInt32) readVariableValue
{
    UInt32 value = 0;
    
    UInt8 byte;
    UInt8 shift = 0;
    do 
    {
        value <<= shift;
        [data getBytes:&byte range:NSMakeRange(offset, 1)];
        offset++;
        value |= (byte & 0x7f);
        shift = 7;
    } while ((byte & 0x80) != 0);
    
    return value;
}

- (NSString *) readString: (int) length
{
    char *buffer = malloc(length + 1);
    memcpy(buffer, ([data bytes] + offset), length);
    buffer[length] = 0x0;
    NSString *string = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    free(buffer);
    return string;
}

- (void) readMetaSequence
{
    UInt32 sequenceNumber = 0;
    sequenceNumber |= [self readByteAtRelativeOffset:0];
    sequenceNumber <<= 8;
    sequenceNumber |= [self readByteAtRelativeOffset:1];
    [self.log appendFormat:@"Meta Sequence Number: %d\n", sequenceNumber];
}

- (void) readMetaTextEvent: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Text: %@\n", text];
}

- (void) readMetaCopyrightNotice: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Copyright: %@\n", text];
}

- (void) readMetaTrackName: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Track Name: %@\n", text];
}

- (void) readMetaInstrumentName: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Instrument Name: %@\n", text];
}

- (void) readMetaLyrics: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Text: %@\n", text];
}

- (void) readMetaMarker: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Marker: %@\n", text];    
}

- (void) readMetaCuePoint: (UInt32) length
{
    NSString *text = [self readString:length];
    [self.log appendFormat:@"Meta Cue Point: %@\n", text];    
}

- (void) readMetaChannelPrefix
{
    UInt8 channel = [self readByteAtRelativeOffset:0];
    [self.log appendFormat:@"Meta Channel Prefix: %d\n", channel];
}

- (void) readMetaEndOfTrack
{
    [self.log appendFormat:@"Meta End of Track\n"];
}

- (void) readMetaSetTempo
{
    UInt32 microPerQuarter = 0;
    microPerQuarter |= [self readByteAtRelativeOffset:0];
    microPerQuarter <<= 8;
    microPerQuarter |= [self readByteAtRelativeOffset:1];
    microPerQuarter <<= 8;
    microPerQuarter |= [self readByteAtRelativeOffset:2];
    
    bpm = MICRO_PER_MINUTE / microPerQuarter;
    [self.log appendFormat:@"Meta Set Tempo: Micro Per Quarter: %d, Beats Per Minute: %d\n", microPerQuarter, bpm];
}

- (void) readMetaSMPTEOffset
{
    UInt8 byte = [self readByteAtRelativeOffset:0];
    UInt8 hour = byte & 0x1f;
    UInt8 rate = (byte & 0x60) >> 5;
    UInt8 fps = 0;
    switch(rate)
    {
        case 0: fps = 24; break;
        case 1: fps = 25; break;
        case 2: fps = 29; break;
        case 3: fps = 30; break;
        default: fps = 0; break;
    }
    UInt8 minutes = [self readByteAtRelativeOffset:1];
    UInt8 seconds = [self readByteAtRelativeOffset:2];
    UInt8 frame = [self readByteAtRelativeOffset:3];
    UInt8 subframe = [self readByteAtRelativeOffset:4];
    [self.log appendFormat:@"Meta SMPTE Offset (%d): %2d:%2d:%2d:%2d:%2d\n", fps, hour, minutes, seconds, frame, subframe];
}

- (void) readMetaTimeSignature
{
    UInt8 numerator = [self readByteAtRelativeOffset:0];
    UInt8 denominator = [self readByteAtRelativeOffset:1];
    UInt8 metro = [self readByteAtRelativeOffset:2];
    UInt8 thirty_seconds = [self readByteAtRelativeOffset:3];
    
    [self.log appendFormat:@"Meta Time Signature: %d/%.0f, Metronome: %d, 32nds: %d\n", numerator, powf(2, denominator), metro, thirty_seconds];
}

- (void) readMetaKeySignature
{
    UInt8 value = [self readByteAtRelativeOffset:0];
    UInt8 accidentals = value & 0x7f;
    BOOL sharps = YES;
    NSString *accidentalsType = nil;
    if((value & 0x80) != 0)
    {
        accidentalsType = [NSString stringWithString:@"Flats"];
        sharps = NO;
    }
    else
    {
        accidentalsType = [NSString stringWithString:@"Sharps"];
    }
    UInt8 scale = [self readByteAtRelativeOffset:1];
    NSString *scaleType = nil;
    if(scale == 0)
    {
        scaleType = [NSString stringWithString:@"Major"];
    }
    else
    {
        scaleType = [NSString stringWithString:@"Minor"];
    }
    [self.log appendFormat:@"Meta Key Signature: %d %@ Type: %@\n", accidentals, accidentalsType, scaleType];
}

- (void) readMetaSeqSpecific: (UInt32) length
{
    [self.log appendFormat:@"Meta Event Sequencer Specific: - Length: %d\n", length];
}

- (void) readNoteOff: (UInt8) channel parameter1: (UInt8) p1 parameter2: (UInt8) p2
{
    [self.log appendFormat:@"Note Off (Channel %d): %d, Velocity: %d\n", channel, p1, p2];
}

- (void) readNoteOn: (UInt8) channel parameter1: (UInt8) p1 parameter2: (UInt8) p2
{
    [self.log appendFormat:@"Note On (Channel %d): %d, Velocity: %d\n", channel, p1, p2];
}

- (void) readNoteAftertouch: (UInt8) channel parameter1: (UInt8) p1 parameter2: (UInt8) p2
{
    [self.log appendFormat:@"Note Aftertouch (Channel %d): %d, Amount: %d\n", channel, p1, p2];
}

- (void) readControllerEvent: (UInt8) channel parameter1: (UInt8) p1 parameter2: (UInt8) p2
{
    [self.log appendFormat:@"Controller (Channel %d): %d, Value: %d\n", channel, p1, p2];
}

- (void) readProgramChange: (UInt8) channel parameter1: (UInt8) p1
{
    [self.log appendFormat:@"Program Change (Channel %d): %d\n", channel, p1];
}

- (void) readChannelAftertouch: (UInt8) channel parameter1: (UInt8) p1
{
    [self.log appendFormat:@"Channel Aftertouch (Channel %d): %d\n", channel, p1];
}

- (void) readPitchBend: (UInt8) channel parameter1: (UInt8) p1 parameter2: (UInt8) p2
{
    UInt32 value = p1;
    value <<= 8;
    value |= p2;
    [self.log appendFormat:@"Pitch Bend (Channel %d): %d\n", channel, value];
}

- (BOOL) parseData:(NSData *)midiData
{
    BOOL success = YES;
    self.log = [[NSMutableString alloc] init];
    self.events = [[NSMutableArray alloc] init];
    @try 
    {
        // Parse data
        data = midiData;
        int currentTime = 0;
        int noteOnDelta = 0;
        bpm = 0;
        offset = 0;
        
        // If size is less than header size, then abort
        NSUInteger dataLength = [data length];
        NSLog(@"data length: %d",dataLength);
        if((offset + MAIN_HEADER_SIZE) > dataLength)
        {
            NSException *ex = [NSException exceptionWithName:kFileCorrupt 
                                                      reason:kFileCorrupt userInfo:nil];
            NSLog(@"ex a");
            @throw ex;
        }
        
        // Parse header
        if(memcmp([data bytes], "MThd", 4) != 0)
        {
            NSException *ex = [NSException exceptionWithName:kFileCorrupt  
                                                      reason:kInvalidHeader userInfo:nil];
               NSLog(@"ex b");
            @throw ex;
        }
        offset += 4;
        
        UInt32 chunkSize = [self readDWord];
        [self.log appendFormat:@"Header Chunk Size: %d\n", chunkSize];
        
        // Read format
        format = [self readWord];
        [self.log appendFormat:@"Format: %d\n", format];
        
        // Read track count
        trackCount = [self readWord];
        [self.log appendFormat:@"Tracks: %d\n", trackCount];
        
        // Read time format
        UInt16 timeDivision = [self readWord];
        if((timeDivision & 0x8000) == 0)
        {
            timeFormat = MidiTimeFormatTicksPerBeat;
            ticksPerBeat = timeDivision & 0x7fff;
            [self.log appendFormat:@"Time Format: %d Ticks Per Beat\n", ticksPerBeat];
        }
        else
        {
            timeFormat = MidiTimeFormatFramesPerSecond;
            framesPerSecond = (timeDivision & 0x7f00) >> 8;
            ticksPerFrame = (timeDivision & 0xff);
            [self.log appendFormat:@"Time Division: %d Frames Per Second, %d Ticks Per Frame\n", framesPerSecond, ticksPerFrame];
        }
        
        // Try to parse tracks
        UInt32 expectedTrackOffset = offset;
        for(UInt16 track = 0; track < trackCount; track++)
        {
            if(offset != expectedTrackOffset)
            {
                [self.log appendFormat:@"Track Offset Incorrect for Track %d - Offset: %d, Expected: %d", track, offset, expectedTrackOffset];
                offset = expectedTrackOffset;
            }
            
            // Parse track header
            if(memcmp([data bytes] + offset, "MTrk", 4) != 0)
            {
                NSException *ex = [NSException exceptionWithName:kFileCorrupt  
                                                          reason:kInvalidTrackHeader userInfo:nil];
                   NSLog(@"ex c");
                @throw ex;
            }
            offset += 4;
            
            UInt32 trackSize = [self readDWord];
            expectedTrackOffset = offset + trackSize;
            [self.log appendFormat:@"Track %d : %d bytes\n", track, trackSize];
            
            UInt32 trackEnd = offset + trackSize;
            UInt32 deltaTime;
            UInt8 nextByte = 0;
            UInt8 peekByte = 0;
            while(offset < trackEnd)
            {
                deltaTime = [self readVariableValue];
                currentTime += deltaTime;
                noteOnDelta += deltaTime;
                [self.log appendFormat:@"  (%05d): ", deltaTime];
                
                // Peak at next byte
                peekByte = [self readByteAtRelativeOffset:0];
                
                // If high bit not set, then assume running status
                if((peekByte & 0x80) != 0)
                {
                    nextByte = [self readByte];
                }
                
                // Meta event
                if(nextByte == 0xFF)
                {
                    UInt8 metaEventType = [self readByte];
                    UInt32 metaEventLength = [self readVariableValue];
                    switch (metaEventType) 
                    {
                        case META_SEQUENCE_NUMBER:
                            [self readMetaSequence];
                            break;
                            
                        case META_TEXT_EVENT:
                            [self readMetaTextEvent: metaEventLength];
                            break;
                            
                        case META_COPYRIGHT_NOTICE:
                            [self readMetaCopyrightNotice: metaEventLength];
                            break;
                            
                        case META_TRACK_NAME:
                            [self readMetaTrackName: metaEventLength];
                            break;
                            
                        case META_INSTRUMENT_NAME:
                            [self readMetaInstrumentName: metaEventLength];
                            break;
                            
                        case META_LYRICS:
                            [self readMetaLyrics: metaEventLength];
                            break;
                            
                        case META_MARKER:
                            [self readMetaMarker: metaEventLength];
                            break;
                            
                        case META_CUE_POINT:
                            [self readMetaCuePoint: metaEventLength];
                            break;
                            
                        case META_CHANNEL_PREFIX:
                            [self readMetaChannelPrefix];
                            break;
                            
                        case META_END_OF_TRACK:
                            [self readMetaEndOfTrack];
                            break;
                            
                        case META_SET_TEMPO:
                        {
                            if (bpm == 0) {
                                [self readMetaSetTempo];
                            }
                        }
                            break;
                            
                        case META_SMPTE_OFFSET:
                            [self readMetaSMPTEOffset];
                            break;
                            
                        case META_TIME_SIGNATURE:
                            [self readMetaTimeSignature];
                            break;
                            
                        case META_KEY_SIGNATURE:
                            [self readMetaKeySignature];
                            break;
                            
                        case META_SEQ_SPECIFIC:
                            [self readMetaSeqSpecific: metaEventLength];
                            break;
                            
                        default:
                            [self.log appendFormat:@"Meta Event Type: 0x%x, Length: %d\n", metaEventType, metaEventLength];
                            break;
                    }
                    
                    offset += metaEventLength;
                }
                else if(nextByte == 0xf0)
                {
                    // SysEx event
                    UInt32 sysExDataLength = [self readVariableValue];
                    [self.log appendFormat:@"SysEx Event - Length: %d\n", sysExDataLength];
                    offset += sysExDataLength;
                }
                else
                {
                    // Channel event
                    UInt8 eventType = (nextByte & 0xF0) >> 4;
                    UInt8 channel = (nextByte & 0xF);
                    UInt8 p1 = 0;
                    UInt8 p2 = 0;
                    
                    switch (eventType) 
                    {
                        case CHANNEL_NOTE_OFF:
                        {
                            p1 = [self readByte];
                            p2 = [self readByte];
                            if (channel != 9) {
                                NoteObject *new = [[NoteObject alloc] init];
                                new.time = noteOnDelta;
                                new.note = p1;
                                new.noteOn = false;
                                [events addObject:new];
                                noteOnDelta = 0;
                            }
                            [self readNoteOff: channel parameter1: p1 parameter2: p2];
                        }
                            break;
                            
                            
                        case CHANNEL_NOTE_ON:{
                            p1 = [self readByte];
                            p2 = [self readByte];
                            if (channel != 9) {
                                NoteObject *new = [[NoteObject alloc] init];
                                new.time = noteOnDelta;
                                new.note = p1;
                                if (p2 != 0) {
                                    new.noteOn = true;
                                } else {
                                    new.noteOn = false;
                                }
                                [events addObject:new];
                                noteOnDelta = 0;
                            }
                            [self readNoteOn:channel parameter1:p1 parameter2:p2];
                        }
                            break;
                            
                        case CHANNEL_NOTE_AFTERTOUCH:
                            p1 = [self readByte];
                            p2 = [self readByte];
                            [self readNoteAftertouch:channel parameter1:p1 parameter2:p2];
                            break;
                            
                        case CHANNEL_CONTROLLER:
                            p1 = [self readByte];
                            p2 = [self readByte];
                            [self readControllerEvent:channel parameter1:p1 parameter2:p2];
                            break;
                            
                        case CHANNEL_PROGRAM_CHANGE:
                            p1 = [self readByte];
                            [self readProgramChange:channel parameter1:p1];
                            break;
                            
                        case CHANNEL_AFTERTOUCH:
                            p1 = [self readByte];
                            [self readChannelAftertouch:channel parameter1:p1];
                            break;
                            
                        case CHANNEL_PITCH_BEND:
                            p1 = [self readByte];
                            p2 = [self readByte];
                            [self readPitchBend:channel parameter1:p1 parameter2:p2];
                            break;
                            
                        default:
                            break;
                    }
                    
                }
            }
        }
        
    }
    @catch (NSException *exception) 
    {
        success = NO;
        [self.log appendString:[exception reason]];
    }
    /*for (int i=0;i<[noteOns count];i++) {
        NoteObject *current = [noteOns objectAtIndex:i];
        NSLog(@"%d %d",current.time,current.note);
    }*/
    if (timeFormat == MidiTimeFormatFramesPerSecond) {
        ticksPerSecond = framesPerSecond*ticksPerFrame;
    } else {
        ticksPerSecond = ticksPerBeat*bpm/60;
    }
    NSLog(@"bpm: %d",bpm);
    NSLog(@"%@",log);
    return success;
}

@end