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
#import "MPEntities.h"

@interface MPUnlockViewController ()

@property (strong, nonatomic) MPUserEntity *selectedUser;
@property (strong, nonatomic) NSMutableDictionary *avatarToUser;

@end

@implementation MPUnlockViewController
@synthesize selectedUser;
@synthesize avatarToUser;
@synthesize spinner;
@synthesize passwordField;
@synthesize passwordView;
@synthesize usersView;
@synthesize usernameLabel, oldUsernameLabel;
@synthesize userButtonTemplate;
@synthesize deleteTip;

//    [UIView animateWithDuration:1.0f delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
//        self.lock.alpha = 0.5f;
//    } completion:nil];

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    
    self.avatarToUser = [NSMutableDictionary dictionaryWithCapacity:3];
    
    self.spinner.alpha = 0;
    self.passwordField.text = nil;
    self.usersView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.usersView.clipsToBounds = NO;
    self.usernameLabel.layer.cornerRadius = 5;
    self.userButtonTemplate.hidden = YES;

    [self updateLayoutAnimated:NO allowScroll:YES completion:nil];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    
    [self setSpinner:nil];
    [self setPasswordField:nil];
    [self setPasswordView:nil];
    [self setUsersView:nil];
    [self setUsernameLabel:nil];
    [self setUserButtonTemplate:nil];
    [self setDeleteTip:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {

    self.selectedUser = nil;
    [self updateUsers];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];
    
    [super viewWillDisappear:animated];
}

- (void)updateUsers {

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPUserEntity class])];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO]];
    NSArray *users = [[MPAppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:nil];

    // Clean up avatars.
    for (UIView *view in [self.usersView subviews])
        if (view != self.userButtonTemplate)
            [view removeFromSuperview];
    [self.avatarToUser removeAllObjects];

    // Create avatars.
    for (MPUserEntity *user in users)
        [self setupAvatar:[PearlUIUtils copyOf:self.userButtonTemplate] forUser:user];
    [self setupAvatar:[PearlUIUtils copyOf:self.userButtonTemplate] forUser:nil];

    // Scroll view's content changed, update its content size.
    [PearlUIUtils autoSizeContent:self.usersView ignoreHidden:YES ignoreInvisible:YES limitPadding:NO ignoreSubviews:nil];

    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];

    self.deleteTip.alpha = 0;
    if ([users count] > 1)
        [UIView animateWithDuration:0.5f animations:^{
            self.deleteTip.alpha = 1;
        }];
}

- (UIButton *)setupAvatar:(UIButton *)avatar forUser:(MPUserEntity *)user {

    [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
        if (highlighted || selected)
            avatar.backgroundColor = self.userButtonTemplate.backgroundColor;
        else
            avatar.backgroundColor = [UIColor clearColor];
    } options:0];
    [avatar onSelect:^(BOOL selected) {
        self.selectedUser = selected? user: nil;
        if (user)
            [self didToggleUserSelection];
        else if (selected)
            [self didSelectNewUserAvatar:avatar];
    } options:0];
    avatar.toggleSelectionWhenTouchedInside = YES;
    avatar.center = CGPointMake(avatar.center.x + [self.avatarToUser count] * 160, avatar.center.y);
    avatar.hidden = NO;
    avatar.layer.cornerRadius = 5;
    avatar.layer.shadowColor = [UIColor blackColor].CGColor;
    avatar.layer.shadowOpacity = 1;
    avatar.layer.shadowRadius = 20;
    avatar.layer.masksToBounds = NO;
    avatar.backgroundColor = [UIColor clearColor];

    if (user)
        [self.avatarToUser setObject:user forKey:[NSValue valueWithNonretainedObject:avatar]];

    if (self.selectedUser && user == self.selectedUser)
        avatar.selected = YES;

    return avatar;
}

- (void)didToggleUserSelection {

    if (!self.selectedUser)
        [self.passwordField resignFirstResponder];

    [self updateLayoutAnimated:YES allowScroll:YES completion:^(BOOL finished) {
        if (finished)
            if (self.selectedUser)
                [self.passwordField becomeFirstResponder];
    }];
}

- (void)didSelectNewUserAvatar:(UIButton *)newUserAvatar {

        [PearlAlert showAlertWithTitle:@"New User"
                               message:@"Enter your name:" viewStyle:UIAlertViewStylePlainTextInput
                             initAlert:^(UIAlertView *alert, UITextField *firstField) {
                                 firstField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                                 firstField.autocorrectionType = UITextAutocorrectionTypeYes;
                                 firstField.spellCheckingType = UITextSpellCheckingTypeYes;
                                 firstField.keyboardType = UIKeyboardTypeAlphabet;
                             }
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         newUserAvatar.selected = NO;

                         if (buttonIndex == [alert cancelButtonIndex])
                             return;

                         MPUserEntity *newUser = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPUserEntity class])
                                                                            inManagedObjectContext:[MPAppDelegate managedObjectContext]];
                         newUser.name = [alert textFieldAtIndex:0].text;
                         self.selectedUser = newUser;

                         [self updateUsers];
                     }
                           cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonSave, nil];
}

- (void)updateLayoutAnimated:(BOOL)animated allowScroll:(BOOL)allowScroll completion:(void (^)(BOOL finished))completion {

    if (animated) {
        self.oldUsernameLabel.text = self.usernameLabel.text;
        self.oldUsernameLabel.alpha = 1;
        self.usernameLabel.alpha = 0;

        [UIView animateWithDuration:0.5f animations:^{
            [self updateLayoutAnimated:NO allowScroll:allowScroll completion:nil];

            self.oldUsernameLabel.alpha = 0;
            self.usernameLabel.alpha = 1;
        } completion:^(BOOL finished) {
            if (completion)
                completion(finished);
        }];
        return;
    }
    
    if (self.selectedUser && !self.passwordView.alpha) {
        self.passwordView.alpha = 1;
        self.usersView.center = CGPointMake(160, 100);
        self.usersView.scrollEnabled = NO;
        self.usernameLabel.center = CGPointMake(160, 84);
        self.usernameLabel.backgroundColor = [UIColor blackColor];
        self.oldUsernameLabel.center = self.usernameLabel.center;
    } else if (self.passwordView.alpha == 1) {
        self.passwordView.alpha = 0;
        self.usersView.center = CGPointMake(160, 240);
        self.usersView.scrollEnabled = YES;
        self.usernameLabel.center = CGPointMake(160, 296);
        self.usernameLabel.backgroundColor = [UIColor clearColor];
        self.oldUsernameLabel.center = self.usernameLabel.center;
    }

    MPUserEntity *targetedUser = self.selectedUser;
    UIButton *selectedAvatar = [self avatarForUser:self.selectedUser];
    UIButton *targetedAvatar = selectedAvatar;
    if (!targetedAvatar) {
        targetedAvatar = [self findTargetedAvatar];
        targetedUser = [self userForAvatar:targetedAvatar];
    }

    [self.usersView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        const BOOL isTargeted = subview == targetedAvatar;

        subview.userInteractionEnabled = isTargeted;
        subview.alpha = isTargeted ? 1: self.selectedUser? 0.1: 0.4;
        if (!isTargeted && [subview.layer animationForKey:@"targetedShadow"]) {
            CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            toShadowColorAnimation.toValue = (__bridge id)[UIColor blackColor].CGColor;
            toShadowColorAnimation.duration = 0.5f;

            CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            toShadowOpacityAnimation.toValue = PearlFloat(1);
            toShadowOpacityAnimation.duration = 0.5f;

            CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
            group.animations = [NSArray arrayWithObjects:toShadowColorAnimation, toShadowOpacityAnimation, nil];
            group.duration = 0.5f;

            [subview.layer removeAnimationForKey:@"targetedShadow"];
            [subview.layer addAnimation:group forKey:@"inactiveShadow"];
        }
    } recurse:NO];

    if (![targetedAvatar.layer animationForKey:@"targetedShadow"]) {
        CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
        toShadowColorAnimation.toValue = (__bridge id)[UIColor whiteColor].CGColor;
        toShadowColorAnimation.beginTime = 0.0f;
        toShadowColorAnimation.duration = 0.5f;
        toShadowColorAnimation.fillMode = kCAFillModeForwards;

        CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        toShadowOpacityAnimation.toValue = PearlFloat(0.2);
        toShadowOpacityAnimation.duration = 0.5f;

        CABasicAnimation *pulseShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        pulseShadowOpacityAnimation.fromValue = PearlFloat(0.2);
        pulseShadowOpacityAnimation.toValue = PearlFloat(0.6);
        pulseShadowOpacityAnimation.beginTime = 0.5f;
        pulseShadowOpacityAnimation.duration = 2.0f;
        pulseShadowOpacityAnimation.autoreverses = YES;
        pulseShadowOpacityAnimation.repeatCount = NSIntegerMax;

        CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
        group.animations = [NSArray arrayWithObjects:toShadowColorAnimation, toShadowOpacityAnimation, pulseShadowOpacityAnimation, nil];
        group.duration = CGFLOAT_MAX;

        [targetedAvatar.layer removeAnimationForKey:@"inactiveShadow"];
        [targetedAvatar.layer addAnimation:group forKey:@"targetedShadow"];
    }

    if (allowScroll) {
        CGPoint targetContentOffset = CGPointMake(targetedAvatar.center.x - self.usersView.bounds.size.width / 2, self.usersView.contentOffset.y);
        if (!CGPointEqualToPoint(self.usersView.contentOffset, targetContentOffset))
            [self.usersView setContentOffset:targetContentOffset animated:animated];
    }

    self.usernameLabel.text = targetedUser? targetedUser.name: @"New User";
    self.usernameLabel.bounds = CGRectSetHeight(self.usernameLabel.bounds,
            [self.usernameLabel.text sizeWithFont:self.usernameLabel.font
                                constrainedToSize:CGSizeMake(self.usernameLabel.bounds.size.width - 10, 100)
                                    lineBreakMode:self.usernameLabel.lineBreakMode].height);
    self.oldUsernameLabel.bounds = self.usernameLabel.bounds;
    if (completion)
        completion(YES);
}

- (UIButton *)findTargetedAvatar {

    CGFloat xOfMiddle = self.usersView.contentOffset.x + self.usersView.bounds.size.width / 2;
    return (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, self.usersView.contentOffset.y) ofArray:self.usersView.subviews];
}

- (UIButton *)avatarForUser:(MPUserEntity *)user {

    __block UIButton *avatar = nil;
    if (user)
        [self.avatarToUser enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (obj == user)
                avatar = [key nonretainedObjectValue];
        }];

    return avatar;
}

- (MPUserEntity *)userForAvatar:(UIButton *)avatar {

    return NullToNil([self.avatarToUser objectForKey:[NSValue valueWithNonretainedObject:avatar]]);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (![textField.text length])
        return NO;
    
    [textField resignFirstResponder];
    
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
    
    //    [self showMessage:@"Checking password..." state:MPLockscreenProgress];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL unlocked = [[MPAppDelegate get] tryMasterPassword:textField.text forUser:self.selectedUser];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (unlocked) {
                //                [self showMessage:@"Success!" state:MPLockscreenSuccess];
                if ([selectedUser.keyID length])
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (long)(NSEC_PER_SEC * 1.5f)), dispatch_get_main_queue(), ^{
                        [self dismissModalViewControllerAnimated:YES];
                    });
                else {
                    [PearlAlert showAlertWithTitle:@"New Master Password"
                                           message:@"Please confirm the spelling of this new master password."
                                         viewStyle:UIAlertViewStyleSecureTextInput
                                         initAlert:nil
                                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                     if (buttonIndex == [alert cancelButtonIndex]) {
                                         [[MPAppDelegate get] unsetKey];
                                         return;
                                     }
                                     
                                     if (![[alert textFieldAtIndex:0].text isEqualToString:textField.text]) {
                                         [PearlAlert showAlertWithTitle:@"Incorrect Master Password"
                                                                message:
                                          @"The password you entered doesn't match with the master password you tried to use.  "
                                          @"You've probably mistyped one of them.\n\n"
                                          @"Give it another try."
                                                              viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                                                            cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
                                         return;
                                     }
                                     
                                     self.selectedUser.keyID = [MPAppDelegate get].activeUser.keyID;
                                     [[MPAppDelegate get] saveContext];
                                     
                                     [self dismissModalViewControllerAnimated:YES];
                                 }
                                       cancelTitle:[PearlStrings get].commonButtonCancel
                                       otherTitles:[PearlStrings get].commonButtonContinue, nil];
                }
            } else {
                //                [self showMessage:@"Not valid." state:MPLockscreenError];
                
                [UIView animateWithDuration:0.5f animations:^{
                    //                    self.changeMPView.alpha = 1.0f;
                }];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3f animations:^{
                    self.spinner.alpha = 0.0f;
                } completion:^(BOOL finished) {
                    [self.spinner.layer removeAllAnimations];
                }];
            });
        });
    });
    
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    CGFloat xOfMiddle = targetContentOffset->x + scrollView.bounds.size.width / 2;
    UIButton *middleAvatar = (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, targetContentOffset->y) ofArray:scrollView.subviews];
    *targetContentOffset = CGPointMake(middleAvatar.center.x - scrollView.bounds.size.width / 2, targetContentOffset->y);

    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
//    [self scrollToAvatar:middleAvatar animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];
//    [self scrollToAvatar:middleAvatar animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
//    CGFloat xOfMiddle = scrollView.contentOffset.x + scrollView.bounds.size.width / 2;
//    UIButton *middleAvatar = (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, scrollView.contentOffset.y) ofArray:scrollView.subviews];
//
    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
//    [self scrollToAvatar:middleAvatar animated:NO];
}

#pragma mark - IBActions

- (IBAction)changeMP {
    
    [PearlAlert showAlertWithTitle:@"Changing Master Password"
                           message:
     @"This will allow you to log in with a different master password.\n\n"
     @"Note that you will only see the sites and passwords for the master password you log in with.\n"
     @"If you log in with a different master password, your current sites will be unavailable.\n\n"
     @"You can always change back to your current master password later.\n"
     @"Your current sites and passwords will then become available again."
                         viewStyle:UIAlertViewStyleDefault
                         initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex])
                         return;
                     
                     [[MPAppDelegate get] forgetSavedKey];
                     [[MPAppDelegate get] loadKey:YES];
                     
                     [TestFlight passCheckpoint:MPTestFlightCheckpointMPChanged];
                 }
                       cancelTitle:[PearlStrings get].commonButtonAbort
                       otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

- (IBAction)deleteTargetedUser:(UILongPressGestureRecognizer *)sender {
    
    if (sender.state != UIGestureRecognizerStateBegan)
        return;
    
    if (self.selectedUser)
        return;
    
    MPUserEntity *targetedUser = [self userForAvatar:[self findTargetedAvatar]];
    if (!targetedUser)
        return;
    
    [PearlAlert showAlertWithTitle:@"Delete User" message:
     PearlString(@"Do you want to delete all record of the following user?\n\n%@", targetedUser.name)
                         viewStyle:UIAlertViewStyleDefault
                         initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex])
                         return;
                     
                     [[MPAppDelegate get].managedObjectContext deleteObject:targetedUser];
                     [[MPAppDelegate get] saveContext];
                     
                     [self updateUsers];
                 } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Delete", nil];
}
@end
