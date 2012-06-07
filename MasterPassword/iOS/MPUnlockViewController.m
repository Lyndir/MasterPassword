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

@interface MPUnlockViewController ()

@property(strong, nonatomic) MPUserEntity *selectedUser;
@property(strong, nonatomic) NSMutableDictionary *avatarToUser;

@end

@implementation MPUnlockViewController
@synthesize selectedUser;
@synthesize avatarToUser;
@synthesize spinner;
@synthesize passwordField;
@synthesize passwordView;
@synthesize avatarsView;
@synthesize nameLabel, oldNameLabel;
@synthesize avatarTemplate;
@synthesize deleteTip;
@synthesize passwordTipView;
@synthesize passwordTipLabel;
@synthesize avatarShadowColor = _avatarShadowColor;


//    [UIView animateWithDuration:1.0f delay:0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
//        self.lock.alpha = 0.5f;
//    } completion:nil];

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    
    self.avatarToUser = [NSMutableDictionary dictionaryWithCapacity:3];
    
    self.passwordField.text = nil;
    self.avatarsView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.avatarsView.clipsToBounds = NO;
    self.nameLabel.layer.cornerRadius = 5;
    self.avatarTemplate.hidden = YES;
    self.spinner.alpha = 0;
    self.passwordTipView.alpha = 0;

    [self updateLayoutAnimated:NO allowScroll:YES completion:nil];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    
    [self setSpinner:nil];
    [self setPasswordField:nil];
    [self setPasswordView:nil];
    [self setAvatarsView:nil];
    [self setNameLabel:nil];
    [self setAvatarTemplate:nil];
    [self setDeleteTip:nil];
    [self setPasswordTipView:nil];
    [self setPasswordTipLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.selectedUser = nil;
    [self updateUsers];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
    
    [super viewWillDisappear:animated];
}

- (void)updateUsers {

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPUserEntity class])];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO]];
    NSArray *users = [[MPAppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:nil];
    
    // Clean up avatars.
    for (UIView *subview in [self.avatarsView subviews])
        if ([[self.avatarToUser allKeys] containsObject:[NSValue valueWithNonretainedObject:subview]])
            // This subview is a former avatar.
            [subview removeFromSuperview];
    [self.avatarToUser removeAllObjects];

    // Create avatars.
    for (MPUserEntity *user in users)
        [self setupAvatar:[self.avatarTemplate clone] forUser:user];
    [self setupAvatar:[self.avatarTemplate clone] forUser:nil];

    // Scroll view's content changed, update its content size.
    [self.avatarsView autoSizeContentIgnoreHidden:YES ignoreInvisible:YES limitPadding:NO ignoreSubviews:nil];
    
    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];
}

- (UIButton *)setupAvatar:(UIButton *)avatar forUser:(MPUserEntity *)user {
    
    [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
        if (highlighted || selected)
            avatar.backgroundColor = self.avatarTemplate.backgroundColor;
        else
            avatar.backgroundColor = [UIColor clearColor];
    } options:0];
    [avatar onSelect:^(BOOL selected) {
        self.selectedUser = selected ? user : nil;
        if (user)
            [self didToggleUserSelection];
        else if (selected)
            [self didSelectNewUserAvatar:avatar];
    } options:0];
    avatar.togglesSelectionInSuperview = YES;
    avatar.center = CGPointMake(avatar.center.x + [self.avatarToUser count] * 160, avatar.center.y);
    avatar.hidden = NO;
    avatar.layer.cornerRadius = avatar.bounds.size.height / 2;
    avatar.layer.shadowColor = [UIColor blackColor].CGColor;
    avatar.layer.shadowOpacity = 1;
    avatar.layer.shadowRadius = 20;
    avatar.layer.masksToBounds = NO;
    avatar.backgroundColor = [UIColor clearColor];
    
    dbg(@"User: %@, avatar: %d", user.name, user.avatar);
    avatar.tag = user.avatar;
    [avatar setBackgroundImage:[UIImage imageNamed:PearlString(@"avatar-%u", user.avatar)]
                      forState:UIControlStateNormal];
    
    [self.avatarToUser setObject:NilToNSNull(user) forKey:[NSValue valueWithNonretainedObject:avatar]];
    
    if (self.selectedUser && user == self.selectedUser)
        avatar.selected = YES;
    
    return avatar;
}

- (void)didToggleUserSelection {
    
    if (!self.selectedUser)
        [self.passwordField resignFirstResponder];
    else if ([[MPAppDelegate get] signInAsUser:self.selectedUser usingMasterPassword:nil]) {
        [self dismissModalViewControllerAnimated:YES];
        return;
    }

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
        self.oldNameLabel.text = self.nameLabel.text;
        self.oldNameLabel.alpha = 1;
        self.nameLabel.alpha = 0;
        
        [UIView animateWithDuration:0.5f animations:^{
            [self updateLayoutAnimated:NO allowScroll:allowScroll completion:nil];
            
            self.oldNameLabel.alpha = 0;
            self.nameLabel.alpha = 1;
        } completion:^(BOOL finished) {
            if (completion)
                completion(finished);
        }];
        return;
    }
    
    if (self.selectedUser && !self.passwordView.alpha) {
        self.passwordView.alpha = 1;
        self.avatarsView.center = CGPointMake(160, 100);
        self.avatarsView.scrollEnabled = NO;
        self.nameLabel.center = CGPointMake(160, 84);
        self.nameLabel.backgroundColor = [UIColor blackColor];
        self.oldNameLabel.center = self.nameLabel.center;
        self.avatarShadowColor = [UIColor whiteColor];
        self.deleteTip.alpha = 0;
    } else if (!self.selectedUser && self.passwordView.alpha == 1) {
        self.passwordView.alpha = 0;
        self.avatarsView.center = CGPointMake(160, 240);
        self.avatarsView.scrollEnabled = YES;
        self.nameLabel.center = CGPointMake(160, 296);
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.oldNameLabel.center = self.nameLabel.center;
        self.avatarShadowColor = [UIColor lightGrayColor];
        self.deleteTip.alpha = [self.avatarToUser count] > 2? 1: 0;
    }

    MPUserEntity *targetedUser = self.selectedUser;
    UIButton *selectedAvatar = [self avatarForUser:self.selectedUser];
    UIButton *targetedAvatar = selectedAvatar;
    if (!targetedAvatar) {
        targetedAvatar = [self findTargetedAvatar];
        targetedUser = [self userForAvatar:targetedAvatar];
    }
    
    [self.avatarsView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if (![[self.avatarToUser allKeys] containsObject:[NSValue valueWithNonretainedObject:subview]])
            // This subview is not one of the user avatars.
            return;
        UIButton *avatar = (UIButton *)subview;

        BOOL isTargeted = avatar == targetedAvatar;

        avatar.userInteractionEnabled = isTargeted;
        avatar.alpha = isTargeted ? 1 : self.selectedUser ? 0.1 : 0.4;
        
        [self updateAvatarShadowColor:avatar isTargeted:isTargeted];
    } recurse:NO];
    
    if (allowScroll) {
        CGPoint targetContentOffset = CGPointMake(MAX(0, targetedAvatar.center.x - self.avatarsView.bounds.size.width / 2),
                self.avatarsView.contentOffset.y);
        if (!CGPointEqualToPoint(self.avatarsView.contentOffset, targetContentOffset))
            [self.avatarsView setContentOffset:targetContentOffset animated:animated];
    }

    self.nameLabel.text = targetedUser ? targetedUser.name : @"New User";
    self.nameLabel.bounds = CGRectSetHeight(self.nameLabel.bounds,
                                            [self.nameLabel.text sizeWithFont:self.nameLabel.font
                                                            constrainedToSize:CGSizeMake(self.nameLabel.bounds.size.width - 10, 100)
                                                                lineBreakMode:self.nameLabel.lineBreakMode].height);
    self.oldNameLabel.bounds = self.nameLabel.bounds;
    if (completion)
        completion(YES);
}

- (void)setPasswordTip:(NSString *)string {

    if (string.length)
        self.passwordTipLabel.text = string;

    [UIView animateWithDuration:0.3f animations:^{
        self.passwordTipView.alpha = string.length? 1: 0;
    }];
}

- (void)tryMasterPassword {
    
    [self setSpinnerActive:YES];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL unlocked = [[MPAppDelegate get] signInAsUser:self.selectedUser usingMasterPassword:self.passwordField.text];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (unlocked) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (long) (NSEC_PER_SEC * 0.5f)), dispatch_get_main_queue(), ^{
                    [self dismissModalViewControllerAnimated:YES];
                });
            } else if (self.passwordField.text.length)
                [self setPasswordTip:@"Incorrect password."];
            
            [self setSpinnerActive:NO];
        });
    });
}

- (UIButton *)findTargetedAvatar {
    
    CGFloat xOfMiddle = self.avatarsView.contentOffset.x + self.avatarsView.bounds.size.width / 2;
    return (UIButton *) [PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, self.avatarsView.contentOffset.y) ofArray:self.avatarsView.subviews];
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
    
    return NSNullToNil([self.avatarToUser objectForKey:[NSValue valueWithNonretainedObject:avatar]]);
}

- (void)setSpinnerActive:(BOOL)active {

    PearlMainThread(^{
        CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        rotate.toValue = [NSNumber numberWithDouble:2 * M_PI];
        rotate.duration = 5.0;

        if (active) {
            rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            rotate.fromValue = [NSNumber numberWithFloat:0];
            rotate.repeatCount = MAXFLOAT;
        } else {
            rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            rotate.repeatCount = 1;
        }

        [self.spinner.layer removeAnimationForKey:@"rotation"];
        [self.spinner.layer addAnimation:rotate forKey:@"rotation"];

        [UIView animateWithDuration:0.3f animations:^{
            self.spinner.alpha = active? 1: 0;

            if (active)
                [self avatarForUser:self.selectedUser].backgroundColor = [UIColor clearColor];
            else
                [self avatarForUser:self.selectedUser].backgroundColor = self.avatarTemplate.backgroundColor;
        }];
    });
}

- (void)updateAvatarShadowColor:(UIButton *)avatar isTargeted:(BOOL)targeted {
    
    if (targeted) {
        if (![avatar.layer animationForKey:@"targetedShadow"]) {
            CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            toShadowColorAnimation.toValue = (__bridge id) (avatar.selected? self.avatarTemplate.backgroundColor: [UIColor whiteColor]).CGColor;
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
            pulseShadowOpacityAnimation.repeatCount = MAXFLOAT;
            
            CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
            group.animations = [NSArray arrayWithObjects:toShadowColorAnimation, toShadowOpacityAnimation, pulseShadowOpacityAnimation, nil];
            group.duration = MAXFLOAT;
            
            [avatar.layer removeAnimationForKey:@"inactiveShadow"];
            [avatar.layer addAnimation:group forKey:@"targetedShadow"];
        }
    } else {
        if ([avatar.layer animationForKey:@"targetedShadow"]) {
            CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            toShadowColorAnimation.toValue = (__bridge id) [UIColor blackColor].CGColor;
            toShadowColorAnimation.duration = 0.5f;
            
            CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            toShadowOpacityAnimation.toValue = PearlFloat(1);
            toShadowOpacityAnimation.duration = 0.5f;
            
            CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
            group.animations = [NSArray arrayWithObjects:toShadowColorAnimation, toShadowOpacityAnimation, nil];
            group.duration = 0.5f;
            
            [avatar.layer removeAnimationForKey:@"targetedShadow"];
            [avatar.layer addAnimation:group forKey:@"inactiveShadow"];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {

    [self setPasswordTip:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    
    [self setSpinnerActive:YES];

    if (self.selectedUser.keyID)
        [self tryMasterPassword];
    
    else
        [PearlAlert showAlertWithTitle:@"New Master Password"
                               message:@"Please confirm the spelling of this new master password."
                             viewStyle:UIAlertViewStyleSecureTextInput
                             initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                 [self setSpinnerActive:NO];
                                 
                                 if (buttonIndex == [alert cancelButtonIndex])
                                     return;
                                 
                                 if (![[alert textFieldAtIndex:0].text isEqualToString:textField.text]) {
                                     [PearlAlert showAlertWithTitle:@"Incorrect Master Password"
                                                            message:
                                      @"The password you entered doesn't match with the master password you tried to use.  "
                                      @"You've probably mistyped one of them.\n\n"
                                      @"Give it another try."
                                                          viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
                                     return;
                                 }
                                 
                                 [self tryMasterPassword];
                             }
                           cancelTitle:[PearlStrings get].commonButtonCancel
                           otherTitles:[PearlStrings get].commonButtonContinue, nil];
    
    
    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    CGFloat xOfMiddle = targetContentOffset->x + scrollView.bounds.size.width / 2;
    UIButton *middleAvatar = (UIButton *) [PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, targetContentOffset->y) ofArray:scrollView.subviews];
    *targetContentOffset = CGPointMake(middleAvatar.center.x - scrollView.bounds.size.width / 2, targetContentOffset->y);
    
    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
    //    [self scrollToAvatar:middleAvatar animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];
    //    [self scrollToAvatar:middleAvatar animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
}

#pragma mark - IBActions

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
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                             if (buttonIndex == [alert cancelButtonIndex])
                                 return;
                             
                             [[MPAppDelegate get].managedObjectContext deleteObject:targetedUser];
                             [[MPAppDelegate get] saveContext];
                             
                             [self updateUsers];
                         } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Delete", nil];
}
@end
