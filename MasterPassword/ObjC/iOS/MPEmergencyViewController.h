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

#import "LLGitTip.h"

@interface MPEmergencyViewController : UIViewController <UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UIView *emergencyGeneratorDialog;
@property(weak, nonatomic) IBOutlet UIView *emergencyGeneratorContainer;
@property(weak, nonatomic) IBOutlet UITextField *emergencyName;
@property(weak, nonatomic) IBOutlet UITextField *emergencyMasterPassword;
@property(weak, nonatomic) IBOutlet UITextField *emergencySite;
@property(weak, nonatomic) IBOutlet UIStepper *emergencyCounterStepper;
@property(weak, nonatomic) IBOutlet UISegmentedControl *emergencyTypeControl;
@property(weak, nonatomic) IBOutlet UILabel *emergencyCounter;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *emergencyActivity;
@property(weak, nonatomic) IBOutlet UIButton *emergencyPassword;
@property(weak, nonatomic) IBOutlet UIView *emergencyContentTipContainer;

- (IBAction)emergencyCopy:(id)sender;

@end
