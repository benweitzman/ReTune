//
//  ViewController.h
//  ReTune
//
//  Created by Ben Weitzman on 3/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjectAL.h"
#import <Foundation/Foundation.h>

typedef struct {
    NSString* filename;
    float pitch;
} File;

typedef struct {
    ALBuffer* buffer;
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
}
@property (strong) NSMutableArray* pitches;
@property (strong) NSMutableArray* ratios;
@property (strong) NSMutableArray* majorScale;
@property (strong) NSMutableArray* buffers;
@property (strong) NSArray* soundFiles;
-(IBAction)buttonTriggered:(id)sender;

@end
