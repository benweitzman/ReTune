//
//  MoreScalesController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoreScalesController.h"
#import "JSONKit.h" 

@implementation MoreScalesController

@synthesize scalesTable;

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

- (void)viewDidAppear:(BOOL)animated {
    self.title = @"Get more scales";
    scalesTable = [[UITableView alloc]initWithFrame:self.view.bounds 
                                              style:UITableViewStylePlain];
    
    //[self.view addSubview:scalesTable];
    // save this view somewhere
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake((self.navigationController.view.frame.size.width-80)/2,
                                                               (self.navigationController.view.frame.size.height-20)/2-40,
                                                               80,
                                                               20)];
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.frame = CGRectMake(label.frame.origin.x - 20 - 5,
                               label.frame.origin.y,
                               20,
                               20);
    label.text = @"Loading…";
    [self.view addSubview:label];
    [self.view addSubview:spinner];
    [spinner startAnimating];
    //[scalesTable addSubview:aiview];
    NSURL *url = [NSURL URLWithString:@"http://localhost:8000/pull"];
    
    // Set up a concurrent queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSData* data = [NSData dataWithContentsOfURL:url];
        [self performSelectorOnMainThread:@selector(parseData:)
                               withObject:data
                            waitUntilDone:YES];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [self.navigationItem setRightBarButtonItem:backButton];
    // Do any additional setup after loading the view from its nib.
}
- (void) cancel {
    [self dismissModalViewControllerAnimated:YES];
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

- (void)parseData:(NSData *)responseData
{
    //NSError* error = [[NSError alloc] init];
    
    // NEW in iOS 5: NSJSONSerialization
    // No more third-party libraries necessary for JSON parsing
    scales = [responseData objectFromJSONData];
    NSLog(@"%@",scales);
    
    // Iterate through tweets
    /*NSEnumerator *it = [json objectEnumerator];
    NSDictionary *tweet;
    while (tweet = [it nextObject]) {
        [tweets addObject:[tweet objectForKey:@"text"]];
    }
    
    // IMPORTANT! Reload the table data*/
    [[self.view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.view addSubview:scalesTable];
    self.scalesTable.dataSource = self;
    
    self.scalesTable.delegate = self;
    [self.scalesTable reloadData];
}


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Required for UITableViewDataSource protocol: informs table view of the number of sections to be loaded onto table
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Required for UITableViewDataSource protocol: informs table view of how many rows to be loaded in each section
    return [scales count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Required for UITableViewDataSource protocol: Responsible for returning instances of the UITableViewCell class
    
    static NSString *cellIdentifier = @"Scale";
    UITableViewCell *cell = nil;
    if ([tableView isEqual:self.scalesTable]) {
        
        // Set up cell
        cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellIdentifier];
        }
        
        // Set the text of the cell
        cell.textLabel.text = [[scales objectAtIndex:indexPath.row] objectForKey:@"scaleName"];
        cell.detailTextLabel.text = [[scales objectAtIndex:indexPath.row] objectForKey:@"description"];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@",[scales objectAtIndex:indexPath.row]);
}

@end
