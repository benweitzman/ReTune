//
//  RegisterViewController.h
//  ReTune
//
//  Created by Ben Weitzman on 8/7/12.
//
//

#import <UIKit/UIKit.h>
#import "UIPlaceHolderTextView.h"


@interface RegisterViewController : UITableViewController <UITextFieldDelegate>
{
    UITextField* usernameField;
    UITextField* passwordField;
    UITextField* passwordAgainField;
    UITextField* emailField;

}
@end
