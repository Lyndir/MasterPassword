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
#import "ATConnect.h"


@interface MPMainViewController (Private)

- (void)updateAnimated:(BOOL)animated;
- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)changeElementWithWarning:(NSString *)warning do:(void (^)(void))task;
- (void)changeElementWithoutWarningDo:(void (^)(void))task;

@end

@implementation MPMainViewController
@synthesize activeElement = _activeElement;
@synthesize searchResultsController = _searchResultsController;
@synthesize typeButton = _typeButton;
@synthesize helpView = _helpView;
@synthesize siteName = _siteName;
@synthesize passwordCounter = _passwordCounter;
@synthesize passwordIncrementer = _passwordIncrementer;
@synthesize passwordEdit = _passwordEdit;
@synthesize contentContainer = _contentContainer;
@synthesize helpContainer = _helpContainer;
@synthesize contentTipContainer = _copiedContainer;
@synthesize alertContainer = _alertContainer;
@synthesize alertTitle = _alertTitle;
@synthesize alertBody = _alertBody;
@synthesize contentTipBody = _contentTipBody;
@synthesize contentTipEditIcon = _contentTipEditIcon;
@synthesize searchTipContainer = _searchTipContainer;
@synthesize actionsTipContainer = _actionsTipContainer;
@synthesize typeTipContainer = _typeTipContainer;
@synthesize contentField = _contentField;
@synthesize contentTipCleanup;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    [self setHelpHidden:![self isHelpVisible] animated:NO];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MP_ChooseType"])
        ((MPTypeViewController *)[segue destinationViewController]).delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    if (![MPAppDelegate get].activeUser)
        [self.navigationController performSegueWithIdentifier:@"MP_Unlock" sender:self];
    if (self.activeElement.user != [MPAppDelegate get].activeUser)
        self.activeElement                      = nil;
    self.searchDisplayController.searchBar.text = nil;

    self.searchTipContainer.alpha  = 0;
    self.actionsTipContainer.alpha = 0;
    self.typeTipContainer.alpha    = 0;

    [self setHelpHidden:[[MPiOSConfig get].helpHidden boolValue] animated:animated];
    [self updateAnimated:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    if ([[MPiOSConfig get].firstRun boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.actionsTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
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

- (void)viewDidLoad {

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    self.contentField.font = [UIFont fontWithName:@"Exo-Black" size:self.contentField.font.pointSize];

    self.alertBody.text            = nil;
    self.contentTipEditIcon.hidden = YES;

    [super viewDidLoad];
}

- (void)viewDidUnload {

    [self setContentField:nil];
    [self setTypeButton:nil];
    [self setSearchResultsController:nil];
    [self setHelpView:nil];
    [self setSiteName:nil];
    [self setPasswordCounter:nil];
    [self setPasswordIncrementer:nil];
    [self setPasswordEdit:nil];
    [self setContentContainer:nil];
    [self setHelpContainer:nil];
    [self setContentTipContainer:nil];
    [self setAlertContainer:nil];
    [self setAlertTitle:nil];
    [self setAlertBody:nil];
    [self setContentTipBody:nil];
    [self setContentTipEditIcon:nil];
    [self setSearchTipContainer:nil];
    [self setActionsTipContainer:nil];
    [self setTypeTipContainer:nil];
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

    self.passwordCounter.alpha     = self.activeElement.type & MPElementTypeClassGenerated? 0.5f: 0;
    self.passwordIncrementer.alpha = self.activeElement.type & MPElementTypeClassGenerated? 0.5f: 0;
    self.passwordEdit.alpha        = self.activeElement.type & MPElementTypeClassStored? 0.5f: 0;

    [self.typeButton setTitle:NSStringFromMPElementType(self.activeElement.type)
                     forState:UIControlStateNormal];
    self.typeButton.alpha = NSStringFromMPElementType(self.activeElement.type).length? 1: 0;

    self.contentField.enabled = NO;

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

- (BOOL)isHelpVisible {

    return self.helpContainer.frame.origin.y == 216;
}

- (void)toggleHelpAnimated:(BOOL)animated {

    [self setHelpHidden:[self isHelpVisible] animated:animated];
}

- (void)setHelpHidden:(BOOL)hidden animated:(BOOL)animated {

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            if (hidden) {
                self.contentContainer.frame  = CGRectSetHeight(self.contentContainer.frame, self.view.bounds.size.height - 44);
                self.helpContainer.frame     = CGRectSetY(self.helpContainer.frame, self.view.bounds.size.height);
                [MPiOSConfig get].helpHidden = [NSNumber numberWithBool:YES];
            } else {
                self.contentContainer.frame  = CGRectSetHeight(self.contentContainer.frame, 175);
                self.helpContainer.frame     = CGRectSetY(self.helpContainer.frame, 216);
                [MPiOSConfig get].helpHidden = [NSNumber numberWithBool:NO];
            }
        }];
    });
}

- (void)setHelpChapter:(NSString *)chapter {

    [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointHelpChapter, chapter]];

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

    [UIPasteboard generalPasteboard].string = [self.activeElement.content description];

    [self showContentTip:@"Copied!" withIcon:nil];

    [TestFlight passCheckpoint:MPTestFlightCheckpointCopyToPasteboard];
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
                                    ++((MPElementGeneratedEntity *)self.activeElement).counter;
                                }];

    [TestFlight passCheckpoint:MPTestFlightCheckpointIncrementPasswordCounter];
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
                                    ((MPElementGeneratedEntity *)self.activeElement).counter = 1;
                                }];

    [TestFlight passCheckpoint:MPTestFlightCheckpointResetPasswordCounter];
}

- (void)changeElementWithWarning:(NSString *)warning do:(void (^)(void))task; {

    [PearlAlert showAlertWithTitle:@"Password Change" message:warning viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [self changeElementWithoutWarningDo:task];
    } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
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
    }

    [TestFlight passCheckpoint:MPTestFlightCheckpointEditPassword];
}

- (IBAction)closeAlert {

    [UIView animateWithDuration:0.3f animations:^{
        self.alertContainer.alpha = 0;
    }                completion:^(BOOL finished) {
        if (finished)
            self.alertBody.text = nil;
    }];

    [TestFlight passCheckpoint:MPTestFlightCheckpointCloseAlert];
}

- (IBAction)action:(id)sender {

    [PearlSheet showSheetWithTitle:nil message:nil viewStyle:UIActionSheetStyleAutomatic
                 tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                     if (buttonIndex == [sheet cancelButtonIndex])
                         return;

                     switch (buttonIndex - [sheet firstOtherButtonIndex]) {
                         case 0: {
                             [self toggleHelpAnimated:YES];
                             break;
                         }
                         case 1: {
                             [self setHelpChapter:@"faq"];
                             [self setHelpHidden:NO animated:YES];
                             break;
                         }
                         case 2: {
                             [[MPAppDelegate get] showGuide];
                             break;
                         }
                         case 3: {
                             [self performSegueWithIdentifier:@"UserProfile" sender:self];
                             break;
                         }
#ifdef ADHOC
                         case 4: {
                             [TestFlight openFeedbackView];
                             break;
                         }
                         case 5:
#else
                         case 4: {
                             ATConnect *connection = [ATConnect sharedConnection];
                             [connection presentFeedbackControllerFromViewController:self];
                             break;
                         }
                         case 5:
#endif
                         {
                             [[MPAppDelegate get] forgetSavedKeyFor:[MPAppDelegate get].activeUser];
                             [[MPAppDelegate get] signOut];
                             break;
                         }
                     }

                     [TestFlight passCheckpoint:MPTestFlightCheckpointAction];
                 }
                 cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:nil otherTitles:
     [self isHelpVisible]? @"Hide Help": @"Show Help", @"FAQ", @"Tutorial", @"Preferences", @"Feedback", @"Sign Out", nil];
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

                                    [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointSelectType, NSStringFromMPElementType(
                                     type)]];

                                    if (type & MPElementTypeClassStored && ![[self.activeElement.content description] length])
                                        [self showContentTip:@"Tap        to set a password." withIcon:self.contentTipEditIcon];
                                }];
}

- (void)didSelectElement:(MPElementEntity *)element {

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

        if ([[MPiOSConfig get].firstRun boolValue])
            [UIView animateWithDuration:0.5f animations:^{
                self.typeTipContainer.alpha = 1;
            }                completion:^(BOOL finished) {
                if (finished) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.2f animations:^{
                            self.typeTipContainer.alpha = 0;
                        }];
                    });
                }
            }];

        [self.searchDisplayController setActive:NO animated:YES];
        self.searchDisplayController.searchBar.text = self.activeElement.name;

        [TestFlight passCheckpoint:MPTestFlightCheckpointSelectElement];
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationElementUsed object:self.activeElement];
    }

    [self updateAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.contentField)
        [self.contentField resignFirstResponder];

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
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [TestFlight passCheckpoint:MPTestFlightCheckpointExternalLink];

        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }

    return YES;
}

@end
