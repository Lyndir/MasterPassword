/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  MPCombinedViewController.h
//  MPCombinedViewController
//
//  Created by lhunath on 2014-03-08.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPEmergencyViewController.h"
#import "MPEntities.h"
#import "MPAvatarCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"
#import "MPEmergencySegue.h"

@implementation MPEmergencyViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
    self.emergencyGeneratorDialog.layer.cornerRadius = 5;
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {

    return [self respondsToSelector:action];
}

#pragma mark - Actions

- (IBAction)unwindToCombined:(UIStoryboardSegue *)sender {

    dbg(@"unwindToCombined:%@", sender);
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];
    return YES;
}

// This isn't really in UITextFieldDelegate.  We fake it from UITextFieldTextDidChangeNotification.
- (void)textFieldEditingChanged:(UITextField *)textField {

}

#pragma mark - Actions

- (IBAction)emergencyClose:(id)sender {

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)emergencyCopy:(id)sender {
}

@end
