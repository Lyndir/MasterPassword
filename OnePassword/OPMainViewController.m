//
//  OPMainViewController.m
//  OnePassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPMainViewController.h"
#import "OPAppDelegate.h"
#import "OPContentViewController.h"
#import "OPElementGeneratedEntity.h"
#import "OPElementStoredEntity.h"

#import <MobileCoreServices/MobileCoreServices.h>


@interface OPMainViewController (Private)

- (void)updateAnimated:(BOOL)animated;
- (void)updateWasAnimated:(BOOL)animated;
- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)updateElement:(void (^)(void))updateElement;

@end

@implementation OPMainViewController
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"OP_Main_ChooseType"])
        [[segue destinationViewController] setDelegate:self];
    if ([[segue identifier] isEqualToString:@"OP_Main_Content"])
        ((OPContentViewController *)[segue destinationViewController]).activeElement = self.activeElement;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.searchTipContainer.hidden = NO;
    
    if (!self.activeElement.name)
        [UIView animateWithDuration:animated? 0.2f: 0 animations:^{
            self.searchTipContainer.alpha = 1;
        }];
    
    [self toggleHelp:[[OPConfig get].helpHidden boolValue]];
    [self updateAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];
    
    self.searchTipContainer.hidden = YES;
}

- (void)viewDidLoad {
    
    // Put the search tip on the window so it's above the nav bar.
//    [self.searchTipContainer removeFromSuperview];
//    [[UIApplication sharedApplication].keyWindow addSubview:self.searchTipContainer];
//    self.searchTipContainer.frame = CGRectSetY(self.searchTipContainer.frame, self.searchTipContainer.frame.origin.y
//                                               + self.navigationController.navigationBar.frame.size.height /* Nav */ + 20 /* Status */);
    self.searchTipContainer.hidden = YES;
    
    // Because IB's edit button doesn't auto-toggle self.editable like editButtonItem does.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if (![OPAppDelegate get].keyPhrase) {
                                                          self.activeElement = nil;
                                                          [self updateAnimated:NO];
                                                      }
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      if (![OPAppDelegate get].keyPhrase) {
                                                          self.activeElement = nil;
                                                          [self updateAnimated:NO];
                                                      }
                                                  }];
    
    [self closeAlert];
    
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    
    [self updateAnimated:animated];
}

- (void)updateAnimated:(BOOL)animated {
    
    [[OPAppDelegate get] saveContext];
    
    if (animated)
        [UIView animateWithDuration:0.2 animations:^{
            [self updateWasAnimated:YES];
        }];
    else
        [self updateWasAnimated:NO];
}

- (void)updateWasAnimated:(BOOL)animated {
    
    NSUInteger chapter = self.activeElement? 2: 1;
    [self.helpView loadRequest:
     [NSURLRequest requestWithURL:
      [NSURL URLWithString:[NSString stringWithFormat:@"#%d", chapter] relativeToURL:
       [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"]]]];
    [self.helpView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"setClass('%@');",
                                                           ClassNameFromOPElementType(self.activeElement.type)]];
    
    self.siteName.text = self.activeElement.name;
    
    self.passwordCounter.alpha = self.activeElement.type & OPElementTypeClassCalculated? 0.5f: 0;
    self.passwordIncrementer.alpha = self.activeElement.type & OPElementTypeClassCalculated? 0.5f: 0;
    self.passwordEdit.alpha = self.activeElement.type & OPElementTypeClassStored? 0.5f: 0;
    
    [self.typeButton setTitle:NSStringFromOPElementType(self.activeElement.type)
                     forState:UIControlStateNormal];
    self.typeButton.alpha = NSStringFromOPElementType(self.activeElement.type).length? 1: 0;
    
    self.contentField.enabled = NO;
    
    if ([self.activeElement isKindOfClass:[OPElementGeneratedEntity class]])
        self.passwordCounter.text = [NSString stringWithFormat:@"%d", ((OPElementGeneratedEntity *) self.activeElement).counter];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *description = self.activeElement.description;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentField.text = description;
        });
    });
}

- (void)showContentTip:(NSString *)message withIcon:(UIImageView *)icon {
    
    self.contentTipBody.text = message;
    
    icon.hidden = NO;
    [UIView animateWithDuration:0.2f animations:^{
        self.contentTipContainer.alpha = 1;
    } completion:^(BOOL finished) {
        if (!finished) {
            icon.hidden = YES;
            return;
        }
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 5.0f * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.2f animations:^{
                self.contentTipContainer.alpha = 0;
            } completion:^(BOOL finished) {
                icon.hidden = YES;
            }];
        });
    }];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    
    self.alertTitle.text = title;
    if ([self.alertBody.text length])
        self.alertBody.text = [NSString stringWithFormat:@"%@\n\n---\n\n%@", self.alertBody.text, message];
    else
        self.alertBody.text = message;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.alertContainer.alpha = 1;
    }];
}

#pragma mark - Protocols

- (IBAction)copyContent {
    
    if (!self.activeElement)
        return;
    
    [[UIPasteboard generalPasteboard] setValue:self.activeElement.content
                             forPasteboardType:(id)kUTTypeUTF8PlainText];
    
    [self showContentTip:@"Copied!" withIcon:nil];
}

- (IBAction)incrementPasswordCounter {
    
    if (![self.activeElement isKindOfClass:[OPElementGeneratedEntity class]])
        // Not of a type that supports a password counter;
        return;
    
    [self updateElement:^{
        ++((OPElementGeneratedEntity *) self.activeElement).counter;
    }];
}

- (void)updateElement:(void (^)(void))updateElement {
    
    // Update password counter.
    NSString *oldPassword = self.activeElement.description;
    updateElement();
    NSString *newPassword = self.activeElement.description;
    [self updateAnimated:YES];
    
    // Show new and old password.
    if (oldPassword && ![oldPassword isEqualToString:newPassword])
        [self showAlertWithTitle:@"Password Changed!" message:l(@"The password for %@ has changed.\n\n"
                                                                @"Don't forget to update the site with your new password! "
                                                                @"Your old password was:\n"
                                                                @"%@", self.activeElement.name, oldPassword)];
}

- (IBAction)editPassword {
    
    if (self.activeElement.type & OPElementTypeClassStored) {
        self.contentField.enabled = YES;
        [self.contentField becomeFirstResponder];
    }
}

- (IBAction)toggleHelp {
    
    [UIView animateWithDuration:0.3f animations:^{
        if (self.helpContainer.frame.origin.y < 400)
            [self toggleHelp:YES];
        else
            [self toggleHelp:NO];
    }];
}

- (void)toggleHelp:(BOOL)hidden {
    
    if (hidden) {
        self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, 373);
        self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, 415);
        [OPConfig get].helpHidden = [NSNumber numberWithBool:YES];
    } else {
        self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, 175);
        self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, 216);
        [OPConfig get].helpHidden = [NSNumber numberWithBool:NO];
    }
}

- (IBAction)closeAlert {
    
    [UIView animateWithDuration:0.3f animations:^{
        self.alertContainer.alpha = 0;
    } completion:^(BOOL finished) {
        self.alertBody.text = nil;
    }];
}

- (void)didSelectType:(OPElementType)type {
    
    [self updateElement:^{
        // Update password type.
        if (ClassFromOPElementType(type) != ClassFromOPElementType(self.activeElement.type)) {
            // Type requires a different class of element.  Recreate the element.
            OPElementEntity *newElement = [NSEntityDescription insertNewObjectForEntityForName:ClassNameFromOPElementType(type)
                                                                        inManagedObjectContext:[OPAppDelegate managedObjectContext]];
            newElement.name = self.activeElement.name;
            newElement.mpHashHex = self.activeElement.mpHashHex;
            newElement.uses = self.activeElement.uses;
            newElement.lastUsed = self.activeElement.lastUsed;
            
            [[OPAppDelegate managedObjectContext] deleteObject:self.activeElement];
            self.activeElement = newElement;
        }
        
        self.activeElement.type = type;
        
        if (type & OPElementTypeClassStored && ![self.activeElement.description length])
            [self showContentTip:@"Tap       to set a password." withIcon:self.contentTipEditIcon];
    }];
}

- (void)didSelectElement:(OPElementEntity *)element {
    
    self.activeElement = element;
    [self.activeElement use];
    
    [self.searchDisplayController setActive:NO animated:YES];
    self.searchDisplayController.searchBar.text = self.activeElement.name;
    
    [self updateAnimated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
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
        if (![self.activeElement isKindOfClass:[OPElementStoredEntity class]])
            // Not of a type whose content can be edited.
            return;
        
        if ([((OPElementStoredEntity *) self.activeElement).contentObject isEqual:self.contentField.text])
            // Content hasn't changed.
            return;
        
        [self updateElement:^{
            ((OPElementStoredEntity *) self.activeElement).contentObject = self.contentField.text;
        }];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [[UIApplication sharedApplication] openURL:[request URL]];
        return NO;
    }
    
    return YES;
}

@end
