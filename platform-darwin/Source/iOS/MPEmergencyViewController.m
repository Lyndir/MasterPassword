//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPEmergencyViewController.h"
#import "MPEntities.h"

@interface MPEmergencyViewController()

@property(nonatomic, strong) MPKey *key;
@property(nonatomic, strong) NSOperationQueue *emergencyKeyQueue;
@property(nonatomic, strong) NSOperationQueue *emergencyPasswordQueue;

@end

@implementation MPEmergencyViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    [self.emergencyKeyQueue = [NSOperationQueue new] setMaxConcurrentOperationCount:1];
    [self.emergencyPasswordQueue = [NSOperationQueue new] setMaxConcurrentOperationCount:1];

    self.view.backgroundColor = [UIColor clearColor];
    self.dialogView.layer.cornerRadius = 5;
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self reset];
    PearlAddNotificationObserver( UIApplicationWillResignActiveNotification, nil, [NSOperationQueue mainQueue],
            ^(MPEmergencyViewController *self, NSNotification *note) {
                [self performSegueWithIdentifier:@"unwind-popover" sender:self];
            } );

    [self.scrollView automaticallyAdjustInsetsForKeyboard];
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];

    PearlRemoveNotificationObservers();
    PearlRemoveNotificationObserversFrom( self.scrollView );
    [self reset];
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (IBAction)controlChanged:(UIControl *)control {

    if (control == self.fullNameField || control == self.masterPasswordField)
        [self updateKey];
    else
        [self updatePassword];
}

- (IBAction)copyPassword:(id)sender {

    NSString *sitePassword = [self.passwordButton titleForState:UIControlStateNormal];
    if (![sitePassword length])
        return;

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (@available(iOS 10.0, *))
        [pasteboard setItems:@[ @{ UIPasteboardTypeAutomatic: sitePassword } ]
                     options:@{
                             UIPasteboardOptionLocalOnly     : @NO,
                             UIPasteboardOptionExpirationDate: [NSDate dateWithTimeIntervalSinceNow:3 * 60]
                     }];
    else
        pasteboard.string = sitePassword;

    [UIView animateWithDuration:0.3f animations:^{
        self.tipContainer.visible = YES;
    }                completion:^(BOOL finished) {
        PearlMainQueueAfter( 3, ^{
            [UIView animateWithDuration:0.3f animations:^{
                self.tipContainer.visible = NO;
            }];
        } );
    }];
}

#pragma mark - Private

- (void)updateKey {

    NSString *fullName = self.fullNameField.text;
    NSString *masterPassword = self.masterPasswordField.text;

    [self.passwordButton setTitle:nil forState:UIControlStateNormal];
    [self.activity startAnimating];
    [self.emergencyKeyQueue cancelAllOperations];
    [self.emergencyKeyQueue addOperationWithBlock:^{
        if ([masterPassword length] && [fullName length])
            self.key = [[MPKey alloc] initForFullName:fullName withMasterPassword:masterPassword];
        else
            self.key = nil;

        PearlMainQueue( ^{
            [self updatePassword];
        } );
    }];
}

- (void)updatePassword {

    NSString *siteName = self.siteField.text;
    MPResultType siteType = [self siteType];
    MPCounterValue siteCounter = (MPCounterValue)self.counterStepper.value;
    self.counterLabel.text = strf( @"%u", siteCounter );

    [self.passwordButton setTitle:nil forState:UIControlStateNormal];
    [self.activity startAnimating];
    [self.emergencyPasswordQueue cancelAllOperations];
    [self.emergencyPasswordQueue addOperationWithBlock:^{
        NSString *sitePassword = nil;
        if (self.key && [siteName length])
            sitePassword = [MPAlgorithmDefault mpwTemplateForSiteNamed:siteName ofType:siteType withCounter:siteCounter
                                                              usingKey:self.key];

        PearlMainQueue( ^{
            [self.activity stopAnimating];
            [self.passwordButton setTitle:sitePassword forState:UIControlStateNormal];
        } );
    }];
}

- (MPResultType)siteType {

    switch (self.typeControl.selectedSegmentIndex) {
        case 0:
            return MPResultTypeTemplateMaximum;
        case 1:
            return MPResultTypeTemplateLong;
        case 2:
            return MPResultTypeTemplateMedium;
        case 3:
            return MPResultTypeTemplateBasic;
        case 4:
            return MPResultTypeTemplateShort;
        case 5:
            return MPResultTypeTemplatePIN;
        default:
            Throw( @"Unsupported type index: %ld", (long)self.typeControl.selectedSegmentIndex );
    }
}

- (void)reset {

    self.fullNameField.text = nil;
    self.masterPasswordField.text = nil;
    self.siteField.text = nil;
    self.counterStepper.value = 1;
    self.typeControl.selectedSegmentIndex = 1;
    [self updateKey];
}

@end
