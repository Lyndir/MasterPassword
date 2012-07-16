//
//  MPMainViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPMainViewController.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "LocalyticsSession.h"


void MPElementMigrate(MPElementEntity *entity, BOOL i);

@interface MPMainViewController (Private)

- (void)updateAnimated:(BOOL)animated;
- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon;
- (void)showToolTip:(NSString *)message withIcon:(UIImageView *)icon;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)changeElementWithWarning:(NSString *)warning do:(void (^)(void))task;
- (void)changeElementWithoutWarningDo:(void (^)(void))task;

@end

@implementation MPMainViewController
@synthesize showSettings = _showSettings;
@synthesize activeElement = _activeElement;
@synthesize searchDelegate = _searchDelegate;
@synthesize typeButton = _typeButton;
@synthesize helpView = _helpView;
@synthesize siteName = _siteName;
@synthesize passwordCounter = _passwordCounter;
@synthesize passwordIncrementer = _passwordIncrementer;
@synthesize passwordEdit = _passwordEdit;
@synthesize passwordUpgrade = _passwordUpgrade;
@synthesize contentContainer = _contentContainer;
@synthesize displayContainer = _displayContainer;
@synthesize helpContainer = _helpContainer;
@synthesize contentTipContainer = _copiedContainer;
@synthesize userNameTipContainer = _userNameTipContainer;
@synthesize alertContainer = _alertContainer;
@synthesize alertTitle = _alertTitle;
@synthesize alertBody = _alertBody;
@synthesize contentTipBody = _contentTipBody;
@synthesize userNameTipBody = _userNameTipBody;
@synthesize toolTipEditIcon = _contentTipEditIcon;
@synthesize searchTipContainer = _searchTipContainer;
@synthesize actionsTipContainer = _actionsTipContainer;
@synthesize typeTipContainer = _typeTipContainer;
@synthesize toolTipContainer = _toolTipContainer;
@synthesize toolTipBody = _toolTipBody;
@synthesize userNameContainer = _userNameContainer;
@synthesize userNameField = _userNameField;
@synthesize contentField = _contentField;
@synthesize contentTipCleanup = _contentTipCleanup, toolTipCleanup = _toolTipCleanup;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    [self updateHelpHiddenAnimated:NO];
    [self updateSettingsHiddenAnimated:NO];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MP_ChooseType"])
        ((MPTypeViewController *)[segue destinationViewController]).delegate = self;
}

- (void)viewDidLoad {

    self.searchDelegate                                  = [MPSearchDelegate new];
    self.searchDelegate.delegate                         = self;
    self.searchDelegate.searchDisplayController          = self.searchDisplayController;
    self.searchDelegate.searchTipContainer               = self.searchTipContainer;
    self.searchDisplayController.searchBar.delegate      = self.searchDelegate;
    self.searchDisplayController.delegate                = self.searchDelegate;
    self.searchDisplayController.searchResultsDelegate   = self.searchDelegate;
    self.searchDisplayController.searchResultsDataSource = self.searchDelegate;

    [self.passwordIncrementer addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(resetPasswordCounter:)]];
    [self.userNameContainer addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editUserName:)]];
    [self.userNameContainer addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyUserName)]];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    self.contentField.font = [UIFont fontWithName:@"Exo-Black" size:self.contentField.font.pointSize];

    self.alertBody.text         = nil;
    self.toolTipEditIcon.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserverForName:MPNotificationElementUpdated object:nil queue:nil
                                                  usingBlock:^void(NSNotification *note) {
                                                      if (self.activeElement.type & MPElementTypeClassStored
                                                       && ![[self.activeElement.content description] length])
                                                          [self showToolTip:@"Tap        to set a password." withIcon:self.toolTipEditIcon];
                                                      if (self.activeElement.requiresExplicitMigration)
                                                          [self showToolTip:@"Password is outdated. Tap      to upgrade it." withIcon:nil];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPNotificationSignedOut object:nil queue:nil
                                                  usingBlock:^void(NSNotification *note) {
                                                      self.activeElement = nil;
                                                  }];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Main will appear.");
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];

    if (![MPAppDelegate get].activeUser)
        [self.navigationController presentViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"MPUnlockViewController"]
                                                animated:animated completion:nil];
    if (self.activeElement.user != [MPAppDelegate get].activeUser)
        self.activeElement                      = nil;
    self.searchDisplayController.searchBar.text = nil;

    self.alertContainer.alpha      = 0;
    self.searchTipContainer.alpha  = 0;
    self.actionsTipContainer.alpha = 0;
    self.typeTipContainer.alpha    = 0;
    self.toolTipContainer.alpha    = 0;

    [self updateHelpHiddenAnimated:NO];
    [self updateSettingsHiddenAnimated:NO];
    [self updateAnimated:animated];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    if (![[MPiOSConfig get].actionsTipShown boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.actionsTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                [MPiOSConfig get].actionsTipShown = PearlBool(YES);

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.2f animations:^{
                        self.actionsTipContainer.alpha = 0;
                    }                completion:^(BOOL finished_) {
                        if (![self.activeElement.name length])
                            [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
                                self.searchTipContainer.alpha = 1;
                            }];
                    }];
                });
            }
        }];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Main will disappear.");
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {

    [self setContentField:nil];
    [self setTypeButton:nil];
    [self setHelpView:nil];
    [self setSiteName:nil];
    [self setPasswordCounter:nil];
    [self setPasswordIncrementer:nil];
    [self setPasswordEdit:nil];
    [self setPasswordUpgrade:nil];
    [self setContentContainer:nil];
    [self setHelpContainer:nil];
    [self setContentTipContainer:nil];
    [self setAlertContainer:nil];
    [self setAlertTitle:nil];
    [self setAlertBody:nil];
    [self setContentTipBody:nil];
    [self setToolTipEditIcon:nil];
    [self setSearchTipContainer:nil];
    [self setActionsTipContainer:nil];
    [self setTypeTipContainer:nil];
    [self setToolTipContainer:nil];
    [self setToolTipBody:nil];
    [self setDisplayContainer:nil];
    [self setUserNameField:nil];
    [self setUserNameTipContainer:nil];
    [self setUserNameTipBody:nil];
    [self setUserNameContainer:nil];
    [super viewDidUnload];
}

- (void)updateAnimated:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            [self updateAnimated:NO];
        }];
        return;
    }

    [self setHelpChapter:self.activeElement? @"2": @"1"];
    self.siteName.text = self.activeElement.name;

    self.passwordCounter.alpha     = 0;
    self.passwordIncrementer.alpha = 0;
    self.passwordEdit.alpha        = 0;
    self.passwordUpgrade.alpha     = 0;

    if (self.activeElement.requiresExplicitMigration)
        self.passwordUpgrade.alpha = 0.5f;

    else {
        if (self.activeElement.type & MPElementTypeClassGenerated) {
            self.passwordCounter.alpha     = 0.5f;
            self.passwordIncrementer.alpha = 0.5f;
        } else
            if (self.activeElement.type & MPElementTypeClassStored)
                self.passwordEdit.alpha = 0.5f;
    }

    [self.typeButton setTitle:NSStringFromMPElementType(self.activeElement.type)
                     forState:UIControlStateNormal];
    self.typeButton.alpha = NSStringFromMPElementType(self.activeElement.type).length? 1: 0;

    self.contentField.enabled  = NO;
    self.userNameField.enabled = NO;

    if ([self.activeElement isKindOfClass:[MPElementGeneratedEntity class]])
        self.passwordCounter.text = PearlString(@"%u", ((MPElementGeneratedEntity *)self.activeElement).counter);

    self.contentField.text = @"";
    if (self.activeElement.name && ![self.activeElement isDeleted])
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *description = [self.activeElement.content description];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.contentField.text = description;
            });
        });
}

- (void)toggleHelpAnimated:(BOOL)animated {

    [self setHelpHidden:![[MPiOSConfig get].helpHidden boolValue] animated:animated];
}

- (void)setHelpHidden:(BOOL)hidden animated:(BOOL)animated {

    [MPiOSConfig get].helpHidden = PearlBool(hidden);
    [self updateHelpHiddenAnimated:animated];
}

- (void)updateHelpHiddenAnimated:(BOOL)animated {
    
    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            [self updateHelpHiddenAnimated:NO];
        }];
        return;
    }
    
    if ([[MPiOSConfig get].helpHidden boolValue]) {
        self.contentContainer.frame  = CGRectSetHeight(self.contentContainer.frame, self.view.bounds.size.height - 44);
        self.helpContainer.frame     = CGRectSetY(self.helpContainer.frame, self.view.bounds.size.height);
    } else {
        self.contentContainer.frame  = CGRectSetHeight(self.contentContainer.frame, 225);
        self.helpContainer.frame     = CGRectSetY(self.helpContainer.frame, 266);
    }
}

- (IBAction)toggleSettings {
    
    [self toggleSettingsAnimated:YES];
}

- (void)toggleSettingsAnimated:(BOOL)animated {

    [MPiOSConfig get].settingsHidden = PearlBoolNot([MPiOSConfig get].settingsHidden);
    self.showSettings = ![[MPiOSConfig get].settingsHidden boolValue];
    [self updateSettingsHiddenAnimated:animated];
}

- (void)updateSettingsHiddenAnimated:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            [self updateSettingsHiddenAnimated:NO];
        }];
        return;
    }

    if (self.showSettings) {
        self.displayContainer.frame      = CGRectSetHeight(self.displayContainer.frame, 137);
    } else {
        self.displayContainer.frame      = CGRectSetHeight(self.displayContainer.frame, 87);
    }

}

- (void)setHelpChapter:(NSString *)chapter {

    [TestFlight passCheckpoint:PearlString(MPCheckpointHelpChapter @"_%@", chapter)];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:[@"#" stringByAppendingString:chapter]
                            relativeToURL:[[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"]];
        [self.helpView loadRequest:[NSURLRequest requestWithURL:url]];
    });
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    NSString *error = [self.helpView stringByEvaluatingJavaScriptFromString:
                                      PearlString(@"setClass('%@');", ClassNameFromMPElementType(self.activeElement.type))];
    if (error.length)
    err(@"helpView.setClass: %@", error);
}

- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon {

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.contentTipCleanup)
            self.contentTipCleanup(NO);

        self.contentTipBody.text = message;
        self.contentTipCleanup   = ^(BOOL finished) {
            icon.hidden            = YES;
            self.contentTipCleanup = nil;
        };

        icon.hidden = NO;
        [UIView animateWithDuration:0.3f animations:^{
            self.contentTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.contentTipContainer.alpha = 0;
                    }                completion:self.contentTipCleanup];
                });
            }
        }];
    });
}

- (void)showUserNameTip:(NSString *)message {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.userNameTipBody.text = message;

        [UIView animateWithDuration:0.3f animations:^{
            self.userNameTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.userNameTipContainer.alpha = 0;
                    }];
                });
            }
        }];
    });
}

- (void)showToolTip:(NSString *)message withIcon:(UIImageView *)icon {

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.toolTipCleanup)
            self.toolTipCleanup(NO);

        self.toolTipBody.text = message;
        self.toolTipCleanup   = ^(BOOL finished) {
            icon.hidden         = YES;
            self.toolTipCleanup = nil;
        };

        icon.hidden = NO;
        [UIView animateWithDuration:0.3f animations:^{
            self.toolTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.toolTipContainer.alpha = 0;
                    }                completion:self.toolTipCleanup];
                });
            }
        }];
    });
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.alertTitle.text = title;
        NSRange scrollRange = NSMakeRange(self.alertBody.text.length, message.length);
        if ([self.alertBody.text length])
            self.alertBody.text = [NSString stringWithFormat:@"%@\n\n---\n\n%@", self.alertBody.text, message];
        else
            self.alertBody.text = message;
        [self.alertBody scrollRangeToVisible:scrollRange];

        [UIView animateWithDuration:0.3f animations:^{
            self.alertContainer.alpha = 1;
        }];
    });
}

#pragma mark - Protocols

- (IBAction)copyContent {

    if (!self.activeElement)
        return;

    inf(@"Copying password for: %@", self.activeElement.name);
    [UIPasteboard generalPasteboard].string = [self.activeElement.content description];

    [self showContentTip:@"Copied!" withIcon:nil];

    [TestFlight passCheckpoint:MPCheckpointCopyToPasteboard];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCopyToPasteboard
                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         NSStringFromMPElementType(self.activeElement.type), @"type",
                                                                         PearlUnsignedInteger(self.activeElement.version),
                                                                         @"version",
                                                                         nil]];
}

- (IBAction)copyUserName {

    if (!self.activeElement.userName)
        return;

    inf(@"Copying user name for: %@", self.activeElement.name);
    [UIPasteboard generalPasteboard].string = [self.activeElement.content description];

    [self showUserNameTip:@"Copied!"];

    [TestFlight passCheckpoint:MPCheckpointCopyUserNameToPasteboard];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCopyUserNameToPasteboard
                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         NSStringFromMPElementType(self.activeElement.type), @"type",
                                                                         PearlUnsignedInteger(self.activeElement.version),
                                                                         @"version",
                                                                         nil]];
}

- (IBAction)incrementPasswordCounter {

    if (![self.activeElement isKindOfClass:[MPElementGeneratedEntity class]])
     // Not of a type that supports a password counter.
        return;

    [self changeElementWithWarning:
           @"You are incrementing the site's password counter.\n\n"
            @"If you continue, a new password will be generated for this site.  "
            @"You will then need to update your account's old password to this newly generated password.\n\n"
            @"You can reset the counter by holding down on this button."
                                do:^{
                                    inf(@"Incrementing password counter for: %@", self.activeElement.name);
                                    ++((MPElementGeneratedEntity *)self.activeElement).counter;

                                    [TestFlight passCheckpoint:MPCheckpointIncrementPasswordCounter];
                                    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointIncrementPasswordCounter
                                                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                         NSStringFromMPElementType(
                                                                                                          self.activeElement.type), @"type",
                                                                                                         PearlUnsignedInteger(self.activeElement.version),
                                                                                                         @"version",
                                                                                                         nil]];
                                }];
}

- (IBAction)resetPasswordCounter:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
     // Only fire when the gesture was first detected.
        return;
    if (![self.activeElement isKindOfClass:[MPElementGeneratedEntity class]])
     // Not of a type that supports a password counter.
        return;
    if (((MPElementGeneratedEntity *)self.activeElement).counter == 1)
     // Counter has initial value, no point resetting.
        return;

    [self changeElementWithWarning:
           @"You are resetting the site's password counter.\n\n"
            @"If you continue, the site's password will change back to its original value.  "
            @"You will then need to update your account's password back to this original value."
                                do:^{
                                    inf(@"Resetting password counter for: %@", self.activeElement.name);
                                    ((MPElementGeneratedEntity *)self.activeElement).counter = 1;

                                    [TestFlight passCheckpoint:MPCheckpointResetPasswordCounter];
                                    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointResetPasswordCounter
                                                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                         NSStringFromMPElementType(
                                                                                                          self.activeElement.type), @"type",
                                                                                                         PearlUnsignedInteger(self.activeElement.version),
                                                                                                         @"version",
                                                                                                         nil]];
                                }];
}

- (IBAction)editUserName:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
     // Only fire when the gesture was first detected.
        return;
    
    if (!self.activeElement)
        return;

    self.userNameField.enabled = YES;
    [self.userNameField becomeFirstResponder];

    [TestFlight passCheckpoint:MPCheckpointEditUserName];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointEditUserName attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                             NSStringFromMPElementType(
                                                                                                              self.activeElement.type),
                                                                                                             @"type",
                                                                                                             PearlUnsignedInteger(self.activeElement.version),
                                                                                                             @"version",
                                                                                                             nil]];
}

- (void)changeElementWithWarning:(NSString *)warning do:(void (^)(void))task; {

    [PearlAlert showAlertWithTitle:@"Password Change" message:warning viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [self changeElementWithoutWarningDo:task];
    }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

- (void)changeElementWithoutWarningDo:(void (^)(void))task; {

    // Update element, keeping track of the old password.
    NSString *oldPassword = [self.activeElement.content description];
    task();
    NSString *newPassword = [self.activeElement.content description];
    [[MPAppDelegate get] saveContext];
    [self updateAnimated:YES];

    // Show new and old password.
    if ([oldPassword length] && ![oldPassword isEqualToString:newPassword])
        [self showAlertWithTitle:@"Password Changed!"
                         message:PearlString(@"The password for %@ has changed.\n\n"
                                              @"IMPORTANT:\n"
                                              @"Don't forget to update the site with your new password! "
                                              @"Your old password was:\n"
                                              @"%@", self.activeElement.name, oldPassword)];
}


- (IBAction)editPassword {

    if (self.activeElement.type & MPElementTypeClassStored) {
        self.contentField.enabled = YES;
        [self.contentField becomeFirstResponder];

        [TestFlight passCheckpoint:MPCheckpointEditPassword];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointEditPassword
                                                   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                             NSStringFromMPElementType(
                                                                              self.activeElement.type), @"type",
                                                                             PearlUnsignedInteger(self.activeElement.version),
                                                                             @"version",
                                                                             nil]];
    }
}

- (IBAction)upgradePassword {

    [self changeElementWithWarning:
           self.activeElement.type & MPElementTypeClassGenerated?
            @"You are upgrading the site.\n\n"
             @"This upgrade improves the site's compatibility with the latest version of Master Password.\n\n"
             @"Your password will change and you will need to update your site's account."
            :
            @"You are upgrading the site.\n\n"
             @"This upgrade improves the site's compatibility with the latest version of Master Password."
                                do:^{
                                    inf(@"Explicitly migrating element: %@", self.activeElement);
                                    MPElementMigrate(self.activeElement, YES);

                                    [TestFlight passCheckpoint:MPCheckpointExplicitMigration];
                                    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointExplicitMigration
                                                                               attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                         NSStringFromMPElementType(
                                                                                                          self.activeElement.type), @"type",
                                                                                                         PearlUnsignedInteger(self.activeElement.version),
                                                                                                         @"version",
                                                                                                         nil]];
                                }];
}

- (IBAction)closeAlert {

    [UIView animateWithDuration:0.3f animations:^{
        self.alertContainer.alpha = 0;
    }                completion:^(BOOL finished) {
        if (finished)
            self.alertBody.text = nil;
    }];

    [TestFlight passCheckpoint:MPCheckpointCloseAlert];
}

- (IBAction)action:(id)sender {

    [PearlSheet showSheetWithTitle:nil message:nil viewStyle:UIActionSheetStyleAutomatic
                 tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                     if (buttonIndex == [sheet cancelButtonIndex])
                         return;

                     switch (buttonIndex - [sheet firstOtherButtonIndex]) {
                         case 0: {
                             inf(@"Action: Toggle Help");
                             [self toggleHelpAnimated:YES];
                             break;
                         }
                         case 1: {
                             inf(@"Action: FAQ");
                             [self setHelpChapter:@"faq"];
                             [self setHelpHidden:NO animated:YES];
                             break;
                         }
                         case 2: {
                             inf(@"Action: Guide");
                             [[MPAppDelegate get] showGuide];
                             break;
                         }
                         case 3: {
                             inf(@"Action: Preferences");
                             [self performSegueWithIdentifier:@"UserProfile" sender:self];
                             break;
                         }
#ifdef ADHOC
                         case 4: {
                             inf(@"Action: Feedback via TestFlight");
                             [TestFlight openFeedbackView];
                             break;
                         }
                         case 5:
#else
                         case 4: {
                             inf(@"Action: Feedback via Mail");
                             if (![MFMailComposeViewController canSendMail])
                                 [PearlAlert showAlertWithTitle:@"Sending Feedback"
                                                        message:
                                                         @"We'd love to hear what you think!\n\n"
                                                          @"Please send any comments or reports to:\n"
                                                          @"masterpassword@lyndir.com"
                                                      viewStyle:UIAlertViewStyleDefault
                                                      initAlert:nil tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay
                                                    otherTitles:nil];

                             else {
                                 [PearlAlert showAlertWithTitle:@"Sending Feedback"
                                                        message:
                                                         @"We'd love to hear what you think!\n\n"
                                                          @"If you're having trouble, it may help us if you can first reproduce the problem "
                                                          @"and then include log files in your message."
                                                      viewStyle:UIAlertViewStyleDefault
                                                      initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                                     MFMailComposeViewController *composer = [MFMailComposeViewController new];
                                     [composer setMailComposeDelegate:self];
                                     [composer setToRecipients:[NSArray arrayWithObject:@"Master Password Development <masterpassword@lyndir.com>"]];
                                     [composer setSubject:PearlString(@"Feedback for Master Password [%@]",
                                                                      [[PearlKeyChain deviceIdentifier] stringByDeletingMatchesOf:@"-.*"])];
                                     [composer setMessageBody:
                                                PearlString(
                                                 @"\n\n\n"
                                                  @"--\n"
                                                  @"%@\n"
                                                  @"Master Password %@, build %@",
                                                 [MPAppDelegate get].activeUser.name,
                                                 [PearlInfoPlist get].CFBundleShortVersionString,
                                                 [PearlInfoPlist get].CFBundleVersion)
                                                       isHTML:NO];

                                     if (buttonIndex_ == [alert_ firstOtherButtonIndex]) {
                                         PearlLogLevel logLevel = [[MPiOSConfig get].sendInfo boolValue]? PearlLogLevelDebug
                                          : PearlLogLevelInfo;
                                         [composer addAttachmentData:[[[PearlLogger get] formatMessagesWithLevel:logLevel] dataUsingEncoding:NSUTF8StringEncoding]
                                                            mimeType:@"text/plain"
                                                            fileName:PearlString(@"%@-%@.log",
                                                                                 [[NSDateFormatter rfc3339DateFormatter] stringFromDate:[NSDate date]],
                                                                                 [PearlKeyChain deviceIdentifier])];
                                     }

                                     [self presentModalViewController:composer animated:YES];
                                 }
                                                    cancelTitle:nil otherTitles:@"Include Logs", @"No Logs", nil];
                             }
                             break;
                         }
                         case 5:
#endif
                         {
                             inf(@"Action: Sign out");
                             [[MPAppDelegate get] signOutAnimated:YES];
                             break;
                         }
                     }

                     [TestFlight passCheckpoint:MPCheckpointAction];
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:nil otherTitles:
     [[MPiOSConfig get].helpHidden boolValue]? @"Show Help": @"Hide Help", @"FAQ", @"Tutorial", @"Preferences", @"Feedback", @"Sign Out",
     nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {

    if (error)
    err(@"Feedback composer error: %@, result: %d", error, result);
    else
     inf(@"Feedback composer result: %d", result);

    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (MPElementType)selectedType {

    return self.activeElement.type;
}

- (void)didSelectType:(MPElementType)type {

    [self changeElementWithWarning:
           @"You are about to change the type of this password.\n\n"
            @"If you continue, the password for this site will change.  "
            @"You will need to update your account's old password to the new one."
                                do:^{
                                    // Update password type.
                                    if (ClassFromMPElementType(type) != ClassFromMPElementType(self.activeElement.type))
                                     // Type requires a different class of element.  Recreate the element.
                                        [[MPAppDelegate managedObjectContext] performBlockAndWait:^{
                                            MPElementEntity *newElement = [NSEntityDescription insertNewObjectForEntityForName:ClassNameFromMPElementType(
                                             type)
                                                                                                        inManagedObjectContext:[MPAppDelegate managedObjectContext]];
                                            newElement.name     = self.activeElement.name;
                                            newElement.user     = self.activeElement.user;
                                            newElement.uses     = self.activeElement.uses;
                                            newElement.lastUsed = self.activeElement.lastUsed;

                                            [[MPAppDelegate managedObjectContext] deleteObject:self.activeElement];
                                            self.activeElement = newElement;
                                        }];

                                    self.activeElement.type = type;

                                    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationElementUpdated
                                                                                        object:self.activeElement];
                                }];
}

- (void)didSelectElement:(MPElementEntity *)element {

    inf(@"Selected: %@", element.name);

    [self closeAlert];

    if (element) {
        self.activeElement = element;
        if ([self.activeElement use] == 1)
            [self showAlertWithTitle:@"New Site" message:
                                                  PearlString(@"You've just created a password for %@.\n\n"
                                                               @"IMPORTANT:\n"
                                                               @"Go to %@ and set or change the password for your account to the password above.\n"
                                                               @"Do this right away: if you forget, you may have trouble remembering which password to use to log into the site later on.",
                                                              self.activeElement.name, self.activeElement.name)];
        [[MPAppDelegate get] saveContext];

        if (![[MPiOSConfig get].typeTipShown boolValue])
            [UIView animateWithDuration:0.5f animations:^{
                self.typeTipContainer.alpha = 1;
            }                completion:^(BOOL finished) {
                if (finished) {
                    [MPiOSConfig get].typeTipShown = PearlBool(YES);

                    dispatch_after(
                     dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                         [UIView animateWithDuration:0.2f animations:^{
                             self.typeTipContainer.alpha = 0;
                         }];
                     });
                }
            }];

        [self.searchDisplayController setActive:NO animated:YES];
        self.searchDisplayController.searchBar.text = self.activeElement.name;

        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationElementUpdated object:self.activeElement];
        [TestFlight passCheckpoint:PearlString(MPCheckpointUseType @"_%@", NSStringFromMPElementType(self.activeElement.type))];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointUseType attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                            NSStringFromMPElementType(
                                                                                                             self.activeElement.type),
                                                                                                            @"type",
                                                                                                            PearlUnsignedInteger(self.activeElement.version),
                                                                                                            @"version",
                                                                                                            nil]];
    }

    self.showSettings = ![[MPiOSConfig get].settingsHidden boolValue] || (element.userName != nil);
    [self updateAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.contentField)
        [self.contentField resignFirstResponder];
    if (textField == self.userNameField)
        [self.userNameField resignFirstResponder];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.contentField) {
        self.contentField.enabled = NO;
        if (![self.activeElement isKindOfClass:[MPElementStoredEntity class]])
         // Not of a type whose content can be edited.
            return;

        if ([((MPElementStoredEntity *)self.activeElement).content isEqual:self.contentField.text])
         // Content hasn't changed.
            return;

        [self changeElementWithoutWarningDo:^{
            ((MPElementStoredEntity *)self.activeElement).content = self.contentField.text;
        }];
    }

    if (textField == self.userNameField) {
        self.userNameField.enabled  = NO;
        if (![[MPiOSConfig get].userNameTipShown boolValue]) {
            [self showUserNameTip:@"Tap to copy or hold to edit."];
            [MPiOSConfig get].userNameTipShown = PearlBool(YES);
        }

        if ([self.userNameField.text length])
            self.activeElement.userName = self.userNameField.text;
        else
            self.activeElement.userName = nil;
        
        [[MPAppDelegate get] saveContext];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        inf(@"External link: %@", [request URL]);
        [TestFlight passCheckpoint:MPCheckpointExternalLink];

        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

@end
