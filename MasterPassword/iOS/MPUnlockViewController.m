//
//  MBUnlockViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 22/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "MPUnlockViewController.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "MPElementEntity.h"

typedef enum {
    MPLockscreenIdle,
    MPLockscreenError,
    MPLockscreenSuccess,
    MPLockscreenProgress,
} MPLockscreen;

@interface MPUnlockViewController ()

@end

@implementation MPUnlockViewController
@synthesize lock;
@synthesize spinner;
@synthesize field;
@synthesize messageLabel;
@synthesize changeMPView;

- (void)showMessage:(NSString *)message state:(MPLockscreen)state {
    
    __block void(^showMessageAnimation)(void) = ^{
        self.lock.alpha = 0.0f;
        switch (state) {
            case MPLockscreenIdle:
                [self.lock setImage:[UIImage imageNamed:@"lock_idle"]];
                break;
            case MPLockscreenError:
                [self.lock setImage:[UIImage imageNamed:@"lock_red"]];
                break;
            case MPLockscreenSuccess:
                [self.lock setImage:[UIImage imageNamed:@"lock_green"]];
                break;
            case MPLockscreenProgress:
                [self.lock setImage:[UIImage imageNamed:@"lock_blue"]];
                break;
        }
        
        self.lock.alpha = 0.0f;
        [UIView animateWithDuration:1.0f animations:^{
            self.lock.alpha = 1.0f;
        } completion:^(BOOL finished) {
            if (finished)
                [UIView animateWithDuration:1.0f delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
                    self.lock.alpha = 0.5f;
                } completion:nil];
        }];
        
        [UIView animateWithDuration:0.5f animations:^{
            self.messageLabel.alpha = 1.0f;
            self.messageLabel.text = message;
        }];
    };
    
    if (self.messageLabel.alpha)
        [UIView animateWithDuration:0.3f animations:^{
            self.messageLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            if (finished)
                showMessageAnimation();
        }];
    else
        showMessageAnimation();
}

- (void)hideMessage {
    
    [UIView animateWithDuration:0.5f animations:^{
        self.messageLabel.alpha = 0.0f;
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    
    self.messageLabel.text = nil;
    self.messageLabel.alpha = 0;
    self.changeMPView.alpha = 0;
    self.spinner.alpha = 0;
    self.field.text = nil;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MPNotificationKeyForgotten
                                                      object:nil queue:nil usingBlock:^(NSNotification *note) {
                                                          [self.field becomeFirstResponder];
                                                      }];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    
    [self setSpinner:nil];
    [self setField:nil];
    
    [self setMessageLabel:nil];
    [self setLock:nil];
    [self setChangeMPView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [self.field becomeFirstResponder];
    
    [super viewDidAppear:animated];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if ([textField.text length]) {
        [textField resignFirstResponder];
        return YES;
    }
    
    return NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            dispatch_async(dispatch_get_main_queue(), ^{
                CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
                rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
                rotate.fromValue = [NSNumber numberWithFloat:0];
                rotate.toValue = [NSNumber numberWithFloat:2 * M_PI];
                rotate.repeatCount = MAXFLOAT;
                rotate.duration = 3.0;
                
                [self.spinner.layer removeAllAnimations];
                [self.spinner.layer addAnimation:rotate forKey:@"transform"];
                
                [UIView animateWithDuration:0.3f animations:^{
                    self.spinner.alpha = 1.0f;
                }];
                
                [self showMessage:@"Checking password..." state:MPLockscreenProgress];
            });
            
            if ([[MPAppDelegate get] tryMasterPassword:textField.text])
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showMessage:@"Success!" state:MPLockscreenSuccess];
                    
                    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
                    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %@", [MPAppDelegate get].keyID];
                    fetchRequest.fetchLimit = 1;
                    BOOL keyIDHasElements = [[[MPAppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:nil] count] > 0;
                    if (keyIDHasElements)
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (long)(NSEC_PER_SEC * 1.5f)), dispatch_get_main_queue(), ^{
                            [self dismissModalViewControllerAnimated:YES];
                        });
                    else {
                        [PearlAlert showAlertWithTitle:@"New Master Password"
                                               message:
                         @"Please confirm the spelling of this new master password."
                                             viewStyle:UIAlertViewStyleSecureTextInput
                                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                         if (buttonIndex == [alert cancelButtonIndex]) {
                                             [[MPAppDelegate get] updateKey:nil];
                                             return;
                                         }
                                         if (![[alert textFieldAtIndex:0].text isEqualToString:textField.text]) {
                                             [PearlAlert showAlertWithTitle:@"Incorrect Master Password"
                                                                    message:
                                              @"The password you entered doesn't match with the master password you tried to use.  "
                                              @"You've probably mistyped one of them.\n\n"
                                              @"Give it another try."
                                                                  viewStyle:UIAlertViewStyleDefault tappedButtonBlock:nil
                                                                cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
                                             return;
                                         }
                                         [self dismissModalViewControllerAnimated:YES];
                                     }
                                           cancelTitle:[PearlStrings get].commonButtonCancel
                                           otherTitles:[PearlStrings get].commonButtonContinue, nil];
                    }
                });
            else
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showMessage:@"Not valid." state:MPLockscreenError];
                    [UIView animateWithDuration:0.5f animations:^{
                        self.changeMPView.alpha = 1.0f;
                    }];
                });
        }
        @finally {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3f animations:^{
                    self.spinner.alpha = 0.0f;
                } completion:^(BOOL finished) {
                    [self.spinner.layer removeAllAnimations];
                }];
            });
        }
    });
}

- (IBAction)changeMP {
    
    [PearlAlert showAlertWithTitle:@"Changing Master Password"
                           message:
     @"This will allow you to log in with a different master password.\n\n"
     @"Note that you will only see the sites and passwords for the master password you log in with.\n"
     @"If you log in with a different master password, your current sites will be unavailable.\n\n"
     @"You can always change back to your current master password later.\n"
     @"Your current sites and passwords will then become available again."
                         viewStyle:UIAlertViewStyleDefault
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex])
                         return;
                     
                     [[MPAppDelegate get] forgetKey];
                     [[MPAppDelegate get] loadKey:YES];
                     
                     [TestFlight passCheckpoint:MPTestFlightCheckpointMPChanged];
                 }
                       cancelTitle:[PearlStrings get].commonButtonAbort
                       otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

@end
