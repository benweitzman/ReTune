//
//  InfoController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InfoController.h"
#import <QuartzCore/QuartzCore.h>

@implementation CustomScroller

- (BOOL) touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view {
    return YES;
    if ([view isKindOfClass:[UISlider class]]) return YES;
    return NO;
}

@end

@implementation InfoController
@synthesize pageScroller;
@synthesize tabBar;
@synthesize subViews;

@synthesize rangeLabel,rangeSlider, hertzLabel, hertzSlider, methodControl, instrumentsTable;

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
    [methodControl addTarget:self action:@selector(methodChanged:) forControlEvents:UIControlEventValueChanged];
    [hertzSlider addTarget:self action:@selector(hertzChanged:) forControlEvents:UIControlEventValueChanged];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Instruments" ofType:@"plist"];
    instrumentList = [[NSDictionary alloc] initWithContentsOfFile:path];
    [instrumentsTable.layer setCornerRadius:7.0f];
    [instrumentsTable.layer setBorderColor:[UIColor grayColor].CGColor];
    [instrumentsTable.layer setBorderWidth:1];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
        subViews = [[NSArray alloc] initWithArray:[subViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 tag] < [obj2 tag]) return NSOrderedAscending;
            else if ([obj1 tag] > [obj2 tag]) return NSOrderedDescending;
            return NSOrderedSame;
        }]];
        pageScroller.pagingEnabled = YES;
        pageScroller.contentSize = CGSizeMake(pageScroller.frame.size.width * [subViews count], pageScroller.frame.size.height);
        pageScroller.showsHorizontalScrollIndicator = NO;
        pageScroller.showsVerticalScrollIndicator = NO;
        pageScroller.scrollsToTop = NO;
        pageScroller.delegate = self;
        pageScroller.delaysContentTouches = NO;
        //[pageScroller setBackgroundColor:[UIColor colorWithPatternImage:patternImage]];
        for (int i=0;i<[subViews count];i++) {
            CGRect frame = pageScroller.frame;
            frame.origin.x = frame.size.width * i;
            frame.origin.y = 0;
            ((UIView*)[subViews objectAtIndex:i]).frame = frame;
            [pageScroller addSubview:(UIView*)[subViews objectAtIndex:i]];
            [(UIView*)[subViews objectAtIndex:i] setBackgroundColor:[UIColor colorWithPatternImage:patternImage]];
            if ([[subViews objectAtIndex:i] isKindOfClass:[UIScrollView class]]) {
                ((UIScrollView*)[subViews objectAtIndex:i]).delaysContentTouches = NO;
            }
        }
        CGRect frame = pageScroller.frame;
        frame.origin.x = frame.size.width * 0;
        frame.origin.y = 0;
        [pageScroller scrollRectToVisible:frame animated:YES];
        currentPage = 1;
        [tabBar setSelectedItem:[tabBar.items objectAtIndex:0]];
        tabBarSelect = false;
        self.view.backgroundColor = [UIColor underPageBackgroundColor];

    }
    // Do any additional setup after loading the view from its nib.
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    if (!tabBarSelect) {
        CGFloat pageWidth = pageScroller.frame.size.width;
        currentPage = floor((pageScroller.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        [tabBar setSelectedItem:[tabBar.items objectAtIndex:currentPage]];
    }
    /*if (currentPage == 0) {
        pageScroller.delaysContentTouches = NO;
    } else {
        pageScroller.delaysContentTouches = YES;
    }*/
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    tabBarSelect = false;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    tabBarSelect = true;
    NSLog(@"tab select");
    CGRect frame = pageScroller.frame;
    frame.origin.x = frame.size.width * item.tag;
    frame.origin.y = 0;
    [pageScroller scrollRectToVisible:frame animated:YES];
    currentPage = item.tag;
    //[tabBar setSelectedItem:[tabBar.items objectAtIndex:0]];
}

- (void)viewDidUnload
{
    [self setPageScroller:nil];
    [self setTabBar:nil];
    [self setSubViews:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    userSettings = [NSUserDefaults standardUserDefaults];
    rangeSlider.value = [userSettings floatForKey:@"Slider Range"];
    rangeLabel.text = [NSString stringWithFormat:@"%.f cents",[userSettings floatForKey:@"Slider Range"]];
    methodControl.selectedSegmentIndex = [userSettings integerForKey:@"Key Switch Method"];
    hertzSlider.value = [userSettings floatForKey:@"A Hertz"];
    hertzLabel.text = [NSString stringWithFormat:@"%.f Hz",[userSettings floatForKey:@"A Hertz"]];
    if (methodControl.selectedSegmentIndex == 2) {
        hertzSlider.enabled = true;
        hertzLabel.layer.opacity = 1;
    } else {
        hertzSlider.enabled = false;
        hertzLabel.layer.opacity = 0.5;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction) backButtonClick:(id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) goBack {
    [self dismissModalViewControllerAnimated:YES];
}

- (void) save {
    [userSettings synchronize];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)rangeChanged:(id)sender {
    rangeSlider.value = roundf(rangeSlider.value);
    NSLog(@"%f",rangeSlider.value);
    rangeLabel.text = [NSString stringWithFormat:@"%.f cents",rangeSlider.value];
    [userSettings setFloat:rangeSlider.value forKey:@"Slider Range"];
}

- (void)methodChanged:(id)sender {
    [userSettings setObject:[NSNumber numberWithInt:methodControl.selectedSegmentIndex] forKey:@"Key Switch Method"];
    if (methodControl.selectedSegmentIndex == 2) {
        hertzSlider.enabled = true;
        hertzLabel.layer.opacity = 1;
    } else {
        hertzSlider.enabled = false;
        hertzLabel.layer.opacity = 0.5;
    }
}

- (void)hertzChanged:(id)sender {
    hertzSlider.value = roundf(hertzSlider.value);
    hertzLabel.text = [NSString stringWithFormat:@"%.f Hz",hertzSlider.value];
    [userSettings setFloat:hertzSlider.value forKey:@"A Hertz"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[instrumentList allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[instrumentList objectForKey:[[instrumentList allKeys] objectAtIndex:section]] count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[instrumentList allKeys] objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[[instrumentList objectForKey:[[instrumentList allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] stringByDeletingPathExtension];
    //cell.detailTextLabel.text = @"No Loop";
    NSString *path = [[NSBundle mainBundle] pathForResource:[[[instrumentList objectForKey:[[instrumentList allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] stringByDeletingPathExtension] ofType:@"sound"];
    NSArray *instrumentInfo = [NSArray arrayWithContentsOfFile:path];
    NSLog(@"%@",instrumentInfo);
    if ([(NSDictionary*)[instrumentInfo objectAtIndex:0] objectForKey:@"Loop Start"] != nil) {
        cell.detailTextLabel.text = @"Indefinite Sustain";
    }
    if ([cell.textLabel.text isEqualToString:[userSettings stringForKey:@"Default Instrument"]] && checkedPath == nil) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        checkedPath = indexPath;
    }
    // Configure the cell...
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView cellForRowAtIndexPath:checkedPath].accessoryType = UITableViewCellAccessoryNone;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    checkedPath = indexPath;
    [userSettings setObject:[tableView cellForRowAtIndexPath:indexPath].textLabel.text forKey:@"Default Instrument"];
}

@end
