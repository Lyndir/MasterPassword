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
#import "MPElementListAllViewController.h"
#import "MPElementListSearchController.h"


@interface MPMainViewController()
@property (nonatomic)BOOL suppressOutdatedAlert;
@end

@implementation MPMainViewController {
    NSManagedObjectID *_activeElementOID;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotate {

    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {

    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    [self updateHelpHiddenAnimated:NO];
    [self updateUserHiddenAnimated:NO];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MP_ChooseType"])
        ((MPTypeViewController *)[segue destinationViewController]).delegate = self;
    if ([[segue identifier] isEqualToString:@"MP_AllSites"])
        ((MPElementListAllViewController *)[((UINavigationController *)[segue destinationViewController]) topViewController]).delegate = self;
}

- (void)viewDidLoad {

    self.searchDelegate                                  = [MPElementListSearchController new];
    self.searchDelegate.delegate                         = self;
    self.searchDelegate.searchDisplayController          = self.searchDisplayController;
    self.searchDelegate.searchTipContainer               = self.searchTipContainer;
    self.searchDisplayController.searchBar.delegate      = self.searchDelegate;
    self.searchDisplayController.delegate                = self.searchDelegate;
    self.searchDisplayController.searchResultsDelegate   = self.searchDelegate;
    self.searchDisplayController.searchResultsDataSource = self.searchDelegate;

    [self.passwordIncrementer addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(resetPasswordCounter:)]];
    [self.loginNameContainer addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                action:@selector(editLoginName:)]];
    [self.loginNameContainer addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyLoginName:)]];
    [self.outdatedAlertBack addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(infoOutdatedAlert)]];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    self.alertBody.text         = nil;
    self.toolTipEditIcon.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:self queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.suppressOutdatedAlert = NO;
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPElementUpdatedNotification object:nil queue:nil usingBlock:
     ^void(NSNotification *note) {
         [self activeElementDo:^(MPElementEntity *activeElement) {
             if (activeElement.type & MPElementTypeClassStored && ![[activeElement.content description] length])
                 [self showToolTip:@"Tap        to set a password." withIcon:self.toolTipEditIcon];
             if (activeElement.requiresExplicitMigration)
                 [self showToolTip:@"Password outdated. Tap to upgrade it." withIcon:nil];
         }];
     }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedOutNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                _activeElementOID = nil;
                self.suppressOutdatedAlert = NO;
                [self updateAnimated:NO];
                [self.navigationController popToRootViewControllerAnimated:[[note.userInfo objectForKey:@"animated"] boolValue]];
            }];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    [self activeElementDo:^(MPElementEntity *activeElement) {
        if (activeElement.user != [MPAppDelegate get].activeUser)
            _activeElementOID = nil;
    }];

    self.searchDisplayController.searchBar.text = nil;
    self.alertContainer.alpha                   = 0;
    self.outdatedAlertContainer.alpha           = 0;
    self.searchTipContainer.alpha               = 0;
    self.actionsTipContainer.alpha              = 0;
    self.typeTipContainer.alpha                 = 0;
    self.toolTipContainer.alpha                 = 0;

    [self updateAnimated:NO];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    inf(@"Main will appear");

    // Sometimes, the search bar gets stuck in some sort of first-responder mode that it can't get out of...
    [[self.view.window findFirstResponderInHierarchy] resignFirstResponder];

    // Needed for when we appear after a modal VC dismisses:
    // We can't present until the other modal VC has been fully dismissed and presenting in -viewWillAppear: will fail.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        MPUserEntity *activeUser = [MPAppDelegate get].activeUser;
        if ([MPAlgorithmDefault migrateUser:activeUser] && !self.suppressOutdatedAlert)
            [UIView animateWithDuration:0.3f animations:^{
                self.outdatedAlertContainer.alpha = 1;
                self.suppressOutdatedAlert = YES;
            }];
        [activeUser.managedObjectContext saveToStore];
    });

    if (![[MPiOSConfig get].actionsTipShown boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.actionsTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (!finished)
                return;

            [MPiOSConfig get].actionsTipShown = @YES;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2f animations:^{
                    self.actionsTipContainer.alpha = 0;
                }                completion:^(BOOL finished_) {
                    if (!_activeElementOID)
                        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
                            self.searchTipContainer.alpha = 1;
                        }];
                }];
            });
        }];

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Main"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Main will disappear.");
    [super viewWillDisappear:animated];
}

- (void)updateAnimated:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            [self updateAnimated:NO];
        }];
        return;
    }

    [self activeElementDo:^(MPElementEntity *activeElement) {
        [self setHelpChapter:activeElement? @"2": @"1"];
        [self updateHelpHiddenAnimated:NO];

        self.passwordCounter.alpha     = 0;
        self.passwordIncrementer.alpha = 0;
        self.passwordEdit.alpha        = 0;
        self.passwordUpgrade.alpha     = 0;
        self.passwordUser.alpha        = 0;
        self.displayContainer.alpha    = 0;

        if (activeElement) {
            self.passwordUser.alpha     = 0.5f;
            self.displayContainer.alpha = 1.0f;
        }

        if (activeElement.requiresExplicitMigration)
            self.passwordUpgrade.alpha = 0.5f;

        else {
            if (activeElement.type & MPElementTypeClassGenerated) {
                self.passwordCounter.alpha     = 0.5f;
                self.passwordIncrementer.alpha = 0.5f;
            } else
                if (activeElement.type & MPElementTypeClassStored)
                    self.passwordEdit.alpha = 0.5f;
        }

        self.siteName.text = activeElement.name;

        self.typeButton.alpha = activeElement? 1: 0;
        [self.typeButton setTitle:activeElement.typeName
                         forState:UIControlStateNormal];

        if ([activeElement isKindOfClass:[MPElementGeneratedEntity class]])
            self.passwordCounter.text = PearlString(@"%u", ((MPElementGeneratedEntity *)activeElement).counter);

        self.contentField.enabled = NO;
        self.contentField.text    = @"";
        if (activeElement.name && ![activeElement isDeleted])
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSString *description = [activeElement.content description];

                dispatch_async(dispatch_get_main_queue(), ^{
                    self.contentField.text = description;
                });
            });

        self.loginNameField.enabled = NO;
        self.loginNameField.text    = activeElement.loginName;
        self.siteInfoHidden = !activeElement || ([[MPiOSConfig get].siteInfoHidden boolValue] && (activeElement.loginName == nil));
        [self updateUserHiddenAnimated:NO];
    }];
}

- (void)toggleHelpAnimated:(BOOL)animated {

    [self setHelpHidden:![[MPiOSConfig get].helpHidden boolValue] animated:animated];
}

- (void)setHelpHidden:(BOOL)hidden animated:(BOOL)animated {

    [MPiOSConfig get].helpHidden = @(hidden);
    [self updateHelpHiddenAnimated:animated];
}

- (void)updateHelpHiddenAnimated:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            [self updateHelpHiddenAnimated:NO];
        }];
        return;
    }

    self.pullUpView.hidden = ![[MPiOSConfig get].helpHidden boolValue];
    self.pullDownView.hidden = [[MPiOSConfig get].helpHidden boolValue];

    if ([[MPiOSConfig get].helpHidden boolValue]) {
        self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, self.view.bounds.size.height - 44 /* search bar */);
        self.helpContainer.frame    = CGRectSetY(self.helpContainer.frame, self.view.bounds.size.height - 20);
    } else {
        self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, 225);
        self.helpContainer.frame    = CGRectSetY(self.helpContainer.frame, 246);
    }
}

- (IBAction)toggleUser {

    [self toggleUserAnimated:YES];
}

- (void)toggleUserAnimated:(BOOL)animated {

    [MPiOSConfig get].siteInfoHidden = PearlBool(!self.siteInfoHidden);
    self.siteInfoHidden              = [[MPiOSConfig get].siteInfoHidden boolValue];
    [self updateUserHiddenAnimated:animated];
}

- (void)updateUserHiddenAnimated:(BOOL)animated {

    if (animated) {
        [UIView animateWithDuration:0.3f animations:^{
            [self updateUserHiddenAnimated:NO];
        }];
        return;
    }

    if (self.siteInfoHidden) {
        self.displayContainer.frame = CGRectSetHeight(self.displayContainer.frame, 87);
    } else {
        self.displayContainer.frame = CGRectSetHeight(self.displayContainer.frame, 137);
    }

}

- (void)setHelpChapter:(NSString *)chapter {

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:PearlString(MPCheckpointHelpChapter @"_%@", chapter)];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointHelpChapter attributes:@{@"chapter": chapter}];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:[@"#" stringByAppendingString:chapter]
                            relativeToURL:[[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"]];
        [self.helpView loadRequest:[NSURLRequest requestWithURL:url]];
    });
}

- (IBAction)panHelpDown:(UIPanGestureRecognizer *)sender {

    CGFloat targetY = MIN(self.view.bounds.size.height - 20, 246 + [sender translationInView:self.helpContainer].y);
    BOOL hideHelp = YES;
    if (targetY <= 246) {
        hideHelp = NO;
        targetY = 246;
    }

    self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, targetY);

    if (sender.state == UIGestureRecognizerStateEnded)
        [self setHelpHidden:hideHelp animated:YES];
}

- (IBAction)panHelpUp:(UIPanGestureRecognizer *)sender {

    CGFloat targetY = MAX(246, self.view.bounds.size.height - 20 + [sender translationInView:self.helpContainer].y);
    BOOL hideHelp = NO;
    if (targetY >= self.view.bounds.size.height - 20) {
        hideHelp = YES;
        targetY = self.view.bounds.size.height - 20 ;
    }

    self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, targetY);

    if (sender.state == UIGestureRecognizerStateEnded)
        [self setHelpHidden:hideHelp animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    [self activeElementDo:^(MPElementEntity *activeElement) {
        NSString *error = [self.helpView stringByEvaluatingJavaScriptFromString:
                                          PearlString(@"setClass('%@');", activeElement.typeClassName)];
        if (error.length)
        err(@"helpView.setClass: %@", error);
    }];
}

- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon {

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.contentTipCleanup)
            self.contentTipCleanup(NO);

        __weak MPMainViewController *wSelf = self;
        self.contentTipBody.text = message;
        self.contentTipCleanup   = ^(BOOL finished) {
            icon.hidden             = YES;
            wSelf.contentTipCleanup = nil;
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

- (void)showLoginNameTip:(NSString *)message {

    dispatch_async(dispatch_get_main_queue(), ^{
        self.loginNameTipBody.text = message;

        [UIView animateWithDuration:0.3f animations:^{
            self.loginNameTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.loginNameTipContainer.alpha = 0;
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

        __weak MPMainViewController *wSelf = self;
        self.toolTipBody.text = message;
        self.toolTipCleanup   = ^(BOOL finished) {
            icon.hidden     = YES;
            wSelf.toolTipCleanup = nil;
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

    [self activeElementDo:^(MPElementEntity *activeElement) {
        id content = activeElement.content;
        if (!content)
         // Nothing to copy.
            return;

        inf(@"Copying password for: %@", activeElement.name);
        [UIPasteboard generalPasteboard].string = [content description];

        [self showContentTip:@"Copied!" withIcon:nil];

#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPCheckpointCopyToPasteboard];
#endif
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCopyToPasteboard attributes:@{@"type"    : activeElement.typeName,
                                                                                                        @"version" : @(activeElement.version)}];
    }];
}

- (IBAction)copyLoginName:(UITapGestureRecognizer *)sender {

    [self activeElementDo:^(MPElementEntity *activeElement) {
        if (!activeElement.loginName)
            return;

        inf(@"Copying user name for: %@", activeElement.name);
        [UIPasteboard generalPasteboard].string = activeElement.loginName;

        [self showLoginNameTip:@"Copied!"];

#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPCheckpointCopyLoginNameToPasteboard];
#endif
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCopyLoginNameToPasteboard
                                                   attributes:@{@"type"    : activeElement.typeName,
                                                                @"version" : @(activeElement.version)}];
    }];
}

- (IBAction)incrementPasswordCounter {

    [self changeActiveElementWithWarning:
           @"You are incrementing the site's password counter.\n\n"
            @"If you continue, a new password will be generated for this site.  "
            @"You will then need to update your account's old password to this newly generated password.\n\n"
            @"You can reset the counter by holding down on this button."
                                do:^BOOL(MPElementEntity *activeElement) {
                                    if (![activeElement isKindOfClass:[MPElementGeneratedEntity class]]) {
                                        // Not of a type that supports a password counter.
                                        err(@"Cannot increment password counter: Element is not generated: %@", activeElement.name);
                                        return NO;
                                    }

                                    inf(@"Incrementing password counter for: %@", activeElement.name);
                                    ++((MPElementGeneratedEntity *)activeElement).counter;

#ifdef TESTFLIGHT_SDK_VERSION
                                    [TestFlight passCheckpoint:MPCheckpointIncrementPasswordCounter];
#endif
                                    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointIncrementPasswordCounter
                                                                               attributes:@{@"type": activeElement.typeName,
                                                                                            @"version": @(activeElement.version)}];
                                    return YES;
                                }];
}

- (IBAction)resetPasswordCounter:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
     // Only fire when the gesture was first detected.
        return;
    __block BOOL abort = NO;
    [self activeElementDo:^(MPElementEntity *activeElement) {
        if (![activeElement isKindOfClass:[MPElementGeneratedEntity class]]) {
            // Not of a type that supports a password counter.
            err(@"Cannot reset password counter: Element is not generated: %@", activeElement.name);
            abort = YES;
        } else
            if (((MPElementGeneratedEntity *)activeElement).counter == 1)
             // Counter has initial value, no point resetting.
                abort = YES;
    }];
    if (abort)
        return;

    [self changeActiveElementWithWarning:
           @"You are resetting the site's password counter.\n\n"
            @"If you continue, the site's password will change back to its original value.  "
            @"You will then need to update your account's password back to this original value."
                                do:^BOOL(MPElementEntity *activeElement){
                                    inf(@"Resetting password counter for: %@", activeElement.name);
                                    ((MPElementGeneratedEntity *)activeElement).counter = 1;

#ifdef TESTFLIGHT_SDK_VERSION
                                    [TestFlight passCheckpoint:MPCheckpointResetPasswordCounter];
#endif
                                    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointResetPasswordCounter
                                                                               attributes:@{@"type": activeElement.typeName,
                                                                                            @"version": @(activeElement.version)}];
                                    return YES;
                                }];
}

- (IBAction)editLoginName:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
     // Only fire when the gesture was first detected.
        return;

    [self activeElementDo:^(MPElementEntity *activeElement) {
        if (!activeElement)
            return;

        self.loginNameField.enabled = YES;
        [self.loginNameField becomeFirstResponder];

#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPCheckpointEditLoginName];
#endif
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointEditLoginName attributes:@{@"type"    : activeElement.typeName,
                                                                                                     @"version" : @(activeElement.version)}];
    }];
}

- (void)changeActiveElementWithWarning:(NSString *)warning do:(BOOL (^)(MPElementEntity *activeElement))task; {

    [PearlAlert showAlertWithTitle:@"Password Change" message:warning viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [self changeActiveElementWithoutWarningDo:task];
    }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

- (void)changeActiveElementWithoutWarningDo:(BOOL (^)(MPElementEntity *activeElement))task; {

    // Update element, keeping track of the old password.
    [self activeElementDo:^(MPElementEntity *activeElement) {
        NSManagedObjectContext *moc = activeElement.managedObjectContext;
        [moc performBlock:^{

            // Perform the task.
            NSString *oldPassword = [activeElement.content description];
            if (!task(activeElement))
                return;
            NSString *newPassword = [activeElement.content description];

            // Save.
            NSError *error;
            if (![moc save:&error])
            err(@"While saving changes to: %@, error: %@", activeElement.name, error);

            // Update the UI.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateAnimated:YES];

                // Show new and old password.
                if ([oldPassword length] && ![oldPassword isEqualToString:newPassword])
                    [self showAlertWithTitle:@"Password Changed!"
                                     message:PearlString(@"The password for %@ has changed.\n\n"
                                                          @"IMPORTANT:\n"
                                                          @"Don't forget to update the site with your new password! "
                                                          @"Your old password was:\n"
                                                          @"%@", activeElement.name, oldPassword)];
            });
        }];
    }];
}

- (void)activeElementDo:(void (^)(MPElementEntity *activeElement))task {

    if (!_activeElementOID) {
        task(nil);
        return;
    }

    NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextForThreadIfReady];
    if (!moc) {
        task(nil);
        return;
    }

    NSError *error;
    MPElementEntity *activeElement = (MPElementEntity *)[moc existingObjectWithID:_activeElementOID error:&error];
    if (!activeElement)
        err(@"Couldn't retrieve active element: %@", error);

    task(activeElement);
}


- (IBAction)editPassword {

    [self activeElementDo:^(MPElementEntity *activeElement) {
        if (!(activeElement.type & MPElementTypeClassStored)) {
            // Not of a type that supports editing the content.
            err(@"Cannot edit content: Element is not stored: %@", activeElement.name);
            return;
        }

        self.contentField.enabled = YES;
        [self.contentField becomeFirstResponder];

#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPCheckpointEditPassword];
#endif
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointEditPassword attributes:@{@"type"    : activeElement.typeName,
                                                                                                    @"version" : @(activeElement.version)}];
    }];
}

- (IBAction)upgradePassword {

    __block NSString *warning = nil;
    [self activeElementDo:^(MPElementEntity *activeElement) {
        warning = activeElement.type & MPElementTypeClassGenerated?
         @"You are upgrading the site.\n\n"
          @"This upgrade improves the site's compatibility with the latest version of Master Password.\n\n"
          @"Your password will change and you will need to update your site's account."
         :
         @"You are upgrading the site.\n\n"
          @"This upgrade improves the site's compatibility with the latest version of Master Password.";
    }];
    if (!warning)
        return;

    [self changeActiveElementWithWarning:warning do:
            ^BOOL(MPElementEntity *activeElement) {
                inf(@"Explicitly migrating element: %@", activeElement);
                [activeElement migrateExplicitly:YES];

#ifdef TESTFLIGHT_SDK_VERSION
                [TestFlight passCheckpoint:MPCheckpointExplicitMigration];
#endif
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointExplicitMigration attributes:@{
                        @"type"    : activeElement.typeName,
                        @"version" : @(activeElement.version)
                }];
                return YES;
            }];
}

- (IBAction)searchOutdatedElements {

    self.searchDisplayController.searchBar.selectedScopeButtonIndex    = MPSearchScopeOutdated;
    self.searchDisplayController.searchBar.searchResultsButtonSelected = YES;
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (IBAction)closeAlert {

    [UIView animateWithDuration:0.3f animations:^{
        self.alertContainer.alpha = 0;
    }                completion:^(BOOL finished) {
        if (finished)
            self.alertBody.text = nil;
    }];
}

- (IBAction)closeOutdatedAlert {

    [UIView animateWithDuration:0.3f animations:^{
        self.outdatedAlertContainer.alpha = 0;
    }];
}

- (IBAction)infoOutdatedAlert {

    [self setHelpChapter:@"outdated"];
    [self setHelpHidden:NO animated:YES];
    [self closeOutdatedAlert];
    self.suppressOutdatedAlert = NO;
}

- (IBAction)action:(id)sender {

    [PearlSheet showSheetWithTitle:nil viewStyle:UIActionSheetStyleAutomatic
                         initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == [sheet cancelButtonIndex])
            return;

        switch (buttonIndex - [sheet firstOtherButtonIndex]) {
            case 0: {
                inf(@"Action: FAQ");
                [self setHelpChapter:@"faq"];
                [self setHelpHidden:NO animated:YES];
                break;
            }
            case 1: {
                inf(@"Action: Guide");
                [[MPAppDelegate get] showGuide];
                break;
            }
            case 2: {
                inf(@"Action: Preferences");
                [self performSegueWithIdentifier:@"MP_UserProfile" sender:self];
                break;
            }
            case 3: {
                inf(@"Action: Other Apps");
                [self performSegueWithIdentifier:@"MP_OtherApps" sender:self];
                break;
            }
//#if defined(ADHOC) && defined(TESTFLIGHT_SDK_VERSION)
//                         case 4: {
//                             inf(@"Action: Feedback via TestFlight");
//                             [TestFlight openFeedbackView];
//                             break;
//                         }
//#else
            case 4: {
                inf(@"Action: Feedback via Mail");
                [[MPAppDelegate get] showFeedbackWithLogs:YES forVC:self];
                break;
            }
//#endif

            default: {
                wrn(@"Unsupported action: %u", buttonIndex - [sheet firstOtherButtonIndex]);
                break;
            }
        }
    }
                       cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:nil otherTitles:
            @"？ FAQ",
            @"ℹ Quick Guide",
            @"⚙ Preferences",
            @"⬇ Other Apps",
            @"✉ Feedback",
            nil];
}

- (MPElementType)selectedType {

    return [self selectedElement].type;
}

- (MPElementEntity *)selectedElement {

    __block MPElementEntity *selectedElement;
    [self activeElementDo:^(MPElementEntity *activeElement) {
        selectedElement = activeElement;
    }];

    return selectedElement;
}

- (void)didSelectType:(MPElementType)type {

    [self changeActiveElementWithWarning:
           @"You are about to change the type of this password.\n\n"
            @"If you continue, the password for this site will change.  "
            @"You will need to update your account's old password to the new one."
                                      do:^BOOL(MPElementEntity *activeElement){
                                          if ([activeElement.algorithm classOfType:type] != activeElement.typeClass) {
                                              // Type requires a different class of element.  Recreate the element.
                                              MPElementEntity *newElement = [NSEntityDescription insertNewObjectForEntityForName:[activeElement.algorithm classNameOfType:type]
                                                                                                          inManagedObjectContext:activeElement.managedObjectContext];
                                              newElement.name      = activeElement.name;
                                              newElement.user      = activeElement.user;
                                              newElement.uses      = activeElement.uses;
                                              newElement.lastUsed  = activeElement.lastUsed;
                                              newElement.version   = activeElement.version;
                                              newElement.loginName = activeElement.loginName;

                                              [activeElement.managedObjectContext deleteObject:activeElement];
                                              _activeElementOID = newElement.objectID;
                                              activeElement = newElement;
                                          }
                                          activeElement.type = type;

                                          [[NSNotificationCenter defaultCenter] postNotificationName:MPElementUpdatedNotification
                                                                                              object:activeElement.objectID];
                                          return YES;
                                      }];
}

- (void)didSelectElement:(MPElementEntity *)element {

    if (!element)
        return;

    _activeElementOID = element.objectID;
    [self closeAlert];
    [self changeActiveElementWithoutWarningDo:^BOOL(MPElementEntity *activeElement) {
        if ([activeElement use] == 1)
            [self showAlertWithTitle:@"New Site" message:
                                                  PearlString(@"You've just created a password for %@.\n\n"
                                                               @"IMPORTANT:\n"
                                                               @"Go to %@ and set or change the password for your account to the password above.\n"
                                                               @"Do this right away: if you forget, you may have trouble remembering which password to use to log into the site later on.",
                                                              activeElement.name, activeElement.name)];
        return YES;
    }];

    [self activeElementDo:^(MPElementEntity *activeElement) {
        inf(@"Selected: %@", activeElement.name);
        dbg(@"Element:\n%@", [activeElement debugDescription]);

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
        self.searchDisplayController.searchBar.text = activeElement.name;

        [[NSNotificationCenter defaultCenter] postNotificationName:MPElementUpdatedNotification object:activeElement.objectID];
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:PearlString(MPCheckpointUseType @"_%@", activeElement.typeShortName)];
#endif
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointUseType attributes:@{@"type"    : activeElement.typeName,
                                                                                               @"version" : @(activeElement.version)}];
    }];
    [self updateAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.contentField)
        [self.contentField resignFirstResponder];
    if (textField == self.loginNameField)
        [self.loginNameField resignFirstResponder];

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.contentField) {
        self.contentField.enabled = NO;
        __block BOOL abort = NO;
        [self activeElementDo:^(MPElementEntity *activeElement) {
            if (![activeElement isKindOfClass:[MPElementStoredEntity class]]) {
                // Not of a type whose content can be edited.
                err(@"Cannot update element content: Element is not stored: %@", activeElement.name);
                abort = YES;
            } else if ([((MPElementStoredEntity *)activeElement).content isEqual:self.contentField.text])
                // Content hasn't changed.
                abort = YES;
        }];
        if (abort)
            return;

        [self changeActiveElementWithoutWarningDo:^BOOL(MPElementEntity *activeElement) {
            ((MPElementStoredEntity *)activeElement).content = self.contentField.text;
            return YES;
        }];
    }

    if (textField == self.loginNameField) {
        self.loginNameField.enabled = NO;
        if (![[MPiOSConfig get].loginNameTipShown boolValue]) {
            [self showLoginNameTip:@"Tap to copy or hold to edit."];
            [MPiOSConfig get].loginNameTipShown = @YES;
        }

        [self changeActiveElementWithoutWarningDo:^BOOL(MPElementEntity *activeElement) {
            if ([self.loginNameField.text length])
                activeElement.loginName = self.loginNameField.text;
            else
                activeElement.loginName = nil;

            return YES;
        }];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([[[request URL] query] isEqualToString:@"outdated"]) {
            [self searchOutdatedElements];
            return NO;
        }

        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

@end
