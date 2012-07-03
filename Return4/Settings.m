//
//  Settings.m
//  Retune4.3
//
//  Created by Ben Weitzman on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Settings.h"

@implementation Settings

@synthesize settings;

-(id)initWithSettingsFile:(NSString *)filename;
{
	self = [super init];
	if (!self)
		return nil;
    
    self.settings = [[NSMutableDictionary alloc] initWithContentsOfFile:filename];
    file = [[NSString alloc] initWithString:filename];
	return self;
}

- (void) save {
    [settings writeToFile:file atomically:YES];
}

@end
