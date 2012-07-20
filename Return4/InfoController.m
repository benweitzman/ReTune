//
//  InfoController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfoController.h"

@implementation InfoController

@synthesize rangeLabel,rangeSlider;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *patternImage = [UIImage imageNamed:@"diamond_upholstery.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:patternImage];
    [rangeSlider addTarget:self action:@selector(rangeChanged:) forControlEvents:UIControlEventValueChanged];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    userSettings = [NSUserDefaults standardUserDefaults];
    rangeSlider.value = [userSettings floatForKey:@"Slider Range"];
    rangeLabel.text = [NSString stringWithFormat:@"%.f",[userSettings floatForKey:@"Slider Range"]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction) backButtonClick:(id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) cancel {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) save {
    [userSettings synchronize];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)rangeChanged:(id)sender {
    rangeSlider.value = roundf(rangeSlider.value);
    rangeLabel.text = [NSString stringWithFormat:@"%.f",rangeSlider.value];
    [userSettings setFloat:rangeSlider.value forKey:@"Slider Range"];
}

@end
