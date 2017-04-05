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

@implementation MPEmergencyViewController {
    MPKey *_key;
    NSOperationQueue *_emergencyKeyQueue;
    NSOperationQueue *_emergencyPasswordQueue;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [_emergencyKeyQueue = [NSOperationQueue new] setMaxConcurrentOperationCount:1];
    [_emergencyPasswordQueue = [NSOperationQueue new] setMaxConcurrentOperationCount:1];

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

- (IBAction)copyPassword:(UITapGestureRecognizer *)recognizer {

    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSString *sitePassword = self.passwordLabel.text;
        if ([sitePassword length]) {
            [UIPasteboard generalPasteboard].string = sitePassword;
            [UIView animateWithDuration:0.3f animations:^{
                self.tipContainer.alpha = 1;
            }                completion:^(BOOL finished) {
                if (finished)
                    PearlMainQueueAfter( 3, ^{
                        self.tipContainer.alpha = 0;
                    } );
            }];
        }
    }
}

#pragma mark - Private

- (void)updateKey {

    NSString *fullName = self.fullNameField.text;
    NSString *masterPassword = self.masterPasswordField.text;

    self.passwordLabel.text = nil;
    [self.activity startAnimating];
    [_emergencyKeyQueue cancelAllOperations];
    [_emergencyKeyQueue addOperationWithBlock:^{
        if ([masterPassword length] && [fullName length])
            _key = [[MPKey alloc] initForFullName:fullName withMasterPassword:masterPassword];
        else
            _key = nil;

        PearlMainQueue( ^{
            [self updatePassword];
        } );
    }];
}

- (void)updatePassword {

    NSString *siteName = self.siteField.text;
    MPSiteType siteType = [self siteType];
    NSUInteger siteCounter = (NSUInteger)self.counterStepper.value;
    self.counterLabel.text = strf( @"%lu", (unsigned long)siteCounter );

    self.passwordLabel.text = nil;
    [self.activity startAnimating];
    [_emergencyPasswordQueue cancelAllOperations];
    [_emergencyPasswordQueue addOperationWithBlock:^{
        NSString *sitePassword = nil;
        if (_key && [siteName length])
            sitePassword = [MPAlgorithmDefault generatePasswordForSiteNamed:siteName ofType:siteType withCounter:siteCounter usingKey:_key];

        PearlMainQueue( ^{
            [self.activity stopAnimating];
            self.passwordLabel.text = sitePassword;
        } );
    }];
}

- (enum MPSiteType)siteType {

    switch (self.typeControl.selectedSegmentIndex) {
        case 0:
            return MPSiteTypeGeneratedMaximum;
        case 1:
            return MPSiteTypeGeneratedLong;
        case 2:
            return MPSiteTypeGeneratedMedium;
        case 3:
            return MPSiteTypeGeneratedBasic;
        case 4:
            return MPSiteTypeGeneratedShort;
        case 5:
            return MPSiteTypeGeneratedPIN;
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
