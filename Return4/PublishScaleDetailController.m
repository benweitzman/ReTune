//
//  PublishScaleDetailController.m
//  Retune4.3
//
//  Created by Ben Weitzman on 7/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PublishScaleDetailController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "UITextViewTableViewCell.h"
#import <CommonCrypto/CommonDigest.h>


@interface NonDismissingAlertView : UIAlertView

-(void) doDismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@end

@implementation NonDismissingAlertView 

-(void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    //if (buttonIndex should not dismiss the alert)
     //   return;
    //[super dismissWithClickedButtonIndex:buttonIndex animated:animated];
}

-(void) doDismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    [super dismissWithClickedButtonIndex:buttonIndex animated:animated];
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
    tf.frame = CGRectMake(140, 12, 165, 30);
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
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [self.navigationItem setRightBarButtonItem:backButton];
    UIImage *patternImage = [UIImage imageNamed:@"diamond_upholstery.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:patternImage];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void) cancel {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [self dismissModalViewControllerAnimated:YES];
    else {}
        [[self navigationController] dismissModalViewControllerAnimated:YES];
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
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            return 12+60+12;
        else
            return 12+200+12;
    } else {
        return 12+30+12;
    }
}

- (void) addLoginButtonsToCell:(UITableViewCell*)cell {
    for (UIView *view in [cell subviews]) {
        if ([view isKindOfClass:[UIButton class]] || [view isKindOfClass:[UIActivityIndicatorView class]] || [view isKindOfClass:[UITextField class]]) {
            [view removeFromSuperview];
        }
    }
    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
    UIButton *loginButton, *registerButton;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        loginButton = [[UIButton alloc] initWithFrame:CGRectMake(180, 12, 180, 30)];
        registerButton = [[UIButton alloc] initWithFrame:CGRectMake(380, 12, 120, 30)];
    } else {
        loginButton = [[UIButton alloc] initWithFrame:CGRectMake(140,12,60,30)];
        registerButton = [[UIButton alloc] initWithFrame:CGRectMake(220,12,80, 30)];
        [loginButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [registerButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
    }
    [loginButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [loginButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        [loginButton setTitle:@"Login to continue" forState:UIControlStateNormal];
    else {
        [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    }
    [loginButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [registerButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [registerButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
    [registerButton setTitle:@"Register" forState:UIControlStateNormal];
    [registerButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cell addSubview:loginButton];
    [cell addSubview:registerButton];
    [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [registerButton addTarget:self action:@selector(goToRegister) forControlEvents:UIControlEventTouchUpInside];
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
            {
                cell.textLabel.text = @"Scale Name";
                scaleNameField = [self makeTextField:scaleName placeholder:@"Scale name here"];
                for (UIView *view in cell.subviews) {
                    if ([view isKindOfClass:[UITextField class]])
                        [view removeFromSuperview];
                }
                [cell addSubview:scaleNameField];
            }
                break;
            case 1:
            {
                if ([cell.subviews count] == 1) {
                    cell.textLabel.text = @"Author Name";
                    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    [activityIndicator setFrame:CGRectMake(180, 12, 30, 30)];
                    [activityIndicator startAnimating];
                    [cell addSubview:activityIndicator];
                    //authorNameField = [self makeTextField:@"" placeholder:@"Your hame here"];
                    NSURL *loginTestURL = [NSURL URLWithString:@"http://retuneapp.com/loginTest/"];
                    __weak ASIHTTPRequest *loginTestRequest = [ASIHTTPRequest requestWithURL:loginTestURL];
                    [loginTestRequest setCompletionBlock:^{
                        NSString *loginTestResponse = [loginTestRequest responseString];
                        NSLog(@"%@",loginTestResponse);
                        if ([loginTestResponse isEqualToString:@"not logged in"]) {
                            [self addLoginButtonsToCell:cell];
                        } else {
                            for (UIView *view in authorCell.subviews) {
                                if ([view isKindOfClass:[UIActivityIndicatorView class]])
                                    [view removeFromSuperview];
                            }
                            authorNameField = [self makeTextField:loginTestResponse placeholder:@"Your hame here"];
                            [authorNameField setEnabled:NO];
                            [cell addSubview:authorNameField];
                            UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                                                    resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
                            UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                                             resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
                            UIButton *logoutButton;
                            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                                logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(380, 12, 120, 30)];
                            else {
                                logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(250, 12, 50, 30)];
                                [logoutButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
                            }
                            [logoutButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
                            [logoutButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
                            [logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
                            [logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                            [logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
                            [cell addSubview:logoutButton];
                        }
                    }];
                    [loginTestRequest startAsynchronous];
                    authorCell = cell;
                }
            }
                break;
            case 2:
            {
                cell.textLabel.text = @"Description";
                descriptionField = [[UIPlaceHolderTextView alloc] init];  
                descriptionField.text = @"" ;   
                descriptionField.placeholder = @"Your description here";
                descriptionField.autocorrectionType = UITextAutocorrectionTypeNo ;  
                descriptionField.autocapitalizationType = UITextAutocapitalizationTypeNone;  
                //descriptionField.adjustsFontSizeToFitWidth = YES;  
                descriptionField.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                    descriptionField.frame = CGRectMake(174, 5, 320, 60);
                else {
                    descriptionField.frame = CGRectMake(15,35,300, 170);
                }
                descriptionField.backgroundColor = [UIColor clearColor];
                [cell addSubview:descriptionField];
            }
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

- (void) goToRegister {
    RegisterViewController *registerController = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
    [self.navigationController pushViewController:registerController animated:YES];
}

- (void) login {
    NonDismissingAlertView *alert = [[NonDismissingAlertView alloc] initWithTitle:@"Login" message:@"" delegate:self cancelButtonTitle:@"Cancel"  otherButtonTitles:@"Submit", nil];
    [alert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [alert show];
}

- (void) logout {
    NSURL *url = [NSURL URLWithString:@"http://retuneapp.com/logout/"];
    __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        [self addLoginButtonsToCell:authorCell];
    }];
    [request startAsynchronous];
}


- (void)shakeView:(UIView *)viewToShake
{
    CGFloat t = 10.0;
    CGAffineTransform translateRight  = CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0.0);
    CGAffineTransform translateLeft = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0.0);
    
    viewToShake.transform = translateLeft;
    
    [UIView animateWithDuration:0.07 delay:0.0 options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat animations:^{
        [UIView setAnimationRepeatCount:2.0];
        viewToShake.transform = translateRight;
    } completion:^(BOOL finished) {
        if (finished) {
            [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                viewToShake.transform = CGAffineTransformIdentity;
            } completion:NULL];
        }
    }];
}

- (void)alertView:(NonDismissingAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView title];
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]) {
        [alertView doDismissWithClickedButtonIndex:buttonIndex animated:YES];
    } else {
        if([title isEqualToString:@"Login"])
        {
            UITextField *username = [alertView textFieldAtIndex:0];
            UITextField *password = [alertView textFieldAtIndex:1];
            
            NSURL *url = [NSURL URLWithString:@"http://retuneapp.com/getAuth/"];
            __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
            [request setCompletionBlock:^{
                NSString *responseString = [request responseString];
                NSString* auth = [self sha1:[NSString stringWithFormat:@"%@%@",@"a4h398d",responseString]];
                NSURL *loginURL = [NSURL URLWithString:@"http://retuneapp.com/login/"];
                __weak ASIFormDataRequest *loginRequest = [ASIFormDataRequest requestWithURL:loginURL];
                [loginRequest setPostValue:username.text forKey:@"username"];
                [loginRequest setPostValue:password.text forKey:@"password"];
                [loginRequest setPostValue:auth forKey:@"auth"];
                [loginRequest setCompletionBlock:^{
                    NSString *loginResponse = [loginRequest responseString];
                    if ([loginResponse isEqualToString:@"Bad"]) {
                        [self shakeView:alertView];
                        return;
                    }
                    NSLog(@"%@",loginResponse);
                    authorNameField = [self makeTextField:username.text placeholder:@"Your hame here"];
                    [authorNameField setEnabled:NO];
                    for (UIView *view in authorCell.subviews) {
                        if ([view isKindOfClass:[UIButton class]])
                            [view removeFromSuperview];
                    }
                    [authorCell addSubview:authorNameField];
                    UIImage *buttonImage = [[UIImage imageNamed:@"greyButton.png"]
                                            resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
                    UIImage *buttonImageHighlight = [[UIImage imageNamed:@"greyButtonHighlight.png"]
                                                     resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
                    UIButton *logoutButton;
                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                        logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(380, 12, 120, 30)];
                    else {
                        logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(250, 12, 50, 30)];
                        [logoutButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
                    }
                    [logoutButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
                    [logoutButton setBackgroundImage:buttonImageHighlight forState:UIControlStateHighlighted];
                    [logoutButton setTitle:@"Logout" forState:UIControlStateNormal];
                    [logoutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    [logoutButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
                    [authorCell addSubview:logoutButton];
                    [alertView doDismissWithClickedButtonIndex:buttonIndex animated:YES];
                    NSURL *loginTestURL = [NSURL URLWithString:@"http://retuneapp.com/loginTest/"];
                    __weak ASIHTTPRequest *loginTestRequest = [ASIHTTPRequest requestWithURL:loginTestURL];
                    [loginTestRequest setCompletionBlock:^{
                        NSString *loginTestResponse = [loginTestRequest responseString];
                        NSLog(@"%@",loginTestResponse);
                    }];
                    [loginTestRequest startAsynchronous];
                }];
                [loginRequest setFailedBlock:^{
                    NSError *error = [loginRequest error];
                    NSLog(@"%@",error);
                }];
                [loginRequest startAsynchronous];
            }];
            [request setFailedBlock:^{
                NSError *error = [request error];
                NSLog(@"%@",error);
            }];
            [request startAsynchronous];
        }
    }
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
        NSMutableDictionary *toSend = [NSMutableDictionary new];
        [toSend setValue:scaleNameField.text forKey:@"scaleName"];
        [toSend setValue:authorNameField.text forKey:@"authorName"];
        [toSend setValue:descriptionField.text forKey:@"description"];
        [toSend setValue:scaleToSend forKey:@"scale"];
        //NSLog(@"%@",toSend);
        NSError *error; 
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:toSend 
                                                           options:0 // Pass 0 if you don't care about the readability of the generated string
                                                             error:&error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",jsonString);
        
        // Set up a concurrent queue
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            // pull auth key from server (current time) and hash it with a salt to ensure that that page is only visited by this app
            NSError *error;
            NSURL *url = [NSURL URLWithString:@"http://retuneapp.herokuapp.com/getAuth"];
            NSString* data = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
            NSString* auth = [self sha1:[NSString stringWithFormat:@"%@%@",@"a4h398d",data]];
            NSLog(@"%@",[NSString stringWithFormat:@"http://retuneapp.herokueapp.com/push?auth=%@&data=%@",auth,jsonString]);
            NSURL *pushUrl = [NSURL URLWithString:[[NSString stringWithFormat:@"http://retuneapp.herokuapp.com/push?auth=%@&data=%@",auth,jsonString] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            NSLog(@"%@",pushUrl);
            NSString *pushResponse = [NSString stringWithContentsOfURL:pushUrl encoding:NSUTF8StringEncoding error:&error];
            NSLog(@"%@",pushResponse);
            [self performSelectorOnMainThread:@selector(handleResponse:) withObject:pushResponse waitUntilDone:YES];
        });
    }
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    //[self dismissModalViewControllerAnimated:YES];
}

- (void) handleResponse:(NSString *)response {
    if ([response isEqualToString:@"Good"]) {
        [self dismissModalViewControllerAnimated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error uploading to server" message:@"There was a problem trying to upload your scale to the server. Please try again later" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }
}

- (NSString *) sha1:(NSString *)input {
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end

