//
//  MBUnlockViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 22/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPUnlockViewController : UIViewController <UITextFieldDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UIScrollView *usersView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *oldUsernameLabel;
@property (weak, nonatomic) IBOutlet UIButton *userButtonTemplate;
@property (weak, nonatomic) IBOutlet UILabel *deleteTip;

- (IBAction)deleteTargetedUser:(UILongPressGestureRecognizer *)sender;

@end
