//
//  MoreScalesDetailController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 7/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoreScalesDetailController.h"

@implementation MoreScalesDetailController

@synthesize authorLabel, scaleNameLabel, descriptionView, scale;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void) viewDidAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    authorLabel.text = [scale objectForKey:@"authorName"];
    scaleNameLabel.text = [scale objectForKey:@"scaleName"];
    descriptionView.text = [scale objectForKey:@"description"];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

-(IBAction)downloadScale:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *scaleName = [scale objectForKey:@"scaleName"];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:[scaleName stringByAppendingPathExtension:@"scale"]];
    int version = 1;
    NSFileManager *fm = [NSFileManager defaultManager];
    while ([fm fileExistsAtPath:file]) {
        file = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ (%d).scale",scaleName,version]];
        version++;
    }
    [(NSArray*)[scale objectForKey:@"notes"] writeToFile:file atomically:YES];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        int scaleId = [[scale objectForKey:@"id"] intValue];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://retuneapp.com/download/%d/",scaleId]];
        NSData *data = [NSData dataWithContentsOfURL:url];
        (void) data;
    });
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self dismissModalViewControllerAnimated:YES];
}

@end
