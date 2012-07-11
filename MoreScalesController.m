//
//  MoreScalesController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoreScalesController.h"
#import "MoreScalesDetailController.h"
#import "JSONKit.h" 

@implementation MoreScalesController

@synthesize scalesTable;
@synthesize typeControl, directionControl;

- (BOOL) disablesAutomaticKeyboardDismissal {
    return NO;
}

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
    loadingMore = false;
    if (self.scalesTable == nil ) {
    self.title = @"Get more scales";
   
    
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
    NSURL *url = [NSURL URLWithString:currentPull];
    
    // Set up a concurrent queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSData* data = [NSData dataWithContentsOfURL:url];
        [self performSelectorOnMainThread:@selector(parseData:)
                               withObject:data
                            waitUntilDone:YES];
    });
    searching = false;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    currentPage = 0;
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [self.navigationItem setRightBarButtonItem:backButton];
    scales = [[NSMutableArray alloc] init];
    currentPull = [NSMutableString stringWithString:@"http://retuneapp.com/pull"];
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
    NSDictionary *data = [responseData objectFromJSONData];
    shouldLoadMore = [[data objectForKey:@"shouldLoadMore"] boolValue];
    scales = [[NSMutableArray alloc] initWithArray:[data objectForKey:@"scales"]];
    //NSLog(@"%@",scales);
    
    // Iterate through tweets
    /*NSEnumerator *it = [json objectEnumerator];
    NSDictionary *tweet;
    while (tweet = [it nextObject]) {
        [tweets addObject:[tweet objectForKey:@"text"]];
    }
    
    // IMPORTANT! Reload the table data*/
    [[self.view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect bounds = self.view.bounds;
    scalesTable = [[UITableView alloc]initWithFrame:CGRectMake(bounds.origin.x,bounds.origin.y,bounds.size.width,bounds.size.height)
                                              style:UITableViewStylePlain];
    [self.view addSubview:scalesTable];
    self.scalesTable.dataSource = self;
    
    self.scalesTable.delegate = self;
    [self.scalesTable reloadData];
    typeControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Sort by Name",@"Sort by Date",@"Sort by Downloads",nil]];
    [typeControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    //segmentedControl.frame = CGRectMake(0, 0, 320, 30);
    [typeControl setSelectedSegmentIndex:0];
    [typeControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    typeControl.frame = CGRectMake(0.0f, 0.0f, 377.0f, 30.0f);
    
    directionControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Asc",@"Desc", nil]];
    [directionControl addTarget:self  action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [directionControl setSelectedSegmentIndex:0];
    [directionControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    directionControl.frame = CGRectMake(387.0f, 0.0f, 139.0f, 30.0f);
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:typeControl];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithCustomView:directionControl];
    NSArray *theToolbarItems = [NSArray arrayWithObjects:item,item2, nil];
    [self setToolbarItems:theToolbarItems];
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 540, 88)];
    searchBar.delegate = self;
    searchBar.showsScopeBar = TRUE;
    searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"Scale Name",@"Description",@"Author", nil];
    searchBar.selectedScopeButtonIndex = 0;
    self.scalesTable.tableHeaderView = searchBar;
    [self.navigationController setToolbarHidden:NO animated:YES];
    NSLog(@"%d",[[scalesTable visibleCells] count]);
    
}

- (IBAction)segmentChanged:(id)sender {
    int direction = (directionControl.selectedSegmentIndex*2-1)*-1;
    if (typeControl.selectedSegmentIndex == 0) {
        scales = [scales sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 objectForKey:@"scaleName"] compare:[obj2 objectForKey:@"scaleName"] options:NSCaseInsensitiveSearch]*direction;
        }];
    } else if (typeControl.selectedSegmentIndex == 1) {
        scales = [scales sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSNumber*)[obj1 objectForKey:@"id"] compare:(NSNumber*)[obj2 objectForKey:@"id"]]*direction;
        }];
    } else {
        scales = [scales sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [(NSNumber*)[obj1 objectForKey:@"downloads"] compare:(NSNumber*)[obj2 objectForKey:@"downloads"]]*direction;
        }];
    }
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
    NSLog(@"%d",[scales count]);
    if (scales != nil) {
        NSLog(@"scale count:%d",[scales count]);
        if (!searching || true) return [scales count]+1;
        return [scalesCopy count]+1;
    } 
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Required for UITableViewDataSource protocol: Responsible for returning instances of the UITableViewCell class
    
    static NSString *cellIdentifier = @"Scale";
    UITableViewCell *cell = nil;
    NSMutableArray *scaleSource = scales;
    //if (searching) scaleSource = scalesCopy;
    if ([tableView isEqual:self.scalesTable]) {
        
        // Set up cell
        cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellIdentifier];
        }
        if (indexPath.row == [scaleSource count] || [scaleSource count] == 0) {
            cell.textLabel.text = @"Loading more scales";
            loadingCell = cell;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            // Set the text of the cell
            NSDictionary *scale = [scaleSource objectAtIndex:indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ by %@",[scale objectForKey:@"scaleName"],[scale objectForKey:@"authorName"]];
            cell.detailTextLabel.text = [scale objectForKey:@"description"];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell == loadingCell) {
        NSLog(@"go time");
        [self loadMorePages];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *scale = [scales objectAtIndex:indexPath.row];
    /*NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
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
    [self dismissModalViewControllerAnimated:YES];*/
    int scaleId = [[scale objectForKey:@"id"] intValue];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSError *error;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://retuneapp.com/pull/%d/",scaleId]];
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        if (!error && data.description != @"Bad") {
            NSDictionary *scale = [data objectFromJSONData];
            [self performSelectorOnMainThread:@selector(goToDetailPageWithScale:) withObject:scale waitUntilDone:NO];
        }
    });
   // NSLog(@"%@",file);
}

- (void)goToDetailPageWithScale:(NSDictionary *)scale {
    MoreScalesDetailController *detailController = [[MoreScalesDetailController alloc] initWithNibName:@"MoreScalesDetailController" bundle:nil];
    detailController.title = @"Scale Info";
    detailController.scale = [scale mutableCopy];
    [self.navigationController pushViewController:detailController animated:YES];
    
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searcherBar {
    NSLog(@"clicked");
    [searchBar setShowsCancelButton:TRUE animated:YES];
    [searchBar resignFirstResponder];
    searching = false;
    NSLog(@"wut");
}



- (void)searchBarTextDidBeginEditing:(UISearchBar *)searcherBar {
    [searcherBar setShowsCancelButton:TRUE animated:YES];
    searching = true;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searcherBar {
    searching = false;
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searcherBar {
    currentPage = 0;
    NSString *searchText = searcherBar.text;
    if ([searchText length] == 0) {
        searching = false;
        [self.scalesTable reloadData];
        return;
    }
    searching = true;
    NSMutableString *urlString = [NSMutableString stringWithString:@"http://retuneapp.com/pull?"];
    [urlString appendFormat:@"query=%@",searchText];
    if (searcherBar.selectedScopeButtonIndex == 0 ){
        [urlString appendString:@"&scope=scaleName"];
    } else if (searcherBar.selectedScopeButtonIndex == 1) {
        [urlString appendString:@"&scope=description"];
    } else {
        [urlString appendString:@"&scope=authorName"];
    }
    currentPull = urlString;
    NSURL *url = [NSURL URLWithString:urlString];
    currentPull = urlString;
    NSLog(@"%@",urlString);
    // Set up a concurrent queue
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSData* data = [NSData dataWithContentsOfURL:url];
        [self performSelectorOnMainThread:@selector(parseLoad:)
                               withObject:data
                            waitUntilDone:YES];
    });
}

-(void) parseLoad:(NSData *)responseData {
    scales = [[[responseData objectFromJSONData] objectForKey:@"scales"] mutableCopy];
    shouldLoadMore = [[[responseData objectFromJSONData] objectForKey:@"shouldLoadMore"] boolValue];
    [self.scalesTable reloadData];
}

- (void) searchBar:(UISearchBar *)searcherBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    //[self searchBar:searcherBar textDidChange:searcherBar.text];
}

- (void)loadMorePages {
    if (shouldLoadMore && !loadingMore) {
        NSLog(@"starting to load more");
        loadingMore = true;
        currentPage++;
        NSString *pageURL;
        if ([currentPull rangeOfString:@"?"].location != NSNotFound){
            pageURL = [NSString stringWithFormat:@"%@%@%d",currentPull,@"&page=",currentPage];
        } else {
            pageURL = [NSString stringWithFormat:@"%@%@%d",currentPull,@"?page=",currentPage];
        }
        NSURL * url = [NSURL URLWithString:pageURL];
        NSLog(@"%@",pageURL);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            NSData* data = [NSData dataWithContentsOfURL:url];
            NSDictionary *jsonObj = [data objectFromJSONData];
            NSLog(@"%@",jsonObj);
            shouldLoadMore = [[jsonObj objectForKey:@"shouldLoadMore"] boolValue];
            if ([[jsonObj objectForKey:@"scales"] count] == 0) {
                shouldLoadMore = false;
            }
            [scales addObjectsFromArray:[jsonObj objectForKey:@"scales"]];
            [scalesTable reloadData];
            loadingMore = false;
        });
    }
}

@end
