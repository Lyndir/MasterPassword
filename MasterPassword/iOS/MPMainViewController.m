//
//  MPMainViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPMainViewController.h"
#import "MPAppDelegate_Key.h"
#import "MPElementGeneratedEntity.h"
#import "MPElementStoredEntity.h"
#import "IASKAppSettingsViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>


@interface MPMainViewController (Private)

- (void)updateAnimated:(BOOL)animated;
- (void)updateWasAnimated:(BOOL)animated;
- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)updateElement:(void (^)(void))updateElement;

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
@synthesize searchTipContainer = _searchTip;
@synthesize contentField = _contentField;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    [self setHelpHidden:![self isHelpVisible] animated:NO];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"MP_Main_ChooseType"])
        ((MPTypeViewController *)[segue destinationViewController]).delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.searchTipContainer.hidden = NO;
    
    if (!self.activeElement.name)
        [UIView animateWithDuration:animated? 0.2f: 0 animations:^{
            self.searchTipContainer.alpha = 1;
        }];
    
    [self setHelpHidden:[[MPiOSConfig get].helpHidden boolValue] animated:animated];
    [self updateAnimated:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    self.searchTipContainer.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];
    
    self.contentField.font = [UIFont fontWithName:@"Exo-Black" size:self.contentField.font.pointSize];
    
    // Put the search tip on the window so it's above the nav bar.
    if (![self.searchTipContainer.superview isEqual:self.navigationController.navigationBar.superview]) {
        CGRect frameInWindow = [self.searchTipContainer.window convertRect:self.searchTipContainer.frame
                                                                  fromView:self.searchTipContainer.superview];
        [self.searchTipContainer removeFromSuperview];
        [self.navigationController.navigationBar.superview addSubview:self.searchTipContainer];
        self.searchTipContainer.frame = [self.searchTipContainer.window convertRect:frameInWindow
                                                                             toView:self.searchTipContainer.superview];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      self.activeElement = nil;
                                                  }];
    
    self.alertBody.text = nil;
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
    [super viewDidUnload];
}

- (void)updateAnimated:(BOOL)animated {
    
    [[MPAppDelegate get] saveContext];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (animated)
            [UIView animateWithDuration:0.3f animations:^{
                [self updateWasAnimated:animated];
            }];
        else
            [self updateWasAnimated:animated];
    });
}

- (void)updateWasAnimated:(BOOL)animated {
    
    [self setHelpChapter:self.activeElement? @"2": @"1"];
    self.siteName.text = self.activeElement.name;
    
    self.passwordCounter.alpha = self.activeElement.type & MPElementTypeClassCalculated? 0.5f: 0;
    self.passwordIncrementer.alpha = self.activeElement.type & MPElementTypeClassCalculated? 0.5f: 0;
    self.passwordEdit.alpha = self.activeElement.type & MPElementTypeClassStored? 0.5f: 0;
    
    [self.typeButton setTitle:NSStringFromMPElementType(self.activeElement.type)
                     forState:UIControlStateNormal];
    self.typeButton.alpha = NSStringFromMPElementType(self.activeElement.type).length? 1: 0;
    
    self.contentField.enabled = NO;
    
    if ([self.activeElement isKindOfClass:[MPElementGeneratedEntity class]])
        self.passwordCounter.text = [NSString stringWithFormat:@"%u", ((MPElementGeneratedEntity *) self.activeElement).counter];
    
    self.contentField.text = @"";
    if (self.activeElement.name && ![self.activeElement isDeleted])
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            NSString *description = [self.activeElement description];
            
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
                self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, self.view.bounds.size.height - 44);
                self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, self.view.bounds.size.height);
                [MPiOSConfig get].helpHidden = [NSNumber numberWithBool:YES];
            } else {
                self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, 175);
                self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, 216);
                [MPiOSConfig get].helpHidden = [NSNumber numberWithBool:NO];
            }
        }];
    });
}

- (void)setHelpChapter:(NSString *)chapter {
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointHelpChapter, chapter]];
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.helpView loadRequest:
         [NSURLRequest requestWithURL:
          [NSURL URLWithString:[NSString stringWithFormat:@"#%@", chapter] relativeToURL:
           [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"]]]];
    });
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    NSString *error = [self.helpView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setClass('%@');",
                                                                             ClassNameFromMPElementType(self.activeElement.type)]];
    if (error.length)
        err(@"helpView.setClass: %@", error);
}

- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.contentTipBody.text = message;
        
        icon.hidden = NO;
        [UIView animateWithDuration:0.2f animations:^{
            self.contentTipContainer.alpha = 1;
        } completion:^(BOOL finished) {
            if (finished) {
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [UIView animateWithDuration:0.2f animations:^{
                        self.contentTipContainer.alpha = 0;
                    } completion:^(BOOL finished) {
                        if (finished)
                            icon.hidden = YES;
                    }];
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
        
        [UIView animateWithDuration:0.2f animations:^{
            self.alertContainer.alpha = 1;
        }];
    });
}

#pragma mark - Protocols

- (IBAction)copyContent {
    
    if (!self.activeElement)
        return;
    
    [[UIPasteboard generalPasteboard] setValue:self.activeElement.content
                             forPasteboardType:(id)kUTTypeUTF8PlainText];
    
    [self showContentTip:@"Copied!" withIcon:nil];
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointCopyToPasteboard];
#endif
}

- (IBAction)incrementPasswordCounter {
    
    if (![self.activeElement isKindOfClass:[MPElementGeneratedEntity class]])
        // Not of a type that supports a password counter;
        return;
    
    [self updateElement:^{
        ++((MPElementGeneratedEntity *) self.activeElement).counter;
    }];
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointIncrementPasswordCounter];
#endif
}

- (void)updateElement:(void (^)(void))updateElement {
    
    // Update password counter.
    NSString *oldPassword = self.activeElement.description;
    updateElement();
    NSString *newPassword = self.activeElement.description;
    [self updateAnimated:YES];
    
    // Show new and old password.
    if ([oldPassword length] && ![oldPassword isEqualToString:newPassword])
        [self showAlertWithTitle:@"Password Changed!" message:l(@"The password for %@ has changed.\n\n"
                                                                @"Don't forget to update the site with your new password! "
                                                                @"Your old password was:\n"
                                                                @"%@", self.activeElement.name, oldPassword)];
}

- (IBAction)editPassword {
    
    if (self.activeElement.type & MPElementTypeClassStored) {
        self.contentField.enabled = YES;
        [self.contentField becomeFirstResponder];
    }
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointEditPassword];
#endif
}

- (IBAction)closeAlert {
    
    [UIView animateWithDuration:0.3f animations:^{
        self.alertContainer.alpha = 0;
    } completion:^(BOOL finished) {
        if (finished)
            self.alertBody.text = nil;
    }];
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointCloseAlert];
#endif
}

- (IBAction)action:(id)sender {
    
    [PearlSheet showSheetWithTitle:nil message:nil viewStyle:UIActionSheetStyleAutomatic
                 tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                     if (buttonIndex == [sheet cancelButtonIndex])
                         return;
                     
                     switch (buttonIndex - [sheet firstOtherButtonIndex]) {
                         case 0:
                             [self toggleHelpAnimated:YES];
                             break;
                         case 1:
                             [self setHelpChapter:@"faq"];
                             [self setHelpHidden:NO animated:YES];
                             break;
                         case 2:
                             [[MPAppDelegate get] showGuide];
                             break;
                         case 3: {
                             IASKAppSettingsViewController *settingsVC = [IASKAppSettingsViewController new];
                             settingsVC.delegate = self;
                             [self.navigationController pushViewController:settingsVC animated:YES];
                             break;
                         }
#ifdef TESTFLIGHT
                         case 4:
                             [TestFlight openFeedbackView];
                             break;
                         case 5:
#else
                         case 4:
#endif
                         {
                             [[MPAppDelegate get] signOut];
                             [[MPAppDelegate get] loadKey:YES];
                             break;
                         }
                     }
                     
#ifdef TESTFLIGHT
                     [TestFlight passCheckpoint:MPTestFlightCheckpointAction];
#endif
                 } cancelTitle:[PearlStrings get].commonButtonCancel destructiveTitle:nil
                       otherTitles:
     [self isHelpVisible]? @"Hide Help": @"Show Help", @"FAQ", @"Tutorial", @"Settings",
#ifdef TESTFLIGHT
     @"Feedback",
#endif
     @"Sign Out",
     nil]; 
}

- (MPElementType)selectedType {
    
    return self.activeElement.type;
}

- (void)didSelectType:(MPElementType)type {
    
    [self updateElement:^{
        // Update password type.
        if (ClassFromMPElementType(type) != ClassFromMPElementType(self.activeElement.type))
            // Type requires a different class of element.  Recreate the element.
            [[MPAppDelegate managedObjectContext] performBlockAndWait:^{
                MPElementEntity *newElement = [NSEntityDescription insertNewObjectForEntityForName:ClassNameFromMPElementType(type)
                                                                            inManagedObjectContext:[MPAppDelegate managedObjectContext]];
                newElement.name = self.activeElement.name;
                newElement.mpHashHex = self.activeElement.mpHashHex;
                newElement.uses = self.activeElement.uses;
                newElement.lastUsed = self.activeElement.lastUsed;
                
                [[MPAppDelegate managedObjectContext] deleteObject:self.activeElement];
                self.activeElement = newElement;
            }];
        
        self.activeElement.type = type;
        
#ifdef TESTFLIGHT
        [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointSelectType, NSStringFromMPElementType(type)]];
#endif
        
        if (type & MPElementTypeClassStored && ![self.activeElement.description length])
            [self showContentTip:@"Tap        to set a password." withIcon:self.contentTipEditIcon];
    }];
}

- (void)didSelectElement:(MPElementEntity *)element {
    
    [self closeAlert];
    
    if (element) {
        self.activeElement = element;
        if ([self.activeElement use] == 1)
            [self showAlertWithTitle:@"New Site" message:
             l(@"You've just created a password for %@.\n\n"
               @"IMPORTANT:\n"
               @"Don't forget to set or change the password for your account at %@ to the password above. "
               @"It's best to do this right away. If you forget it, may get confusing later on "
               @"to remember what password you need to use for logging into the site.",
               self.activeElement.name, self.activeElement.name)];
        
        [self.searchDisplayController setActive:NO animated:YES];
        self.searchDisplayController.searchBar.text = self.activeElement.name;
        
#ifdef TESTFLIGHT
        [TestFlight passCheckpoint:MPTestFlightCheckpointSelectElement];
#endif
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
        
        if ([((MPElementStoredEntity *) self.activeElement).content isEqual:self.contentField.text])
            // Content hasn't changed.
            return;
        
        [self updateElement:^{
            ((MPElementStoredEntity *) self.activeElement).content = self.contentField.text;
        }];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
#ifdef TESTFLIGHT
        [TestFlight passCheckpoint:MPTestFlightCheckpointExternalLink];
#endif
        
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
    
    while ([self.navigationController.viewControllers containsObject:sender])
        [self.navigationController popViewControllerAnimated:YES];
}

@end
