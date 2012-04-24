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
}
@property (strong) NSMutableArray* pitches;
@property (strong) NSMutableArray* ratios;
@property (strong) NSMutableArray* majorScale;
@property (strong) NSMutableArray* buffers;
@property (strong) NSArray* soundFiles;
@property (nonatomic,strong) PGMidi *midi;
-(IBAction)buttonTriggered:(id)sender;
-(void)noteOn:(int)noteValue;


@end
