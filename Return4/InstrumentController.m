//
//  InstrumentController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "InstrumentController.h"
#import "LoadScaleController.h"

@implementation InstrumentController

@synthesize delegate;

- (void) cancel{
    [self dismissModalViewControllerAnimated:YES];
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
    [self.navigationController.view setBackgroundColor:[UIColor redColor]];
    //[self.view setBackgroundColor:[UIColor redColor]];
    [self.view.window setBackgroundColor:[UIColor redColor]];
    [self.navigationController.view.window setBackgroundColor:[UIColor blueColor]];
    self.title = @"Select an instrument";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [self.navigationItem setRightBarButtonItem:backButton];
    
    NSString * bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSFileManager * fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *direnum = [fm enumeratorAtPath:bundleRoot];
    NSString *filename;
    instruments = [[NSMutableArray alloc] init];
    while ((filename = [direnum nextObject])) {
        if ([filename hasSuffix:@".sound"]){
            NSLog(@"%@",filename);
            [instruments addObject:[filename stringByDeletingPathExtension]];
        }
    }
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Instruments" ofType:@"plist"];
    instrumentList = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSLog(@"%@",instrumentList);
    /*NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    fm = [NSFileManager defaultManager];
    direnum = [fm enumeratorAtPath:documentsDirectory];
    //midiFiles = [[NSMutableArray alloc] init];
    while ((filename = [direnum nextObject])) {
        if ([filename hasSuffix:@".sound"]){
            NSLog(@"%@",filename);
            [instruments addObject:[filename stringByDeletingPathExtension]];
        }
    }*/

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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [[[instrumentList objectForKey:[[instrumentList allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] stringByDeletingPathExtension];

    
    // Configure the cell...
    
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
    //[self.navigationController pushViewController:instrumentViewController transition:10 forceImmediate:NO];
    // Navigation logic may go here. Create and push another view controller.
    [delegate InstrumentController:self didFinishWithSelection:[[[instrumentList objectForKey:[[instrumentList allKeys] objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row] stringByDeletingPathExtension]];
    
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
