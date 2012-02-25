//
//  MBUnlockViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 22/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPUnlockViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *lock;
@property (weak, nonatomic) IBOutlet UIImageView *spinner;
@property (weak, nonatomic) IBOutlet UITextField *field;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *changeMPView;

- (IBAction)changeMP;

@end
