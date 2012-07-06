//
//  PublishScaleDetailController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PublishScaleDetailController.h"

@interface UITextViewTableViewCell : UITableViewCell

@end
    
@implementation UITextViewTableViewCell

- (void) layoutSubviews 
{
    [super layoutSubviews]; 
    
    // Set top of textLabel to top of cell
    CGRect newFrame = self.textLabel.frame;
    newFrame.origin.y = CGRectGetMinY (self.contentView.bounds);
    newFrame.size.height = 45;
    [self.textLabel setFrame:newFrame];
    
    // Set top of detailTextLabel to bottom of textLabel
    newFrame = self.detailTextLabel.frame;
    newFrame.origin.y = CGRectGetMaxY (self.textLabel.frame);
    [self.detailTextLabel setFrame:newFrame];
}

@end

@implementation PublishScaleDetailController

@synthesize scaleToSend, scaleName;

-(UITextField*) makeTextField: (NSString*)text    
                  placeholder: (NSString*)placeholder  {  
    UITextField *tf = [[UITextField alloc] init];  
    tf.placeholder = placeholder ;  
    tf.text = text ;           
    tf.autocorrectionType = UITextAutocorrectionTypeNo ;  
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;  
    tf.adjustsFontSizeToFitWidth = YES;  
    tf.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];      
    tf.frame = CGRectMake(180, 12, 320, 30); 
    return tf ;  
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (section == 0) return 3;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2 ) {
        return 12+60+12;
    } else {
        return 12+30+12;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
   
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (indexPath.section == 0) {
        if (cell == nil) {
            cell = [[UITextViewTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Scale Name" ;  
                scaleNameField = [self makeTextField:scaleName placeholder:@"Scale name here"];  
                [cell addSubview:scaleNameField];  
                break;
            case 1:
                cell.textLabel.text = @"Author Name" ;  
                authorNameField = [self makeTextField:@"" placeholder:@"Your hame here"];  
                [cell addSubview:authorNameField];  
                break;
            case 2:
                cell.textLabel.text = @"Description";
                descriptionField = [[UIPlaceHolderTextView alloc] init];  
                descriptionField.text = @"" ;   
                descriptionField.placeholder = @"Your description here";
                descriptionField.autocorrectionType = UITextAutocorrectionTypeNo ;  
                descriptionField.autocapitalizationType = UITextAutocapitalizationTypeNone;  
                //descriptionField.adjustsFontSizeToFitWidth = YES;  
                descriptionField.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];      
                descriptionField.frame = CGRectMake(174, 5, 320, 60);
                descriptionField.backgroundColor = [UIColor clearColor];
                [cell addSubview:descriptionField];  
                break;
        }
    } else {
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.textLabel.text = @"Submit";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        
    }
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
    if (indexPath.section == 1 && indexPath.row == 0) {
        NSLog(@"%@",scaleToSend);
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
