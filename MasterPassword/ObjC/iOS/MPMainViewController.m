//
//  MPMainViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPMainViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPElementListAllViewController.h"

@interface MPMainViewController()

@property(nonatomic) BOOL suppressOutdatedAlert;
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
    if ([[segue identifier] isEqualToString:@"MP_AllSites"]) {
        ((MPElementListAllViewController *)[[segue destinationViewController] topViewController]).delegate = self;
        ((MPElementListAllViewController *)[[segue destinationViewController] topViewController]).filter = sender;
    }
}

- (void)viewDidLoad {

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    self.alertBody.text = nil;
    self.toolTipEditIcon.hidden = YES;

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:self queue:nil usingBlock:
            ^(NSNotification *note) {
                self.suppressOutdatedAlert = NO;
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPElementUpdatedNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
            ^(NSNotification *note) {
                MPElementEntity *activeElement = [self activeElementForMainThread];
                if (activeElement.type & MPElementTypeClassStored &&
                    ![[activeElement.algorithm resolveContentForElement:activeElement usingKey:[MPAppDelegate_Shared get].key] length])
                    [self showToolTip:@"Tap        to set a password." withIcon:self.toolTipEditIcon];
                if (activeElement.requiresExplicitMigration)
                    [self showToolTip:@"Password outdated. Tap to upgrade it." withIcon:nil];
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedOutNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
            ^(NSNotification *note) {
                BOOL animated = [(note.userInfo)[@"animated"] boolValue];

                _activeElementOID = nil;
                self.suppressOutdatedAlert = NO;
                [self updateAnimated:NO];

                [[[PearlSheet activeSheets] copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    [obj cancelSheetAnimated:NO];
                }];
                if (![self.navigationController presentedViewController])
                    [self.navigationController popToRootViewControllerAnimated:animated];
                else
                    [self.navigationController dismissViewControllerAnimated:animated completion:^{
                        [self.navigationController popToRootViewControllerAnimated:animated];
                    }];
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidChangeNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
            ^(NSNotification *note) {
                if (!self.activeElementForMainThread)
                    [self didSelectElement:nil];
            }];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    if (![super respondsToSelector:@selector(prefersStatusBarHidden)])
        [UIApp setStatusBarHidden:NO withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];
    [self.navigationController setNavigationBarHidden:NO animated:animated];

    MPElementEntity *activeElement = [self activeElementForMainThread];
    if (activeElement.user != [[MPiOSAppDelegate get] activeUserForMainThread])
        _activeElementOID = nil;

    self.searchDisplayController.searchBar.text = nil;
    self.alertContainer.hidden = NO;
    self.outdatedAlertContainer.hidden = NO;
    self.searchTipContainer.hidden = NO;
    self.actionsTipContainer.hidden = NO;
    self.typeTipContainer.hidden = NO;
    self.toolTipContainer.hidden = NO;
    self.contentTipContainer.hidden = NO;
    self.loginNameTipContainer.hidden = NO;

    [self updateAnimated:NO];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    inf(@"Main will appear");

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:moc];
        if ([MPAlgorithmDefault migrateUser:activeUser inContext:moc] && !self.suppressOutdatedAlert)
            [UIView animateWithDuration:0.3f animations:^{
                self.outdatedAlertContainer.alpha = 1;
                self.suppressOutdatedAlert = YES;
            }];
        [moc saveToStore];
    }];

    if (![[MPiOSConfig get].actionsTipShown boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.actionsTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (!finished)
                return;

            [MPiOSConfig get].actionsTipShown = @YES;

            dispatch_after( dispatch_time( DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC) ), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.2f animations:^{
                    self.actionsTipContainer.alpha = 0;
                }                completion:^(BOOL finished_) {
                    if (!_activeElementOID)
                        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
                            self.searchTipContainer.alpha = 1;
                        }];
                }];
            } );
        }];

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

    MPElementEntity *activeElement = [self activeElementForMainThread];
    [self setHelpChapter:activeElement? @"2": @"1"];
    [self updateHelpHiddenAnimated:NO];

    self.passwordCounter.alpha = 0;
    self.passwordIncrementer.alpha = 0;
    self.passwordEdit.alpha = 0;
    self.passwordUpgrade.alpha = 0;
    self.passwordUser.alpha = 0;
    self.displayContainer.alpha = 0;

    if (activeElement) {
        self.passwordUser.alpha = 0.5f;
        self.displayContainer.alpha = 1.0f;
    }

    if (activeElement.requiresExplicitMigration)
        self.passwordUpgrade.alpha = 0.5f;

    else {
        if (activeElement.type & MPElementTypeClassGenerated) {
            self.passwordCounter.alpha = 0.5f;
            self.passwordIncrementer.alpha = 0.5f;
        }
        else if (activeElement.type & MPElementTypeClassStored)
            self.passwordEdit.alpha = 0.5f;
    }

    self.siteName.text = activeElement.name;

    self.typeButton.alpha = activeElement? 1: 0;
    [self.typeButton setTitle:activeElement.typeName
                     forState:UIControlStateNormal];

    if ([activeElement isKindOfClass:[MPElementGeneratedEntity class]])
        self.passwordCounter.text = PearlString( @"%lu", (unsigned long)((MPElementGeneratedEntity *)activeElement).counter );

    self.contentField.enabled = NO;
    self.contentField.text = @"";
    if (activeElement.name && ![activeElement isDeleted])
        [activeElement.algorithm resolveContentForElement:activeElement usingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.contentField.text = result;
            } );
        }];

    self.loginNameField.enabled = NO;
    self.loginNameField.text = activeElement.loginName;
    self.siteInfoHidden = !activeElement || ([[MPiOSConfig get].siteInfoHidden boolValue] && (activeElement.loginName == nil));
    [self updateUserHiddenAnimated:NO];
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
        self.contentContainer.frame = CGRectSetHeight( self.contentContainer.frame, self.view.bounds.size.height - 44 /* search bar */);
        self.helpContainer.frame = CGRectSetY( self.helpContainer.frame, self.view.bounds.size.height - 20 /* pull-up */);
    }
    else {
        self.contentContainer.frame = CGRectSetHeight( self.contentContainer.frame, 225 );
        [self.helpContainer setFrameFromCurrentSizeAndParentPaddingTop:CGFLOAT_MAX right:0 bottom:0 left:0];
    }
}

- (IBAction)toggleUser {

    [self toggleUserAnimated:YES];
}

- (void)toggleUserAnimated:(BOOL)animated {

    [MPiOSConfig get].siteInfoHidden = @(!self.siteInfoHidden);
    self.siteInfoHidden = [[MPiOSConfig get].siteInfoHidden boolValue];
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
        self.displayContainer.frame = CGRectSetHeight( self.displayContainer.frame, 87 );
    }
    else {
        self.displayContainer.frame = CGRectSetHeight( self.displayContainer.frame, 137 );
    }
}

- (void)setHelpChapter:(NSString *)chapter {

    MPCheckpoint( MPCheckpointHelpChapter, @{
            @"chapter" : NilToNSNull(chapter)
    } );

    dispatch_async( dispatch_get_main_queue(), ^{
        NSURL *url = [NSURL URLWithString:[@"#" stringByAppendingString:chapter]
                            relativeToURL:[[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"]];
        [self.helpView loadRequest:[NSURLRequest requestWithURL:url]];
    } );
}

- (IBAction)panHelpDown:(UIPanGestureRecognizer *)sender {

    CGFloat targetY = MIN(self.view.bounds.size.height - 20, 246 + [sender translationInView:self.helpContainer].y);
    BOOL hideHelp = YES;
    if (targetY <= 246) {
        hideHelp = NO;
        targetY = 246;
    }

    self.helpContainer.frame = CGRectSetY( self.helpContainer.frame, targetY );

    if (sender.state == UIGestureRecognizerStateEnded)
        [self setHelpHidden:hideHelp animated:YES];
}

- (IBAction)panHelpUp:(UIPanGestureRecognizer *)sender {

    CGFloat targetY = MAX(246, self.view.bounds.size.height - 20 + [sender translationInView:self.helpContainer].y);
    BOOL hideHelp = NO;
    if (targetY >= self.view.bounds.size.height - 20) {
        hideHelp = YES;
        targetY = self.view.bounds.size.height - 20;
    }

    self.helpContainer.frame = CGRectSetY( self.helpContainer.frame, targetY );

    if (sender.state == UIGestureRecognizerStateEnded)
        [self setHelpHidden:hideHelp animated:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    MPElementEntity *activeElement = [self activeElementForMainThread];
    NSString *error = [self.helpView stringByEvaluatingJavaScriptFromString:
            PearlString( @"setClass('%@');", activeElement.typeClassName )];
    if (error.length)
    err(@"helpView.setClass: %@", error);
}

- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon {

    dispatch_async( dispatch_get_main_queue(), ^{
        if (self.contentTipCleanup)
            self.contentTipCleanup( NO );

        __weak MPMainViewController *wSelf = self;
        self.contentTipBody.text = message;
        self.contentTipCleanup = ^(BOOL finished) {
            icon.hidden = YES;
            wSelf.contentTipCleanup = nil;
        };

        icon.hidden = NO;
        [UIView animateWithDuration:0.3f animations:^{
            self.contentTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time( DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC );
                dispatch_after( popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.contentTipContainer.alpha = 0;
                    }                completion:self.contentTipCleanup];
                } );
            }
        }];
    } );
}

- (void)showLoginNameTip:(NSString *)message {

    dispatch_async( dispatch_get_main_queue(), ^{
        self.loginNameTipBody.text = message;

        [UIView animateWithDuration:0.3f animations:^{
            self.loginNameTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time( DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC );
                dispatch_after( popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.loginNameTipContainer.alpha = 0;
                    }];
                } );
            }
        }];
    } );
}

- (void)showToolTip:(NSString *)message withIcon:(UIImageView *)icon {

    dispatch_async( dispatch_get_main_queue(), ^{
        if (self.toolTipCleanup)
            self.toolTipCleanup( NO );

        __weak MPMainViewController *wSelf = self;
        self.toolTipBody.text = message;
        self.toolTipCleanup = ^(BOOL finished) {
            icon.hidden = YES;
            wSelf.toolTipCleanup = nil;
        };

        icon.hidden = NO;
        [UIView animateWithDuration:0.3f animations:^{
            self.toolTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time( DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC );
                dispatch_after( popTime, dispatch_get_main_queue(), ^(void) {
                    [UIView animateWithDuration:0.2f animations:^{
                        self.toolTipContainer.alpha = 0;
                    }                completion:self.toolTipCleanup];
                } );
            }
        }];
    } );
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {

    dispatch_async( dispatch_get_main_queue(), ^{
        self.alertTitle.text = title;
        NSRange scrollRange = NSMakeRange( self.alertBody.text.length, message.length );
        if ([self.alertBody.text length])
            self.alertBody.text = [NSString stringWithFormat:@"%@\n\n---\n\n%@", self.alertBody.text, message];
        else
            self.alertBody.text = message;
        [self.alertBody scrollRangeToVisible:scrollRange];

        [UIView animateWithDuration:0.3f animations:^{
            self.alertContainer.alpha = 1;
        }];
    } );
}

#pragma mark - Protocols

- (IBAction)copyContent {

    MPElementEntity *activeElement = [self activeElementForMainThread];
    inf(@"Copying password for: %@", activeElement.name);
    MPCheckpoint( MPCheckpointCopyToPasteboard, @{
            @"type"      : NilToNSNull(activeElement.typeName),
            @"version"   : @(activeElement.version),
            @"emergency" : @NO
    } );

    [activeElement.algorithm resolveContentForElement:activeElement usingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        if (!result)
                // Nothing to copy.
            return;

        [UIPasteboard generalPasteboard].string = result;
        [self showContentTip:@"Copied!" withIcon:nil];
    }];
}

- (IBAction)copyLoginName:(UITapGestureRecognizer *)sender {

    MPElementEntity *activeElement = [self activeElementForMainThread];
    if (!activeElement.loginName)
        return;

    inf(@"Copying user name for: %@", activeElement.name);
    [UIPasteboard generalPasteboard].string = activeElement.loginName;

    [self showLoginNameTip:@"Copied!"];

    MPCheckpoint( MPCheckpointCopyLoginNameToPasteboard, @{
            @"type"    : NilToNSNull(activeElement.typeName),
            @"version" : @(activeElement.version)
    } );
}

- (IBAction)incrementPasswordCounter {

    [self changeActiveElementWithWarning:
            @"You are incrementing the site's password counter.\n\n"
                    @"If you continue, a new password will be generated for this site.  "
                    @"You will then need to update your account's old password to this newly generated password.\n\n"
                    @"You can reset the counter by holding down on this button."
                                      do:^BOOL(MPElementEntity *activeElement, NSManagedObjectContext *context) {
                                          if (![activeElement isKindOfClass:[MPElementGeneratedEntity class]]) {
                                              // Not of a type that supports a password counter.
                                              err(@"Cannot increment password counter: Element is not generated: %@", activeElement.name);
                                              return NO;
                                          }
                                          MPElementGeneratedEntity *activeGeneratedElement = (MPElementGeneratedEntity *)activeElement;

                                          inf(@"Incrementing password counter for: %@", activeGeneratedElement.name);
                                          ++activeGeneratedElement.counter;

                                          MPCheckpoint( MPCheckpointIncrementPasswordCounter, @{
                                                  @"type"    : NilToNSNull(activeGeneratedElement.typeName),
                                                  @"version" : @(activeGeneratedElement.version),
                                                  @"counter" : @(activeGeneratedElement.counter)
                                          } );
                                          return YES;
                                      }];
}

- (IBAction)resetPasswordCounter:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
            // Only fire when the gesture was first detected.
        return;
    MPElementEntity *activeElement = [self activeElementForMainThread];
    if (![activeElement isKindOfClass:[MPElementGeneratedEntity class]]) {
        // Not of a type that supports a password counter.
        err(@"Cannot reset password counter: Element is not generated: %@", activeElement.name);
        return;
    }
    else if (((MPElementGeneratedEntity *)activeElement).counter == 1)
            // Counter has initial value, no point resetting.
        return;

    [self changeActiveElementWithWarning:
            @"You are resetting the site's password counter.\n\n"
                    @"If you continue, the site's password will change back to its original value.  "
                    @"You will then need to update your account's password back to this original value."
                                      do:^BOOL(MPElementEntity *activeElement_, NSManagedObjectContext *context) {
                                          inf(@"Resetting password counter for: %@", activeElement_.name);
                                          ((MPElementGeneratedEntity *)activeElement_).counter = 1;

                                          MPCheckpoint( MPCheckpointResetPasswordCounter, @{
                                                  @"type"    : NilToNSNull(activeElement_.typeName),
                                                  @"version" : @(activeElement_.version)
                                          } );
                                          return YES;
                                      }];
}

- (IBAction)editLoginName:(UILongPressGestureRecognizer *)sender {

    if (sender.state != UIGestureRecognizerStateBegan)
            // Only fire when the gesture was first detected.
        return;

    MPElementEntity *activeElement = [self activeElementForMainThread];
    if (!activeElement)
        return;

    self.loginNameField.enabled = YES;
    [self.loginNameField becomeFirstResponder];

    MPCheckpoint( MPCheckpointEditLoginName, @{
            @"type"    : NilToNSNull(activeElement.typeName),
            @"version" : @(activeElement.version)
    } );
}

- (void)changeActiveElementWithWarning:(NSString *)warning
                                    do:(BOOL (^)(MPElementEntity *activeElement, NSManagedObjectContext *context))task {

    [PearlAlert showAlertWithTitle:@"Password Change" message:warning viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [self changeActiveElementWithoutWarningDo:task];
    }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

- (void)changeActiveElementWithoutWarningDo:(BOOL (^)(MPElementEntity *, NSManagedObjectContext *context))task {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPElementEntity *activeElement = [self activeElementInContext:context];
        if (!activeElement)
            return;

        MPKey *key = [MPAppDelegate_Shared get].key;
        NSString *oldPassword = [activeElement.algorithm resolveContentForElement:activeElement usingKey:key];
        if (!task( activeElement, context ))
            return;

        activeElement = [self activeElementInContext:context];
        NSString *newPassword = [activeElement.algorithm resolveContentForElement:activeElement usingKey:key];

        // Save.
        [context saveToStore];

        // Update the UI.
        dispatch_async( dispatch_get_main_queue(), ^{
            [self updateAnimated:YES];

            // Show new and old password.
            if ([oldPassword length] && ![oldPassword isEqualToString:newPassword])
                [self showAlertWithTitle:@"Password Changed!"
                                 message:PearlString( @"The password for %@ has changed.\n\n"
                                         @"IMPORTANT:\n"
                                         @"Don't forget to update the site with your new password! "
                                         @"Your old password was:\n"
                                         @"%@", activeElement.name, oldPassword )];
        } );
    }];
}

- (MPElementEntity *)activeElementForMainThread {

    return [self activeElementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
}

- (MPElementEntity *)activeElementInContext:(NSManagedObjectContext *)moc {

    if (!_activeElementOID)
        return nil;

    NSError *error;
    MPElementEntity *activeElement = (MPElementEntity *)[moc existingObjectWithID:_activeElementOID error:&error];
    if (!activeElement)
    err(@"Couldn't retrieve active element: %@", error);

    return activeElement;
}

- (IBAction)editPassword {

    MPElementEntity *activeElement = [self activeElementForMainThread];
    if (!(activeElement.type & MPElementTypeClassStored)) {
        // Not of a type that supports editing the content.
        err(@"Cannot edit content: Element is not stored: %@", activeElement.name);
        return;
    }

    self.contentField.enabled = YES;
    [self.contentField becomeFirstResponder];

    MPCheckpoint( MPCheckpointEditPassword, @{
            @"type"    : NilToNSNull(activeElement.typeName),
            @"version" : @(activeElement.version)
    } );
}

- (IBAction)upgradePassword {

    MPElementEntity *activeElement = [self activeElementForMainThread];
    if (!activeElement)
        return;

    NSString *warning = activeElement.type & MPElementTypeClassGenerated?
                        @"You are upgrading the site.\n\n"
                                @"This upgrade improves the site's compatibility with the latest version of Master Password.\n\n"
                                @"Your password will change and you will need to update your site's account."
                        :
                        @"You are upgrading the site.\n\n"
                                @"This upgrade improves the site's compatibility with the latest version of Master Password.";

    [self changeActiveElementWithWarning:warning do:
            ^BOOL(MPElementEntity *activeElement_, NSManagedObjectContext *context) {
                inf(@"Explicitly migrating element: %@", activeElement_);
                [activeElement_ migrateExplicitly:YES];

                MPCheckpoint( MPCheckpointExplicitMigration, @{
                        @"type"    : NilToNSNull(activeElement_.typeName),
                        @"version" : @(activeElement_.version)
                } );
                return YES;
            }];
}

- (IBAction)searchOutdatedElements {

    [self performSegueWithIdentifier:@"MP_AllSites" sender:MPElementListFilterOutdated];
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
                [[MPiOSAppDelegate get] showFeedbackWithLogs:YES forVC:self];
                break;
            }
//#endif

            default: {
                wrn(@"Unsupported action: %ld", (long)(buttonIndex - [sheet firstOtherButtonIndex]));
                break;
            }
        }
    }
                       cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:nil otherTitles:
            @"FAQ",
            @"Overview",
            @"User Profile",
            @"Other Apps",
            @"Feedback",
            nil];
}

- (MPElementType)selectedType {

    return [self selectedElement].type;
}

- (MPElementEntity *)selectedElement {

    return [self activeElementForMainThread];
}

- (void)didSelectType:(MPElementType)type {

    [self changeActiveElementWithWarning:
            @"You are about to change the type of this password.\n\n"
                    @"If you continue, the password for this site will change.  "
                    @"You will need to update your account's old password to the new one."
                                      do:^BOOL(MPElementEntity *activeElement, NSManagedObjectContext *context) {
                                          _activeElementOID = [[MPiOSAppDelegate get] changeElement:activeElement saveInContext:context
                                                                                             toType:type].objectID;
                                          return YES;
                                      }];
}

- (void)didSelectElement:(MPElementEntity *)element {

    inf(@"Selected: %@", element.name);
    _activeElementOID = element.objectID;
    [self closeAlert];

    if (element) {
        [self changeActiveElementWithoutWarningDo:^BOOL(MPElementEntity *activeElement, NSManagedObjectContext *context) {
            if ([activeElement use] == 1)
                [self showAlertWithTitle:@"New Site" message:
                        PearlString( @"You've just created a password for %@.\n\n"
                                @"IMPORTANT:\n"
                                @"Go to %@ and set or change the password for your account to the password above.\n"
                                @"Do this right away: if you forget, you may have trouble remembering which password to use to log into the site later on.",
                                activeElement.name, activeElement.name )];
            return YES;
        }];

        if (![[MPiOSConfig get].typeTipShown boolValue])
            [UIView animateWithDuration:0.5f animations:^{
                self.typeTipContainer.alpha = 1;
            }                completion:^(BOOL finished) {
                if (finished) {
                    [MPiOSConfig get].typeTipShown = PearlBool(YES);

                    dispatch_after(
                            dispatch_time( DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC) ), dispatch_get_main_queue(), ^{
                                [UIView animateWithDuration:0.2f animations:^{
                                    self.typeTipContainer.alpha = 0;
                                }];
                            } );
                }
            }];

        MPCheckpoint( MPCheckpointUseType, @{
                @"type"    : NilToNSNull(element.typeName),
                @"version" : @(element.version)
        } );
    }

    [self.searchDisplayController setActive:NO animated:YES];
    self.searchDisplayController.searchBar.text = element.name;

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
        MPElementEntity *activeElement = [self activeElementForMainThread];
        MPKey *key = [MPAppDelegate_Shared get].key;
        if (![activeElement isKindOfClass:[MPElementStoredEntity class]]) {
            // Not of a type whose content can be edited.
            err(@"Cannot update element content: Element is not stored: %@", activeElement.name);
            return;
        }
        else if ([[activeElement.algorithm resolveContentForElement:activeElement usingKey:key] isEqual:self.contentField.text])
                // Content hasn't changed.
            return;

        [self changeActiveElementWithoutWarningDo:^BOOL(MPElementEntity *activeElement_, NSManagedObjectContext *context) {
            [activeElement_.algorithm saveContent:self.contentField.text toElement:activeElement_ usingKey:key];
            return YES;
        }];
    }

    if (textField == self.loginNameField) {
        self.loginNameField.enabled = NO;
        if (![[MPiOSConfig get].loginNameTipShown boolValue]) {
            [self showLoginNameTip:@"Tap to copy or hold to edit."];
            [MPiOSConfig get].loginNameTipShown = @YES;
        }

        [self changeActiveElementWithoutWarningDo:^BOOL(MPElementEntity *activeElement, NSManagedObjectContext *context) {
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

        [UIApp openURL:[request URL]];
        return NO;
    }

    return YES;
}

@end
