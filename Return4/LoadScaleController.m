//
//  LoadScaleController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LoadScaleController.h"

@implementation LoadScaleController

@synthesize delegate,button;

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"%@",searchBar.text);
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    displayMode = DisplayAll;
    NSString * bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *direnum = [fm enumeratorAtPath:bundleRoot];
    NSString *filename;
    scales = [[NSMutableArray alloc] init];
    scaleCats = [[NSMutableDictionary alloc] init];
    [scaleCats setValue:[[NSMutableArray alloc] init] forKey:@"Standard"];
    [scaleCats setValue:[[NSMutableArray alloc] init] forKey:@"User"];
    while ((filename = [direnum nextObject])) {
        if ([filename hasSuffix:@".scale"]){
            NSLog(@"%@",filename);
            [scales addObject:[filename stringByDeletingPathExtension]];
            [[scaleCats objectForKey:@"Standard"] addObject:[filename stringByDeletingPathExtension]];
        }
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    fm = [NSFileManager defaultManager];
    direnum = [fm enumeratorAtPath:documentsDirectory];
    //midiFiles = [[NSMutableArray alloc] init];
    while ((filename = [direnum nextObject])) {
        if ([filename hasSuffix:@".scale"]){
            NSLog(@"%@",filename);
            [scales addObject:[filename stringByDeletingPathExtension]];
            [[scaleCats objectForKey:@"User"] addObject:[filename stringByDeletingPathExtension]];
        }
    }
    searching = false;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//#warning Potentially incomplete method implementation.
    // Return the number of sections.
    if (displayMode == DisplayAll) {
        return [[scaleCats allKeys] count];
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//#warning Incomplete method implementation.
    // Return the number of rows in the section.
    NSMutableDictionary *scaleSource = scaleCats;
    if (searching) scaleSource = scaleCopy;
    if (displayMode == DisplayAll) {
        return [[scaleSource objectForKey:[[scaleSource allKeys] objectAtIndex:section]] count];
    } else if (displayMode == DisplayStandard) {
        return [[scaleSource objectForKey:@"Standard"] count];
    } else {
        return [[scaleSource objectForKey:@"User"] count];
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (displayMode == DisplayAll) {
        return [[scaleCats allKeys] objectAtIndex:section];
    } else if (displayMode == DisplayStandard) return @"Standard";
    else return @"User";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *scaleSource = scaleCats;
    if (searching) scaleSource = scaleCopy;
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (displayMode == DisplayAll) {
        cell.textLabel.text = [[scaleSource objectForKey:[[scaleSource allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    } else if (displayMode == DisplayStandard) {
        cell.textLabel.text = [[scaleSource objectForKey:@"Standard"] objectAtIndex:indexPath.row];
    } else {
        cell.textLabel.text = [[scaleSource objectForKey:@"User"] objectAtIndex:indexPath.row];
    }

    
    // Configure the cell..
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [delegate LoadScaleController:self didFinishWithSelection:[[scaleCats objectForKey:[[scaleCats allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row]];
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)segmentChanged:(id)sender {
    UISegmentedControl * segment = (UISegmentedControl *) sender;
    displayMode = segment.selectedSegmentIndex;
    [self.tableView reloadData];
    //[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:[NSIndexPath w] withRowAnimation:UITableViewRowAnimationTop];
}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:FALSE animated:YES];
    [searchBar resignFirstResponder];
    searching = false;
}

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:TRUE animated:YES];
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText length] == 0) {
        searching = false;
        [self.tableView reloadData];
        return;
    }
    searching = true;
    scaleCopy = [[NSMutableDictionary alloc] init];
    for (NSString *key in scaleCats) {
        NSMutableArray *section = [scaleCats objectForKey:key];
        //NSLog(@"%@",section);
        [scaleCopy setObject:[[NSMutableArray alloc] init] forKey:key];
        [section enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *scaleName = obj;
            if ([scaleName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [[scaleCopy objectForKey:key] addObject:scaleName];
            }
        }];
    }
    [self.tableView reloadData];
}
@end
