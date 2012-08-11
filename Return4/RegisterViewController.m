//
//  RegisterViewController.m
//  ReTune
//
//  Created by Ben Weitzman on 8/7/12.
//
//

#import "RegisterViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "UITextViewTableViewCell.h"
#import <CommonCrypto/CommonDigest.h>


@interface RegisterViewController ()

@end

@implementation RegisterViewController

-(UITextField*) makeTextField: (NSString*)text
                  placeholder: (NSString*)placeholder  {
    UITextField *tf = [[UITextField alloc] init];
    tf.placeholder = placeholder ;
    tf.text = text ;
    tf.autocorrectionType = UITextAutocorrectionTypeNo ;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.adjustsFontSizeToFitWidth = YES;
    tf.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        tf.frame = CGRectMake(200, 12, 320, 30);
    else {
        tf.frame = CGRectMake(25,12,280, 30);
    }
    return tf ;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImage *patternImage = [UIImage imageNamed:@"diamond_upholstery.png"];
    self.view.backgroundColor = [UIColor colorWithPatternImage:patternImage];
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
	return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (section == 0) return 4;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 12+30+12;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
                if ([cell.subviews count] != 1) break;
                cell.textLabel.text = @"Username";
                usernameField = [self makeTextField:@"" placeholder:@"Username"];
                [cell addSubview:usernameField];
            }
                break;
            case 1:
            {
                if ([cell.subviews count] != 1) break;
                cell.textLabel.text = @"Email";
                emailField = [self makeTextField:@"" placeholder:@"Email"];
                emailField.keyboardType = UIKeyboardTypeEmailAddress;
                [cell addSubview:emailField];
            }
                break;
            case 2:
            {
                if ([cell.subviews count] != 1) break;
                cell.textLabel.text = @"Password";
                passwordField = [self makeTextField:@"" placeholder:@"Password"];
                [passwordField setSecureTextEntry:YES];
                [cell addSubview:passwordField];
            }
                break;
            case 3:
            {
                if ([cell.subviews count] != 1) break;
                cell.textLabel.text = @"Retype Password";
                passwordAgainField = [self makeTextField:@"" placeholder:@"Password Again"];
                [passwordAgainField setSecureTextEntry:YES];
                [cell addSubview:passwordAgainField];
            }
                break;
        }
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            cell.textLabel.text = @"";
            //[cell.textLabel removeFromSuperview];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if ([usernameField.text length] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please enter a username" delegate:self cancelButtonTitle:@"Try again" otherButtonTitles:nil];
            [alert show];
            return;
        }
        if ([emailField.text length] == 0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please enter your email address" delegate:self cancelButtonTitle:@"Try again" otherButtonTitles:nil];
            [alert show];
            return;
        }
        if ([passwordField.text length] < 5) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Password must be at least 5 characters" delegate:self cancelButtonTitle:@"Try again" otherButtonTitles:nil];
            [alert show];
            return;
        }
        if (![passwordField.text isEqualToString:passwordAgainField.text]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Passwords don't match" delegate:self cancelButtonTitle:@"Try again" otherButtonTitles:nil];
            [alert show];
            return;
        }
        NSURL *url = [NSURL URLWithString:@"http://retuneapp.com/getAuth/"];
        __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setCompletionBlock:^{
            NSString *responseString = [request responseString];
            NSString* auth = [self sha1:[NSString stringWithFormat:@"%@%@",@"a4h398d",responseString]];
            NSURL *registerURL = [NSURL URLWithString:@"http://retuneapp.com/register/"];
            __weak ASIFormDataRequest *registerRequest = [ASIFormDataRequest requestWithURL:registerURL];
            [registerRequest setPostValue:usernameField.text forKey:@"username"];
            [registerRequest setPostValue:passwordField.text forKey:@"password"];
            [registerRequest setPostValue:emailField.text forKey:@"email"];
            [registerRequest setPostValue:auth forKey:@"auth"];
            [registerRequest setCompletionBlock:^{
                NSString *registerResponse = [registerRequest responseString];
                if ([registerResponse isEqualToString:@"OK"]) {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
            [registerRequest startAsynchronous];
        }];
        [request startAsynchronous];
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
