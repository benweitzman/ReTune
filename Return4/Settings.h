//
//  Settings.h
//  Retune4.3
//
//  Created by Ben Weitzman on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Settings : NSObject
{
    NSString *file;
}

@property(strong, retain) NSMutableDictionary * settings; 

-(id)initWithSettingsFile:(NSString *)filename;
- (void) save;

@end
