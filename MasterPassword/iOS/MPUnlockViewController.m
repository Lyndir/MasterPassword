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

@property (strong, nonatomic) MPUserEntity        *selectedUser;
@property (strong, nonatomic) NSMutableDictionary *avatarToUser;
@property (nonatomic) BOOL wordWallAnimating;
@property (nonatomic, strong) NSArray *wordList;


@end

@implementation MPUnlockViewController
@synthesize selectedUser;
@synthesize avatarToUser;
@synthesize spinner;
@synthesize passwordFieldLabel;
@synthesize passwordField;
@synthesize passwordView;
@synthesize avatarsView;
@synthesize nameLabel, oldNameLabel;
@synthesize avatarTemplate;
@synthesize createPasswordTipView;
@synthesize tip;
@synthesize passwordTipView;
@synthesize passwordTipLabel;
@synthesize wordWall;
@synthesize targetedUserActionGesture;
@synthesize loadingUsersIndicator;
@synthesize avatarShadowColor = _avatarShadowColor;
@synthesize wordWallAnimating = _wordWallAnimating;
@synthesize wordList = _wordList;


- (void)initializeAvatarAlert:(UIAlertView *)alert forUser:(MPUserEntity *)user {

    UIScrollView *alertAvatarScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(12, 30, 260, 150)];
    alertAvatarScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [alertAvatarScrollView flashScrollIndicatorsContinuously];
    [alert addSubview:alertAvatarScrollView];

    CGPoint  selectedOffset = CGPointZero;
    for (int a              = 0; a < MPAvatarCount; ++a) {
        UIButton *avatar = [self.avatarTemplate cloneAddedTo:alertAvatarScrollView];

        avatar.tag    = a;
        avatar.hidden = NO;
        avatar.center = CGPointMake(
         (20 + self.avatarTemplate.bounds.size.width / 2) * (a + 1) + self.avatarTemplate.bounds.size.width / 2 * a,
         20 + self.avatarTemplate.bounds.size.height / 2);
        [avatar setBackgroundImage:[UIImage imageNamed:PearlString(@"avatar-%d", a)] forState:UIControlStateNormal];
        [avatar setSelectionInSuperviewCandidate:YES isClearable:NO];

        avatar.layer.cornerRadius  = avatar.bounds.size.height / 2;
        avatar.layer.shadowColor   = [UIColor blackColor].CGColor;
        avatar.layer.shadowOpacity = 1;
        avatar.layer.shadowRadius  = 5;
        avatar.backgroundColor     = [UIColor clearColor];

        [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
            if (highlighted || selected)
                avatar.backgroundColor = self.avatarTemplate.backgroundColor;
            else
                avatar.backgroundColor = [UIColor clearColor];
        }                   options:0];
        [avatar onSelect:^(BOOL selected) {
            if (selected)
                user.avatar = (unsigned)avatar.tag;
        }        options:0];
        avatar.selected            = (a == user.avatar);
        if (avatar.selected)
            selectedOffset = CGPointMake(avatar.center.x - alertAvatarScrollView.bounds.size.width / 2, 0);
    }

    [alertAvatarScrollView autoSizeContent];
    [alertAvatarScrollView setContentOffset:selectedOffset animated:YES];
}

- (void)initializeConfirmationAlert:(UIAlertView *)alert forUser:(MPUserEntity *)user {

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(12, 70, 260, 110)];
    [alert addSubview:container];

    UIButton *alertAvatar = [self.avatarTemplate cloneAddedTo:container];
    alertAvatar.center              = CGPointMake(130, 55);
    alertAvatar.hidden              = NO;
    alertAvatar.layer.shadowColor   = [UIColor blackColor].CGColor;
    alertAvatar.layer.shadowOpacity = 1;
    alertAvatar.layer.shadowRadius  = 5;
    alertAvatar.backgroundColor     = [UIColor clearColor];
    [alertAvatar setBackgroundImage:[UIImage imageNamed:PearlString(@"avatar-%d", user.avatar)] forState:UIControlStateNormal];

    UILabel *alertNameLabel = [self.nameLabel cloneAddedTo:container];
    alertNameLabel.center             = alertAvatar.center;
    alertNameLabel.text               = user.name;
    alertNameLabel.bounds             = CGRectSetHeight(alertNameLabel.bounds,
                                                        [alertNameLabel.text sizeWithFont:self.nameLabel.font
                                                                        constrainedToSize:CGSizeMake(alertNameLabel.bounds.size.width - 10,
                                                                                                     100)
                                                                            lineBreakMode:self.nameLabel.lineBreakMode].height);
    alertNameLabel.layer.cornerRadius = 5;
    alertNameLabel.backgroundColor    = [UIColor blackColor];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {

    self.avatarToUser = [NSMutableDictionary dictionaryWithCapacity:3];

    self.avatarsView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.avatarsView.clipsToBounds    = NO;
    self.nameLabel.layer.cornerRadius = 5;
    self.avatarTemplate.hidden        = YES;
    self.spinner.alpha                = 0;
    self.passwordTipView.alpha        = 0;
    self.createPasswordTipView.alpha  = 0;

    NSMutableArray *wordListLines = [NSMutableArray arrayWithCapacity:27413];
    [[[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"dictionary" withExtension:@"lst"]]
                           encoding:NSUTF8StringEncoding] enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        [wordListLines addObject:line];
    }];
    self.wordList = wordListLines;

    self.wordWall.alpha = 0;
    [self.wordWall enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        UILabel *wordLabel = (UILabel *)subview;

        [self initializeWordLabel:wordLabel];
    }                        recurse:NO];

    [[NSNotificationCenter defaultCenter] addObserverForName:PersistentStoreDidChange object:nil queue:nil usingBlock:
     ^(NSNotification *note) {
         [self updateUsers];
     }];
    [[NSNotificationCenter defaultCenter] addObserverForName:PersistentStoreDidMergeChanges object:nil queue:nil usingBlock:
     ^(NSNotification *note) {
         [self updateUsers];
     }];

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
    [self setTip:nil];
    [self setPasswordTipView:nil];
    [self setPasswordTipLabel:nil];
    [self setTargetedUserActionGesture:nil];
    [self setWordWall:nil];
    [self setCreatePasswordTipView:nil];
    [self setPasswordFieldLabel:nil];
    [self setLoadingUsersIndicator:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Lock screen will appear");
    self.selectedUser = nil;
    [self updateUsers];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];

    if (!animated)
        [[self findTargetedAvatar] setSelected:YES];
    else
        [self updateLayoutAnimated:YES allowScroll:YES completion:nil];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Lock screen will disappear");
    [super viewWillDisappear:animated];
}

- (void)updateUsers {

    NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextIfReady];
    if (!moc) {
        self.tip.text = @"Loading...";
        [self.loadingUsersIndicator startAnimating];
        return;
    }

    self.tip.text = @"Tap and hold to delete or reset.";
    [self.loadingUsersIndicator stopAnimating];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPUserEntity class])];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO]];
    NSArray *users = [moc executeFetchRequest:fetchRequest error:nil];

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

    avatar.center              = CGPointMake(avatar.center.x + [self.avatarToUser count] * 160, avatar.center.y);
    avatar.hidden              = NO;
    avatar.layer.cornerRadius  = avatar.bounds.size.height / 2;
    avatar.layer.shadowColor   = [UIColor blackColor].CGColor;
    avatar.layer.shadowOpacity = 1;
    avatar.layer.shadowRadius  = 20;
    avatar.layer.masksToBounds = NO;
    avatar.backgroundColor     = [UIColor clearColor];
    avatar.tag                 = user.avatar;

    [avatar setBackgroundImage:[UIImage imageNamed:PearlString(@"avatar-%u", user.avatar)]
                      forState:UIControlStateNormal];
    [avatar setSelectionInSuperviewCandidate:YES isClearable:YES];
    [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
        if (highlighted || selected)
            avatar.backgroundColor = self.avatarTemplate.backgroundColor;
        else
            avatar.backgroundColor = [UIColor clearColor];
    }                   options:0];
    [avatar onSelect:^(BOOL selected) {
        if (selected) {
            if ((self.selectedUser = user))
                [self didToggleUserSelection];
            else
                [self didSelectNewUserAvatar:avatar];
        } else {
            self.selectedUser = nil;
            [self didToggleUserSelection];
        }
    }        options:0];

    [self.avatarToUser setObject:NilToNSNull(user) forKey:[NSValue valueWithNonretainedObject:avatar]];

    if (self.selectedUser && user == self.selectedUser)
        avatar.selected = YES;

    return avatar;
}

- (void)didToggleUserSelection {

    if (!self.selectedUser)
        [self.passwordField resignFirstResponder];
    else
        if ([[MPAppDelegate get] signInAsUser:self.selectedUser usingMasterPassword:nil]) {
            [self dismissViewControllerAnimated:YES completion:nil];
            return;
        }

    [self updateLayoutAnimated:YES allowScroll:YES completion:^(BOOL finished) {
        if (finished)
            if (self.selectedUser)
                [self.passwordField becomeFirstResponder];
    }];
}

- (void)didSelectNewUserAvatar:(UIButton *)newUserAvatar {

    __block MPUserEntity *newUser = nil;
    [[MPAppDelegate managedObjectContextIfReady] performBlockAndWait:^{
        newUser = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPUserEntity class])
                                                inManagedObjectContext:[MPAppDelegate managedObjectContextIfReady]];
    }];

    [self showNewUserNameAlertFor:newUser completion:^(BOOL finished) {
        newUserAvatar.selected = NO;
        if (!finished)
            [[MPAppDelegate managedObjectContextIfReady] performBlock:^{
                [[MPAppDelegate managedObjectContextIfReady] deleteObject:newUser];
            }];
    }];
}

- (void)showNewUserNameAlertFor:(MPUserEntity *)newUser completion:(void (^)(BOOL finished))completion {

    [PearlAlert showAlertWithTitle:@"Enter Your Name"
                           message:nil viewStyle:UIAlertViewStylePlainTextInput
                         initAlert:^(UIAlertView *alert, UITextField *firstField) {
                             firstField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                             firstField.keyboardType           = UIKeyboardTypeAlphabet;
                             firstField.text                   = newUser.name;
                             firstField.placeholder            = @"eg. Robert Lee Mitchell";
                         }
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex]) {
                         completion(NO);
                         return;
                     }

                     // Save
                     newUser.name = [alert textFieldAtIndex:0].text;
                     [self showNewUserAvatarAlertFor:newUser completion:completion];
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonSave, nil];
}

- (void)showNewUserAvatarAlertFor:(MPUserEntity *)newUser completion:(void (^)(BOOL finished))completion {

    [PearlAlert showAlertWithTitle:@"Choose Your Avatar"
                           message:@"\n\n\n\n\n\n" viewStyle:UIAlertViewStyleDefault
                         initAlert:^(UIAlertView *_alert, UITextField *_firstField) {
                             [self initializeAvatarAlert:_alert forUser:newUser];
                         }
                 tappedButtonBlock:^(UIAlertView *_alert, NSInteger _buttonIndex) {

                     // Okay
                     [self showNewUserConfirmationAlertFor:newUser completion:completion];
                 }     cancelTitle:nil otherTitles:[PearlStrings get].commonButtonOkay, nil];
}

- (void)showNewUserConfirmationAlertFor:(MPUserEntity *)newUser completion:(void (^)(BOOL finished))completion {

    [PearlAlert showAlertWithTitle:@"Is this correct?"
                           message:
                            @"Please double-check your name.\n"
                             @"\n\n\n\n\n\n"
                         viewStyle:UIAlertViewStyleDefault
                         initAlert:^void(UIAlertView *__alert, UITextField *__firstField) {
                             [self initializeConfirmationAlert:__alert forUser:newUser];
                         }
                 tappedButtonBlock:^void(UIAlertView *__alert, NSInteger __buttonIndex) {
                     if (__buttonIndex == [__alert cancelButtonIndex]) {
                         [self showNewUserNameAlertFor:newUser completion:completion];
                         return;
                     }

                     // Confirm
                     completion(YES);
                     self.selectedUser = newUser;

                     [self updateUsers];
                 }
                       cancelTitle:@"Change" otherTitles:@"Confirm", nil];
}

- (void)updateLayoutAnimated:(BOOL)animated allowScroll:(BOOL)allowScroll completion:(void (^)(BOOL finished))completion {

    if (animated) {
        self.oldNameLabel.text  = self.nameLabel.text;
        self.oldNameLabel.alpha = 1;
        self.nameLabel.alpha    = 0;

        [UIView animateWithDuration:0.5f animations:^{
            [self updateLayoutAnimated:NO allowScroll:allowScroll completion:nil];

            self.oldNameLabel.alpha = 0;
            self.nameLabel.alpha    = 1;
        }                completion:^(BOOL finished) {
            if (completion)
                completion(finished);
        }];
        return;
    }

    // Lay out password entry and user selection views.
    if (self.selectedUser && !self.passwordView.alpha) {
        // User was just selected.
        self.passwordView.alpha        = 1;
        self.avatarsView.center        = CGPointMake(160, 170);
        self.avatarsView.scrollEnabled = NO;
        self.nameLabel.center          = CGPointMake(160, 84);
        self.nameLabel.backgroundColor = [UIColor blackColor];
        self.oldNameLabel.center       = self.nameLabel.center;
        self.avatarShadowColor         = [UIColor whiteColor];
    } else
        if (!self.selectedUser && self.passwordView.alpha == 1) {
            // User was just deselected.
            self.passwordField.text        = nil;
            self.passwordView.alpha        = 0;
            self.avatarsView.center        = CGPointMake(160, 310);
            self.avatarsView.scrollEnabled = YES;
            self.nameLabel.center          = CGPointMake(160, 296);
            self.nameLabel.backgroundColor = [UIColor clearColor];
            self.oldNameLabel.center       = self.nameLabel.center;
            self.avatarShadowColor         = [UIColor lightGrayColor];
        }

    // Lay out the word wall.
    if (!self.selectedUser || self.selectedUser.keyID) {
        self.passwordFieldLabel.text = @"Enter your master password:";

        self.wordWall.alpha              = 0;
        self.createPasswordTipView.alpha = 0;
        self.wordWallAnimating           = NO;
    } else {
        self.passwordFieldLabel.text = @"Create your master password:";

        if (!self.wordWallAnimating) {
            self.wordWallAnimating           = YES;
            self.wordWall.alpha              = 1;
            self.createPasswordTipView.alpha = 1;

            dispatch_async(dispatch_get_main_queue(), ^{
                // Jump out of our UIView animation block.
                [self beginWordWallAnimation];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:1 animations:^{
                    self.createPasswordTipView.alpha = 0;
                }];
            });
        }
    }

    // Lay out user targeting.
    MPUserEntity *targetedUser   = self.selectedUser;
    UIButton     *selectedAvatar = [self avatarForUser:self.selectedUser];
    UIButton     *targetedAvatar = selectedAvatar;
    if (!targetedAvatar) {
        targetedAvatar = [self findTargetedAvatar];
        targetedUser   = [self userForAvatar:targetedAvatar];
    }

    [self.avatarsView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if (![[self.avatarToUser allKeys] containsObject:[NSValue valueWithNonretainedObject:subview]])
         // This subview is not one of the user avatars.
            return;
        UIButton *avatar = (UIButton *)subview;

        BOOL isTargeted = avatar == targetedAvatar;

        avatar.userInteractionEnabled = isTargeted;
        avatar.alpha                  = isTargeted? 1: self.selectedUser? 0.1: 0.4;

        [self updateAvatarShadowColor:avatar isTargeted:isTargeted];
    }                           recurse:NO];

    if (allowScroll) {
        CGPoint targetContentOffset = CGPointMake(MAX(0, targetedAvatar.center.x - self.avatarsView.bounds.size.width / 2),
         self.avatarsView.contentOffset.y);
        if (!CGPointEqualToPoint(self.avatarsView.contentOffset, targetContentOffset))
            [self.avatarsView setContentOffset:targetContentOffset animated:animated];
    }

    // Lay out user name label.
    self.nameLabel.text      = targetedAvatar? targetedUser? targetedUser.name: @"New User": nil;
    self.nameLabel.bounds    = CGRectSetHeight(self.nameLabel.bounds,
                                               [self.nameLabel.text sizeWithFont:self.nameLabel.font
                                                               constrainedToSize:CGSizeMake(self.nameLabel.bounds.size.width - 10, 100)
                                                                   lineBreakMode:self.nameLabel.lineBreakMode].height);
    self.oldNameLabel.bounds = self.nameLabel.bounds;
    if (completion)
        completion(YES);
}

- (void)beginWordWallAnimation {

    [self.wordWall enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        UILabel *wordLabel = (UILabel *)subview;

        if (wordLabel.frame.origin.x < -self.wordWall.frame.size.width / 3) {
            wordLabel.frame = CGRectSetX(wordLabel.frame, wordLabel.frame.origin.x + self.wordWall.frame.size.width);
            [self initializeWordLabel:wordLabel];
        }
    }                        recurse:NO];

    if (self.wordWallAnimating)
        [UIView animateWithDuration:15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.wordWall enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
                UILabel *wordLabel = (UILabel *)subview;

                wordLabel.frame = CGRectSetX(wordLabel.frame, wordLabel.frame.origin.x - self.wordWall.frame.size.width / 3);
            }                        recurse:NO];
        }                completion:^(BOOL finished) {
            if (finished)
                [self beginWordWallAnimation];
        }];
}

- (void)initializeWordLabel:(UILabel *)wordLabel {

    wordLabel.alpha = 0.05 + (random() % 35) / 100.0F;
    wordLabel.text  = [self.wordList objectAtIndex:(NSUInteger)random() % [self.wordList count]];
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
            if (unlocked)
                [self dismissViewControllerAnimated:YES completion:nil];

            else {
                if (self.passwordField.text.length)
                    [self setPasswordTip:@"Incorrect password."];

                [self setSpinnerActive:NO];
            }
        });
    });
}

- (UIButton *)findTargetedAvatar {

    CGFloat xOfMiddle = self.avatarsView.contentOffset.x + self.avatarsView.bounds.size.width / 2;
    return (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, self.avatarsView.contentOffset.y)
                                           ofArray:self.avatarsView.subviews];
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
        rotate.toValue  = [NSNumber numberWithDouble:2 * M_PI];
        rotate.duration = 5.0;

        if (active) {
            rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            rotate.fromValue      = [NSNumber numberWithFloat:0];
            rotate.repeatCount    = MAXFLOAT;
        } else {
            rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            rotate.repeatCount    = 1;
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
            toShadowColorAnimation.toValue   = (__bridge id)(avatar.selected? self.avatarTemplate.backgroundColor
             : [UIColor whiteColor]).CGColor;
            toShadowColorAnimation.beginTime = 0.0f;
            toShadowColorAnimation.duration  = 0.5f;
            toShadowColorAnimation.fillMode  = kCAFillModeForwards;

            CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            toShadowOpacityAnimation.toValue  = PearlFloat(0.2);
            toShadowOpacityAnimation.duration = 0.5f;

            CABasicAnimation *pulseShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            pulseShadowOpacityAnimation.fromValue    = PearlFloat(0.2);
            pulseShadowOpacityAnimation.toValue      = PearlFloat(0.6);
            pulseShadowOpacityAnimation.beginTime    = 0.5f;
            pulseShadowOpacityAnimation.duration     = 2.0f;
            pulseShadowOpacityAnimation.autoreverses = YES;
            pulseShadowOpacityAnimation.repeatCount  = MAXFLOAT;

            CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
            group.animations = [NSArray arrayWithObjects:toShadowColorAnimation, toShadowOpacityAnimation, pulseShadowOpacityAnimation,
                                                         nil];
            group.duration   = MAXFLOAT;

            [avatar.layer removeAnimationForKey:@"inactiveShadow"];
            [avatar.layer addAnimation:group forKey:@"targetedShadow"];
        }
    } else {
        if ([avatar.layer animationForKey:@"targetedShadow"]) {
            CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            toShadowColorAnimation.toValue  = (__bridge id)[UIColor blackColor].CGColor;
            toShadowColorAnimation.duration = 0.5f;

            CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            toShadowOpacityAnimation.toValue  = PearlFloat(1);
            toShadowOpacityAnimation.duration = 0.5f;

            CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
            group.animations = [NSArray arrayWithObjects:toShadowColorAnimation, toShadowOpacityAnimation, nil];
            group.duration   = 0.5f;

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
                                     viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                                   cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
                return;
            }

            [self tryMasterPassword];
        }
                           cancelTitle:[PearlStrings get].commonButtonCancel
                           otherTitles:[PearlStrings get].commonButtonContinue, nil];


    return YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    CGFloat xOfMiddle = targetContentOffset->x + scrollView.bounds.size.width / 2;
    UIButton *middleAvatar = (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake(xOfMiddle, targetContentOffset->y)
                                                             ofArray:scrollView.subviews];
    *targetContentOffset = CGPointMake(middleAvatar.center.x - scrollView.bounds.size.width / 2, targetContentOffset->y);

    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
}

#pragma mark - IBActions

- (IBAction)targetedUserAction:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
        return;

    if (self.selectedUser)
        return;

    MPUserEntity *targetedUser = [self userForAvatar:[self findTargetedAvatar]];
    if (!targetedUser)
        return;

    [PearlSheet showSheetWithTitle:targetedUser.name
                           message:nil viewStyle:UIActionSheetStyleBlackTranslucent
                         initSheet:nil
                 tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                     if (buttonIndex == [sheet cancelButtonIndex])
                         return;

                     if (buttonIndex == [sheet destructiveButtonIndex]) {
                         [[MPAppDelegate get].managedObjectContextIfReady performBlockAndWait:^{
                             [[MPAppDelegate get].managedObjectContextIfReady deleteObject:targetedUser];
                         }];
                         [[MPAppDelegate get] saveContext];
                         [self updateUsers];
                     } else
                         if (buttonIndex == [sheet firstOtherButtonIndex]) {
                             [[MPAppDelegate get] changeMasterPasswordFor:targetedUser didResetBlock:^{
                                 [[self avatarForUser:targetedUser] setSelected:YES];
                             }];
                         }
                         else
                             [[MPAppDelegate get] saveContext];
                 }     cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:@"Delete User" otherTitles:@"Reset Password",
                                                                                                                     @"Save",
                                                                                                                     nil];
}
@end
