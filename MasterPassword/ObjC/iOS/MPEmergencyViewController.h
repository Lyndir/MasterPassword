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


@interface MPEmergencyViewController : UIViewController <UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UIView *dialogView;
@property(weak, nonatomic) IBOutlet UIView *containerView;
@property(weak, nonatomic) IBOutlet UITextField *userNameField;
@property(weak, nonatomic) IBOutlet UITextField *masterPasswordField;
@property(weak, nonatomic) IBOutlet UITextField *siteField;
@property(weak, nonatomic) IBOutlet UIStepper *counterStepper;
@property(weak, nonatomic) IBOutlet UISegmentedControl *typeControl;
@property(weak, nonatomic) IBOutlet UILabel *counterLabel;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property(weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property(weak, nonatomic) IBOutlet UIView *tipContainer;

- (IBAction)controlChanged:(UIControl *)control;
- (IBAction)copyPassword:(UITapGestureRecognizer *)recognizer;

@end
