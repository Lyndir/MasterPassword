//
//  MBUnlockViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 22/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLGitTip.h"

@interface MPUnlockViewController : UIViewController<UITextFieldDelegate, UIScrollViewDelegate, UIWebViewDelegate>

@property(weak, nonatomic) IBOutlet UIImageView *spinner;
@property(weak, nonatomic) IBOutlet UILabel *passwordFieldLabel;
@property(weak, nonatomic) IBOutlet UITextField *passwordField;
@property(weak, nonatomic) IBOutlet UIView *passwordView;
@property(weak, nonatomic) IBOutlet UIScrollView *avatarsView;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *oldNameLabel;
@property(weak, nonatomic) IBOutlet UIButton *avatarTemplate;
@property(weak, nonatomic) IBOutlet UIView *createPasswordTipView;
@property(weak, nonatomic) IBOutlet UILabel *tip;
@property(weak, nonatomic) IBOutlet UIView *passwordTipView;
@property(weak, nonatomic) IBOutlet UILabel *passwordTipLabel;
@property(weak, nonatomic) IBOutlet UIView *wordWall;
@property(strong, nonatomic) IBOutlet UILongPressGestureRecognizer *targetedUserActionGesture;
@property(weak, nonatomic) IBOutlet UIView *uiContainer;
@property(weak, nonatomic) IBOutlet UIView *shareContainer;
@property(weak, nonatomic) IBOutlet UIView *tipsTipContainer;
@property(weak, nonatomic) IBOutlet LLGitTip *gitTipButton;
@property(weak, nonatomic) IBOutlet UIWebView *newsView;
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

- (IBAction)targetedUserAction:(UILongPressGestureRecognizer *)sender;
- (IBAction)facebook:(id)sender;
- (IBAction)twitter:(id)sender;
- (IBAction)google:(id)sender;
- (IBAction)mail:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)emergencyOpen:(id)sender;
- (IBAction)emergencyClose:(id)sender;
- (IBAction)emergencyCopy:(id)sender;

@end
