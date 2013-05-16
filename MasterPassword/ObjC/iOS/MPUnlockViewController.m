//
//  MBUnlockViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 22/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <Social/Social.h>
#import <CoreGraphics/CoreGraphics.h>

#import "MPUnlockViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"


@interface MPUnlockViewController()

@property(strong, nonatomic) NSMutableDictionary *avatarToUserOID;
@property(nonatomic) BOOL wordWallAnimating;
@property(nonatomic, strong) NSArray *wordList;

@property(nonatomic, strong) NSOperationQueue *emergencyQueue;
@property(nonatomic, strong) MPKey *emergencyKey;

@property(nonatomic, strong) NSTimer *marqueeTipTimer;
@property(nonatomic) NSUInteger marqueeTipTextIndex;
@property(nonatomic, strong) NSArray *marqueeTipTexts;
@end


@implementation MPUnlockViewController {
    NSManagedObjectID *_selectedUserOID;
}

- (void)initializeAvatarAlert:(UIAlertView *)alert forUser:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc {

    UIScrollView *alertAvatarScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake( 12, 30, 260, 150 )];
    alertAvatarScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [alertAvatarScrollView flashScrollIndicatorsContinuously];
    [alert addSubview:alertAvatarScrollView];

    CGPoint selectedOffset = CGPointZero;
    for (int a = 0; a < MPAvatarCount; ++a) {
        UIButton *avatar = [self.avatarTemplate cloneAddedTo:alertAvatarScrollView];

        avatar.tag = a;
        avatar.hidden = NO;
        avatar.center = CGPointMake(
                (20 + self.avatarTemplate.bounds.size.width / 2) * (a + 1) + self.avatarTemplate.bounds.size.width / 2 * a,
                20 + self.avatarTemplate.bounds.size.height / 2 );
        [avatar setBackgroundImage:[UIImage imageNamed:PearlString( @"avatar-%d", a )] forState:UIControlStateNormal];
        [avatar setSelectionInSuperviewCandidate:YES isClearable:NO];

        avatar.layer.cornerRadius = avatar.bounds.size.height / 2;
        avatar.layer.shadowColor = [UIColor blackColor].CGColor;
        avatar.layer.shadowOpacity = 1;
        avatar.layer.shadowRadius = 5;
        avatar.backgroundColor = [UIColor clearColor];

        [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
            if (highlighted || selected)
                avatar.backgroundColor = self.avatarTemplate.backgroundColor;
            else
                avatar.backgroundColor = [UIColor clearColor];
        }                   options:0];
        [avatar onSelect:^(BOOL selected) {
            if (selected)
                [moc performBlock:^{
                    user.avatar = (unsigned)avatar.tag;
                }];
        }        options:0];
        avatar.selected = (a == user.avatar);
        if (avatar.selected)
            selectedOffset = CGPointMake( avatar.center.x - alertAvatarScrollView.bounds.size.width / 2, 0 );
    }

    [alertAvatarScrollView autoSizeContent];
    [alertAvatarScrollView setContentOffset:selectedOffset animated:YES];
}

- (void)initializeConfirmationAlert:(UIAlertView *)alert forUser:(MPUserEntity *)user {

    UIView *container = [[UIView alloc] initWithFrame:CGRectMake( 12, 70, 260, 110 )];
    [alert addSubview:container];

    UIButton *alertAvatar = [self.avatarTemplate cloneAddedTo:container];
    alertAvatar.center = CGPointMake( 130, 55 );
    alertAvatar.hidden = NO;
    alertAvatar.layer.shadowColor = [UIColor blackColor].CGColor;
    alertAvatar.layer.shadowOpacity = 1;
    alertAvatar.layer.shadowRadius = 5;
    alertAvatar.backgroundColor = [UIColor clearColor];
    [alertAvatar setBackgroundImage:[UIImage imageNamed:PearlString( @"avatar-%d", user.avatar )] forState:UIControlStateNormal];

    UILabel *alertNameLabel = [self.nameLabel cloneAddedTo:container];
    alertNameLabel.center = alertAvatar.center;
    alertNameLabel.text = user.name;
    alertNameLabel.bounds = CGRectSetHeight( alertNameLabel.bounds,
            [alertNameLabel.text sizeWithFont:self.nameLabel.font
                            constrainedToSize:CGSizeMake( alertNameLabel.bounds.size.width - 10,
                                    100 )
                                lineBreakMode:self.nameLabel.lineBreakMode].height );
    alertNameLabel.layer.cornerRadius = 5;
    alertNameLabel.backgroundColor = [UIColor blackColor];
}

- (BOOL)shouldAutorotate {

    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations {

    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {

    NSString *newsURL = PearlString( @"http://www.masterpasswordapp.com/news.html?version=%@", [[PearlInfoPlist get] CFBundleVersion] );
    [self.newsView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:newsURL]]];

    self.avatarToUserOID = [NSMutableDictionary dictionaryWithCapacity:3];

    [self.avatarsView addGestureRecognizer:self.targetedUserActionGesture];
    self.avatarsView.decelerationRate = UIScrollViewDecelerationRateFast;
    self.avatarsView.clipsToBounds = NO;
    self.tip.text = @"";
    self.nameLabel.layer.cornerRadius = 5;
    self.avatarTemplate.hidden = YES;
    self.passwordTipView.hidden = NO;
    self.createPasswordTipView.hidden = NO;
    [self.emergencyPassword setTitle:@"" forState:UIControlStateNormal];
    self.emergencyGeneratorContainer.alpha = 0;
    self.emergencyGeneratorContainer.hidden = YES;
    self.emergencyQueue = [NSOperationQueue new];
    [self.emergencyCounterStepper addTargetBlock:^(id sender, UIControlEvents event) {
        self.emergencyCounter.text = PearlString( @"%d", (NSUInteger)self.emergencyCounterStepper.value );

        [self updateEmergencyPassword];
    }                           forControlEvents:UIControlEventValueChanged];
    [self.emergencyTypeControl addTargetBlock:^(id sender, UIControlEvents event) {
        [self updateEmergencyPassword];
    }                        forControlEvents:UIControlEventValueChanged];
    self.emergencyContentTipContainer.alpha = 0;
    self.emergencyContentTipContainer.hidden = NO;
    self.marqueeTipTexts = @[
            @"Tap and hold to delete or reset user.",
            @"Shake for emergency generator."
    ];

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

    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidChangeNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateUsers];
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidImportChangesNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self updateUsers];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self emergencyCloseAnimated:NO];
                self.uiContainer.alpha = 0;
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
                [UIView animateWithDuration:1 animations:^{
                    self.uiContainer.alpha = 1;
                }];
            }];

    [self updateLayoutAnimated:NO allowScroll:YES completion:nil];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Lock screen will appear");
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    [[MPiOSAppDelegate get] signOutAnimated:NO];

    _selectedUserOID = nil;
    [self updateUsers];

    self.uiContainer.alpha = 0;
    self.spinner.alpha = 0;

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [self becomeFirstResponder];

    if (!animated && !self.navigationController.presentedViewController)
        [[self findTargetedAvatar] setSelected:YES];
    else
        [self updateLayoutAnimated:YES allowScroll:YES completion:nil];

    [UIView animateWithDuration:0.5 animations:^{
        self.uiContainer.alpha = 1;
    }];

    [self.marqueeTipTimer invalidate];
    self.marqueeTipTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(marqueeTip) userInfo:nil repeats:YES];

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Unlock"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Lock screen will disappear");
    [self emergencyCloseAnimated:animated];

    [self.marqueeTipTimer invalidate];

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }];

    [super viewWillDisappear:animated];
}

- (BOOL)canBecomeFirstResponder {

    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {

    if (motion == UIEventSubtypeMotionShake) {
        MPCheckpoint( MPCheckpointEmergencyGenerator, nil );
        [[self.view findFirstResponderInHierarchy] resignFirstResponder];

        self.emergencyGeneratorContainer.alpha = 0;
        self.emergencyGeneratorContainer.hidden = NO;
        self.emergencyGeneratorContainer.frame = CGRectSetX( self.emergencyGeneratorContainer.frame,
                self.emergencyGeneratorContainer.frame.origin.x - 100 );
        [UIView animateWithDuration:0.3 animations:^{
            self.emergencyGeneratorContainer.frame = CGRectSetX( self.emergencyGeneratorContainer.frame,
                    self.emergencyGeneratorContainer.frame.origin.x + 150 );
            self.emergencyGeneratorContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (!finished)
                return;

            [self.emergencyName becomeFirstResponder];
            [UIView animateWithDuration:0.2 animations:^{
                self.emergencyGeneratorContainer.frame = CGRectSetX( self.emergencyGeneratorContainer.frame,
                        self.emergencyGeneratorContainer.frame.origin.x - 50 );
            }];
        }];
    }
}

- (void)marqueeTip {

    [UIView animateWithDuration:0.5 animations:^{
        self.tip.alpha = 0;
    }                completion:^(BOOL finished) {
        if (!finished)
            return;

        self.tip.text = self.marqueeTipTexts[++self.marqueeTipTextIndex % [self.marqueeTipTexts count]];
        [UIView animateWithDuration:0.5 animations:^{
            self.tip.alpha = 1;
        }];
    }];
}

- (void)updateUsers {

    [MPiOSAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
        NSError *error = nil;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
        fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO] ];
        NSArray *users = [context executeFetchRequest:fetchRequest error:&error];
        if (!users)
        err(@"Failed to load users: %@", error);

        // Clean up avatars.
        for (UIView *subview in [self.avatarsView subviews])
            if ([[self.avatarToUserOID allKeys] containsObject:[NSValue valueWithNonretainedObject:subview]])
                    // This subview is a former avatar.
                [subview removeFromSuperview];
        [self.avatarToUserOID removeAllObjects];

        // Create avatars.
        for (MPUserEntity *user in users)
            [self setupAvatar:[self.avatarTemplate clone] forUser:user];
        [self setupAvatar:[self.avatarTemplate clone] forUser:nil];
    }];

    // Scroll view's content changed, update its content size.
    [self.avatarsView autoSizeContentIgnoreHidden:YES ignoreInvisible:YES limitPadding:NO ignoreSubviews:nil];

    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];
}

- (UIButton *)setupAvatar:(UIButton *)avatar forUser:(MPUserEntity *)user {

    avatar.center = CGPointMake( avatar.center.x + [self.avatarToUserOID count] * 160, avatar.center.y );
    avatar.hidden = NO;
    avatar.layer.cornerRadius = avatar.bounds.size.height / 2;
    avatar.layer.shadowColor = [UIColor blackColor].CGColor;
    avatar.layer.shadowOpacity = 1;
    avatar.layer.shadowRadius = 20;
    avatar.layer.masksToBounds = NO;
    avatar.backgroundColor = [UIColor clearColor];
    avatar.tag = user.avatar;

    [avatar setBackgroundImage:[UIImage imageNamed:PearlString( @"avatar-%u", user.avatar )]
                      forState:UIControlStateNormal];
    [avatar setSelectionInSuperviewCandidate:YES isClearable:YES];
    [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
        if (highlighted || selected)
            avatar.backgroundColor = self.avatarTemplate.backgroundColor;
        else
            avatar.backgroundColor = [UIColor clearColor];
    }                   options:0];
    [avatar onSelect:^(BOOL selected) {
        if (!selected) {
            self.selectedUser = nil;
            [self didToggleUserSelection];
        }
        else if ((self.selectedUser = user))
            [self didToggleUserSelection];
        else
            [self didSelectNewUserAvatar:avatar];
    }        options:0];

    [self.avatarToUserOID setObject:NilToNSNull([user objectID]) forKey:[NSValue valueWithNonretainedObject:avatar]];

    if ([_selectedUserOID isEqual:[user objectID]])
        avatar.selected = YES;

    return avatar;
}

- (void)didToggleUserSelection {

    NSAssert([[NSThread currentThread] isMainThread], @"User selection should only be toggled from the main thread.");

    NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForThreadIfReady];
    MPUserEntity *selectedUser = [self selectedUserInContext:mainContext];
    if (!selectedUser)
        [self.passwordField resignFirstResponder];
    else if ([[MPiOSAppDelegate get] signInAsUser:selectedUser saveInContext:mainContext usingMasterPassword:nil]) {
        [self performSegueWithIdentifier:@"MP_Unlock" sender:self];
        return;
    }

    [self updateLayoutAnimated:YES allowScroll:YES completion:^(BOOL finished) {
        if ([self selectedUserForThread])
            [self.passwordField becomeFirstResponder];
    }];
}

- (void)didSelectNewUserAvatar:(UIButton *)newUserAvatar {

    if (![MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *newUser = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass( [MPUserEntity class] )
                                                              inManagedObjectContext:context];

        [self showNewUserNameAlertFor:newUser saveInContext:context completion:^(BOOL finished) {
            newUserAvatar.selected = NO;
        }];
    }])
        newUserAvatar.selected = NO;
}

- (void)showNewUserNameAlertFor:(MPUserEntity *)newUser saveInContext:(NSManagedObjectContext *)context
                     completion:(void (^)(BOOL finished))completion {

    [PearlAlert showAlertWithTitle:@"Enter Your Name"
                           message:nil viewStyle:UIAlertViewStylePlainTextInput
                         initAlert:^(UIAlertView *alert, UITextField *firstField) {
                             firstField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                             firstField.keyboardType = UIKeyboardTypeAlphabet;
                             firstField.text = newUser.name;
                             firstField.placeholder = @"eg. Robert Lee Mitchell";
                             firstField.enablesReturnKeyAutomatically = YES;
                         }
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex]) {
                         completion( NO );
                         return;
                     }
                     NSString *name = [alert textFieldAtIndex:0].text;
                     if (!name.length) {
                         [PearlAlert showAlertWithTitle:@"Name Is Required" message:nil viewStyle:UIAlertViewStyleDefault initAlert:nil
                                      tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                                          [self showNewUserNameAlertFor:newUser saveInContext:context completion:completion];
                                      }     cancelTitle:@"Try Again" otherTitles:nil];
                         return;
                     }

                     // Save
                     [context performBlockAndWait:^{
                         newUser.name = name;
                     }];
                     [self showNewUserAvatarAlertFor:newUser saveInContext:context completion:completion];
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonSave, nil];
}

- (void)showNewUserAvatarAlertFor:(MPUserEntity *)newUser saveInContext:(NSManagedObjectContext *)context
                       completion:(void (^)(BOOL finished))completion {

    [PearlAlert showAlertWithTitle:@"Choose Your Avatar"
                           message:@"\n\n\n\n\n\n" viewStyle:UIAlertViewStyleDefault
                         initAlert:^(UIAlertView *_alert, UITextField *_firstField) {
                             [self initializeAvatarAlert:_alert forUser:newUser inContext:context];
                         }
                 tappedButtonBlock:^(UIAlertView *_alert, NSInteger _buttonIndex) {

                     // Okay
                     [self showNewUserConfirmationAlertFor:newUser saveInContext:context completion:completion];
                 }     cancelTitle:nil otherTitles:[PearlStrings get].commonButtonOkay, nil];
}

- (void)showNewUserConfirmationAlertFor:(MPUserEntity *)newUser saveInContext:(NSManagedObjectContext *)context
                             completion:(void (^)(BOOL finished))completion {

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
                         [self showNewUserNameAlertFor:newUser saveInContext:context completion:completion];
                         return;
                     }

                     // Confirm
                     [context performBlockAndWait:^{
                         [context saveToStore];
                         NSError *error = nil;
                         if (![context obtainPermanentIDsForObjects:@[ newUser ] error:&error])
                         err(@"Failed to obtain permanent object ID for new user: %@", error);
                         self.selectedUser = newUser;
                     }];
                     completion( YES );

                     [self updateUsers];
                 }
                       cancelTitle:@"Change" otherTitles:@"Confirm", nil];
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
        }                completion:^(BOOL finished) {
            if (completion)
                completion( finished );
        }];
        return;
    }

    // Lay out password entry and user selection views.
    MPUserEntity *selectedUser = [self selectedUserForThread];
    if (selectedUser && !self.passwordView.alpha) {
        // User was just selected.
        self.passwordView.alpha = 1;
        self.avatarsView.frame = CGRectSetY( self.avatarsView.frame, 16 );
        self.avatarsView.scrollEnabled = NO;
        self.nameLabel.center = CGPointMake( 160, 94 );
        self.nameLabel.backgroundColor = [UIColor blackColor];
        self.oldNameLabel.center = self.nameLabel.center;
        self.avatarShadowColor = [UIColor whiteColor];
    }
    else if (!selectedUser && self.passwordView.alpha == 1) {
        // User was just deselected.
        self.passwordField.text = nil;
        self.passwordView.alpha = 0;
        self.avatarsView.frame = CGRectSetY( self.avatarsView.frame, 140 );
        self.avatarsView.scrollEnabled = YES;
        self.nameLabel.center = CGPointMake( 160, 296 );
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.oldNameLabel.center = self.nameLabel.center;
        self.avatarShadowColor = [UIColor lightGrayColor];
    }

    // Lay out the word wall.
    if (!selectedUser || selectedUser.keyID) {
        self.passwordFieldLabel.text = @"Enter your master password:";

        self.wordWall.alpha = 0;
        self.createPasswordTipView.alpha = 0;
        self.wordWallAnimating = NO;
    }
    else {
        self.passwordFieldLabel.text = @"Create your master password:";

        if (!self.wordWallAnimating) {
            self.wordWallAnimating = YES;
            self.wordWall.alpha = 1;
            self.createPasswordTipView.alpha = 1;

            dispatch_async( dispatch_get_main_queue(), ^{
                // Jump out of our UIView animation block.
                [self beginWordWallAnimation];
            } );
            dispatch_after( dispatch_time( DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC ), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:1 animations:^{
                    self.createPasswordTipView.alpha = 0;
                }];
            } );
        }
    }

    // Lay out user targeting.
    UIButton *selectedAvatar = [self avatarForUser:selectedUser];
    MPUserEntity *targetedUser = selectedUser;
    UIButton *targetedAvatar = selectedAvatar;
    if (!targetedAvatar) {
        targetedAvatar = [self findTargetedAvatar];
        targetedUser = [self userForAvatar:targetedAvatar inContext:[MPiOSAppDelegate managedObjectContextForThreadIfReady]];
    }

    [self.avatarsView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if (![[self.avatarToUserOID allKeys] containsObject:[NSValue valueWithNonretainedObject:subview]])
                // This subview is not one of the user avatars.
            return;
        UIButton *avatar = (UIButton *)subview;

        BOOL isTargeted = avatar == targetedAvatar;

        avatar.userInteractionEnabled = isTargeted;
        avatar.alpha = isTargeted? 1: [self selectedUserForThread]? 0.1: 0.4;

        [self updateAvatarShadowColor:avatar isTargeted:isTargeted];
    }                           recurse:NO];

    if (allowScroll) {
        CGPoint targetContentOffset = CGPointMake(
                MAX(0, targetedAvatar.center.x - self.avatarsView.bounds.size.width / 2),
                self.avatarsView.contentOffset.y );
        if (!CGPointEqualToPoint( self.avatarsView.contentOffset, targetContentOffset ))
            [self.avatarsView setContentOffset:targetContentOffset animated:animated];
    }

    // Lay out user name label.
    self.nameLabel.text = targetedAvatar? (targetedUser? targetedUser.name: @"New User"): nil;
    self.nameLabel.bounds = CGRectSetHeight( self.nameLabel.bounds,
            [self.nameLabel.text sizeWithFont:self.nameLabel.font
                            constrainedToSize:CGSizeMake( self.nameLabel.bounds.size.width - 10, 100 )
                                lineBreakMode:self.nameLabel.lineBreakMode].height );
    self.oldNameLabel.bounds = self.nameLabel.bounds;
    if (completion)
        completion( YES );
}

- (void)beginWordWallAnimation {

    [self.wordWall enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        UILabel *wordLabel = (UILabel *)subview;

        if (wordLabel.frame.origin.x < -self.wordWall.frame.size.width / 3) {
            wordLabel.frame = CGRectSetX( wordLabel.frame, wordLabel.frame.origin.x + self.wordWall.frame.size.width );
            [self initializeWordLabel:wordLabel];
        }
    }                        recurse:NO];

    if (self.wordWallAnimating)
        [UIView animateWithDuration:15 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            [self.wordWall enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
                UILabel *wordLabel = (UILabel *)subview;

                wordLabel.frame = CGRectSetX( wordLabel.frame, wordLabel.frame.origin.x - self.wordWall.frame.size.width / 3 );
            }                        recurse:NO];
        }                completion:^(BOOL finished) {
            if (finished)
                [self beginWordWallAnimation];
        }];
}

- (void)initializeWordLabel:(UILabel *)wordLabel {

    wordLabel.alpha = 0.05 + (random() % 35) / 100.0F;
    wordLabel.text = [self.wordList objectAtIndex:(NSUInteger)random() % [self.wordList count]];
}

- (void)setPasswordTip:(NSString *)string {

    if (string.length)
        self.passwordTipLabel.text = string;

    [UIView animateWithDuration:0.3f animations:^{
        self.passwordTipView.alpha = string.length? 1: 0;
    }];
}

- (void)tryMasterPassword {

    if (![self selectedUserForThread])
            // No user selected, can't try sign-in.
        return;

    [self setSpinnerActive:YES];

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        BOOL unlocked = [[MPiOSAppDelegate get] signInAsUser:[self selectedUserInContext:moc] saveInContext:moc
                                         usingMasterPassword:self.passwordField.text];

        dispatch_async( dispatch_get_main_queue(), ^{
            if (unlocked)
                [self performSegueWithIdentifier:@"MP_Unlock" sender:self];

            else {
                if (self.passwordField.text.length)
                    [self setPasswordTip:@"Incorrect password."];

                [self setSpinnerActive:NO];
            }
        } );
    }];
}

- (UIButton *)findTargetedAvatar {

    CGFloat xOfMiddle = self.avatarsView.contentOffset.x + self.avatarsView.bounds.size.width / 2;
    return (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake( xOfMiddle, self.avatarsView.contentOffset.y )
                                           ofArray:self.avatarsView.subviews];
}

- (UIButton *)avatarForUser:(MPUserEntity *)user {

    NSManagedObjectID *userOID = [user objectID];
    __block UIButton *avatar = nil;
    if (userOID)
        [self.avatarToUserOID enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isEqual:userOID])
                avatar = [key nonretainedObjectValue];
        }];

    return avatar;
}

- (MPUserEntity *)userForAvatar:(UIButton *)avatar inContext:(NSManagedObjectContext *)context {

    NSManagedObjectID *userOID = NSNullToNil([self.avatarToUserOID objectForKey:[NSValue valueWithNonretainedObject:avatar]]);
    if (!userOID)
        return nil;

    NSError *error;
    MPUserEntity *user = (MPUserEntity *)[context existingObjectWithID:userOID error:&error];
    if (!user)
    err(@"Failed retrieving user for avatar: %@", error);

    return user;
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
        }
        else {
            rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            rotate.repeatCount = 1;
        }

        [self.spinner.layer removeAnimationForKey:@"rotation"];
        [self.spinner.layer addAnimation:rotate forKey:@"rotation"];

        [UIView animateWithDuration:0.3f animations:^{
            self.spinner.alpha = active? 1: 0;

            if (active)
                [self avatarForUser:[self selectedUserForThread]].backgroundColor = [UIColor clearColor];
            else
                [self avatarForUser:[self selectedUserForThread]].backgroundColor = self.avatarTemplate.backgroundColor;
        }];
    });
}

- (void)updateAvatarShadowColor:(UIButton *)avatar isTargeted:(BOOL)targeted {

    if (targeted) {
        if (![avatar.layer animationForKey:@"targetedShadow"]) {
            CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            toShadowColorAnimation.toValue = (__bridge id)(avatar.selected? self.avatarTemplate.backgroundColor
                                                           : [UIColor whiteColor]).CGColor;
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
            group.animations = @[ toShadowColorAnimation, toShadowOpacityAnimation, pulseShadowOpacityAnimation ];
            group.duration = MAXFLOAT;

            [avatar.layer removeAnimationForKey:@"inactiveShadow"];
            [avatar.layer addAnimation:group forKey:@"targetedShadow"];
        }
    }
    else {
        if ([avatar.layer animationForKey:@"targetedShadow"]) {
            CABasicAnimation *toShadowColorAnimation = [CABasicAnimation animationWithKeyPath:@"shadowColor"];
            toShadowColorAnimation.toValue = (__bridge id)[UIColor blackColor].CGColor;
            toShadowColorAnimation.duration = 0.5f;

            CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
            toShadowOpacityAnimation.toValue = PearlFloat(1);
            toShadowOpacityAnimation.duration = 0.5f;

            CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
            group.animations = @[ toShadowColorAnimation, toShadowOpacityAnimation ];
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

    if (textField == self.emergencyName) {
        if (![self.emergencyMasterPassword.text length])
            [self.emergencyMasterPassword becomeFirstResponder];
    }

    else if (textField == self.emergencyMasterPassword) {
        if (![self.emergencySite.text length])
            [self.emergencySite becomeFirstResponder];
    }

    else if (textField == self.passwordField) {
        [self setSpinnerActive:YES];

        if ([self selectedUserForThread].keyID)
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
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.emergencyName || textField == self.emergencyMasterPassword)
        [self updateEmergencyKey];

    if (textField == self.emergencySite)
        [self updateEmergencyPassword];
}

- (void)updateEmergencyKey {

    if (![self.emergencyMasterPassword.text length] || ![self.emergencyName.text length])
        return;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.emergencyActivity startAnimating];
        [self.emergencyPassword setTitle:@"" forState:UIControlStateNormal];

        NSString *masterPassword = self.emergencyMasterPassword.text;
        NSString *userName = self.emergencyName.text;

        [self.emergencyQueue addOperationWithBlock:^{
            self.emergencyKey = [MPAlgorithmDefault keyForPassword:masterPassword ofUserNamed:userName];

            [self updateEmergencyPassword];
        }];
    }];
}

- (MPElementType)emergencyType {

    switch (self.emergencyTypeControl.selectedSegmentIndex) {
        case 0:
            return MPElementTypeGeneratedMaximum;
        case 1:
            return MPElementTypeGeneratedLong;
        case 2:
            return MPElementTypeGeneratedMedium;
        case 3:
            return MPElementTypeGeneratedBasic;
        case 4:
            return MPElementTypeGeneratedShort;
        case 5:
            return MPElementTypeGeneratedPIN;
        default:
            Throw(@"Unsupported type index: %d", self.emergencyTypeControl.selectedSegmentIndex);
    }
}

- (void)updateEmergencyPassword {

    if (!self.emergencyKey || ![self.emergencySite.text length])
        return;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.emergencyPassword setTitle:@"" forState:UIControlStateNormal];

        NSString *name = self.emergencySite.text;
        NSUInteger counter = (NSUInteger)self.emergencyCounterStepper.value;

        [self.emergencyQueue addOperationWithBlock:^{
            NSString *content = [MPAlgorithmDefault generateContentNamed:name ofType:[self emergencyType]
                                                             withCounter:counter usingKey:self.emergencyKey];

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.emergencyActivity stopAnimating];
                [self.emergencyPassword setTitle:content forState:UIControlStateNormal];
            }];
        }];
    }];
}

- (IBAction)emergencyClose:(UIButton *)sender {

    [self emergencyCloseAnimated:YES];
}

- (IBAction)emergencyCopy:(UIButton *)sender {

    inf(@"Copying emergency password for: %@", self.emergencyName.text);
    [UIPasteboard generalPasteboard].string = [self.emergencyPassword titleForState:UIControlStateNormal];

    [UIView animateWithDuration:0.3f animations:^{
        self.emergencyContentTipContainer.alpha = 1;
    }                completion:^(BOOL finished) {
        if (finished) {
            dispatch_time_t popTime = dispatch_time( DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC );
            dispatch_after( popTime, dispatch_get_main_queue(), ^(void) {
                [UIView animateWithDuration:0.2f animations:^{
                    self.emergencyContentTipContainer.alpha = 0;
                }];
            } );
        }
    }];

    MPCheckpoint( MPCheckpointCopyToPasteboard, @{
            @"type"      : [MPAlgorithmDefault nameOfType:self.emergencyType],
            @"version"   : @MPAlgorithmDefaultVersion,
            @"emergency" : @YES,
    } );
}

- (void)emergencyCloseAnimated:(BOOL)animated {

    [[self.emergencyGeneratorContainer findFirstResponderInHierarchy] resignFirstResponder];

    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.emergencyGeneratorContainer.alpha = 0;
        }                completion:^(BOOL finished) {
            [self emergencyCloseAnimated:NO];
        }];
        return;
    }

    self.emergencyName.text = @"";
    self.emergencyMasterPassword.text = @"";
    self.emergencySite.text = @"";
    self.emergencyCounterStepper.value = 0;
    [self.emergencyPassword setTitle:@"" forState:UIControlStateNormal];
    [self.emergencyActivity stopAnimating];
    self.emergencyGeneratorContainer.alpha = 0;
    self.emergencyGeneratorContainer.hidden = YES;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    CGFloat xOfMiddle = targetContentOffset->x + scrollView.bounds.size.width / 2;
    UIButton *middleAvatar = (UIButton *)[PearlUIUtils viewClosestTo:CGPointMake( xOfMiddle, targetContentOffset->y )
                                                             ofArray:scrollView.subviews];
    *targetContentOffset = CGPointMake( middleAvatar.center.x - scrollView.bounds.size.width / 2, targetContentOffset->y );

    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    [self updateLayoutAnimated:YES allowScroll:YES completion:nil];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    [self updateLayoutAnimated:NO allowScroll:NO completion:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

#pragma mark - IBActions

- (IBAction)targetedUserAction:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
        return;

    if ([self selectedUserForThread])
        return;

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *targetedUser = [self userForAvatar:[self findTargetedAvatar] inContext:context];
        if (!targetedUser)
            return;

        [PearlSheet showSheetWithTitle:targetedUser.name
                             viewStyle:UIActionSheetStyleBlackTranslucent
                             initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
            if (buttonIndex == [sheet cancelButtonIndex])
                return;

            if (buttonIndex == [sheet destructiveButtonIndex]) {
                [context performBlock:^{
                    [context deleteObject:targetedUser];
                    [context saveToStore];

                    dispatch_async( dispatch_get_main_queue(), ^{
                        [self updateUsers];
                    } );
                }];
                return;
            }

            if (buttonIndex == [sheet firstOtherButtonIndex])
                [[MPiOSAppDelegate get] changeMasterPasswordFor:targetedUser saveInContext:context didResetBlock:^{
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [[self avatarForUser:targetedUser] setSelected:YES];
                    } );
                }];
        }                  cancelTitle:[PearlStrings get].commonButtonCancel
                      destructiveTitle:@"Delete User" otherTitles:@"Reset Password", nil];
    }];
}

- (IBAction)facebook:(UIButton *)sender {

    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        [PearlAlert showAlertWithTitle:@"Facebook Not Enabled" message:@"To send tweets, configure Facebook from Settings."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil cancelTitle:nil otherTitles:@"OK", nil];
        return;
    }

    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [vc setInitialText:@"I've started doing passwords properly thanks to Master Password for iOS."];
    [vc addImage:[UIImage imageNamed:@"iTunesArtwork-Rounded"]];
    [vc addURL:[NSURL URLWithString:@"http://masterpasswordapp.com"]];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)twitter:(UIButton *)sender {

    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        [PearlAlert showAlertWithTitle:@"Twitter Not Enabled" message:@"To send tweets, configure Twitter from Settings."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil cancelTitle:nil otherTitles:@"OK", nil];
        return;
    }

    SLComposeViewController *vc = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [vc setInitialText:@"I've started doing passwords properly thanks to Master Password."];
    [vc addImage:[UIImage imageNamed:@"iTunesArtwork-Rounded"]];
    [vc addURL:[NSURL URLWithString:@"http://masterpasswordapp.com"]];
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)google:(UIButton *)sender {

    id<GPPShareBuilder> shareDialog = [[GPPShare sharedInstance] shareDialog];
    [[[shareDialog setURLToShare:[NSURL URLWithString:@"http://masterpasswordapp.com"]]
            setPrefillText:@"I've started doing passwords properly thanks to Master Password."] open];
}

- (IBAction)mail:(UIButton *)sender {

    [[MPiOSAppDelegate get] showFeedbackWithLogs:NO forVC:self];
}

- (IBAction)add:(UIButton *)sender {

    [PearlSheet showSheetWithTitle:@"Follow Master Password" viewStyle:UIActionSheetStyleBlackTranslucent
                         initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == [sheet cancelButtonIndex])
            return;

        if (buttonIndex == [sheet firstOtherButtonIndex]) {
            // Google+
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://plus.google.com/116256327773442623984/about"]];
            return;
        }
        if (buttonIndex == [sheet firstOtherButtonIndex] + 1) {
            // Facebook
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/masterpasswordapp"]];
            return;
        }
        if (buttonIndex == [sheet firstOtherButtonIndex] + 2) {
            // Twitter
            UIApplication *application = [UIApplication sharedApplication];
            for (NSString *candidate in @[
                    @"twitter://user?screen_name=%@", // Twitter
                    @"tweetbot:///user_profile/%@", // TweetBot
                    @"echofon:///user_timeline?%@", // Echofon
                    @"twit:///user?screen_name=%@", // Twittelator Pro
                    @"x-seesmic://twitter_profile?twitter_screen_name=%@", // Seesmic
                    @"x-birdfeed://user?screen_name=%@", // Birdfeed
                    @"tweetings:///user?screen_name=%@", // Tweetings
                    @"simplytweet:?link=http://twitter.com/%@", // SimplyTweet
                    @"icebird://user?screen_name=%@", // IceBird
                    @"fluttr://user/%@", // Fluttr
                    @"http://twitter.com/%@"
            ]) {
                NSURL *url = [NSURL URLWithString:PearlString( candidate, @"master_password" )];

                if ([application canOpenURL:url]) {
                    [application openURL:url];
                    break;
                }
            }
            return;
        }
        if (buttonIndex == [sheet firstOtherButtonIndex] + 3) {
            // Mailing List
            [PearlEMail sendEMailTo:@"masterpassword-join@lists.lyndir.com" subject:@"Subscribe"
                               body:@"Press 'Send' now to subscribe to the Master Password mailing list.\n\n"
                                       @"You'll be kept up-to-date on the evolution of and discussions revolving Master Password."];
            return;
        }
        if (buttonIndex == [sheet firstOtherButtonIndex] + 4) {
            // GitHub
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/Lyndir/MasterPassword"]];
            return;
        }
    }                  cancelTitle:[PearlStrings get].commonButtonCancel
                  destructiveTitle:nil otherTitles:@"Google+", @"Facebook", @"Twitter", @"Mailing List", @"GitHub", nil];
}

#pragma mark - Core Data

- (MPUserEntity *)selectedUserForThread {

    return [self selectedUserInContext:[MPiOSAppDelegate managedObjectContextForThreadIfReady]];
}

- (MPUserEntity *)selectedUserInContext:(NSManagedObjectContext *)moc {

    if (!_selectedUserOID)
        return nil;

    NSError *error;
    MPUserEntity *selectedUser = (MPUserEntity *)[moc existingObjectWithID:_selectedUserOID error:&error];
    if (!selectedUser)
    err(@"Failed to retrieve selected user: %@", error);

    return selectedUser;
}

- (void)setSelectedUser:(MPUserEntity *)selectedUser {

    NSError *error = nil;
    if (selectedUser.objectID.isTemporaryID &&
        ![selectedUser.managedObjectContext obtainPermanentIDsForObjects:@[ selectedUser ] error:&error])
    err(@"Failed to obtain a permanent object ID after setting selected user: %@", error);

    _selectedUserOID = selectedUser.objectID;
}

@end
