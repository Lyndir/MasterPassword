//
//  MBUnlockViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 22/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPUnlockViewController : UIViewController<UITextFieldDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView  *spinner;
@property (weak, nonatomic) IBOutlet UILabel *passwordFieldLabel;
@property (weak, nonatomic) IBOutlet UITextField  *passwordField;
@property (weak, nonatomic) IBOutlet UIView       *passwordView;
@property (weak, nonatomic) IBOutlet UIScrollView *avatarsView;
@property (weak, nonatomic) IBOutlet UILabel      *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel      *oldNameLabel;
@property (weak, nonatomic) IBOutlet UIButton     *avatarTemplate;
@property (weak, nonatomic) IBOutlet UIView *createPasswordTipView;
@property (weak, nonatomic) IBOutlet UILabel      *tip;
@property (weak, nonatomic) IBOutlet UIView       *passwordTipView;
@property (weak, nonatomic) IBOutlet UILabel      *passwordTipLabel;
@property (weak, nonatomic) IBOutlet UIView *wordWall;
@property (strong, nonatomic) IBOutlet UILongPressGestureRecognizer *targetedUserActionGesture;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingUsersIndicator;

@property (nonatomic, strong) UIColor *avatarShadowColor;

- (IBAction)targetedUserAction:(UILongPressGestureRecognizer *)sender;
- (IBAction)facebook:(UIButton *)sender;
- (IBAction)twitter:(UIButton *)sender;
- (IBAction)google:(UIButton *)sender;

@end
