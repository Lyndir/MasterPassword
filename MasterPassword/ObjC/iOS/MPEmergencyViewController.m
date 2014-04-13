/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  MPCombinedViewController.h
//  MPCombinedViewController
//
//  Created by lhunath on 2014-03-08.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

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
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];

    [self reset];
}

- (BOOL)canPerformUnwindSegueAction:(SEL)action fromViewController:(UIViewController *)fromViewController withSender:(id)sender {

    return [self respondsToSelector:action];
}

#pragma mark - Actions

- (IBAction)unwindToCombined:(UIStoryboardSegue *)sender {

    dbg(@"unwindToCombined:%@", sender);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Actions

- (IBAction)controlChanged:(UIControl *)control {

    if (control == self.userNameField || control == self.masterPasswordField)
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

    NSString *userName = self.userNameField.text;
    NSString *masterPassword = self.masterPasswordField.text;

    self.passwordLabel.text = nil;
    [self.activity startAnimating];
    [_emergencyKeyQueue cancelAllOperations];
    [_emergencyKeyQueue addOperationWithBlock:^{
        if ([masterPassword length] && [userName length])
            _key = [MPAlgorithmDefault keyForPassword:masterPassword ofUserNamed:userName];
        else
            _key = nil;

        PearlMainQueue( ^{
            [self updatePassword];
        } );
    }];
}

- (void)updatePassword {

    NSString *siteName = self.siteField.text;
    MPElementType siteType = [self siteType];
    NSUInteger siteCounter = (NSUInteger)self.counterStepper.value;
    self.counterLabel.text = strf( @"%d", siteCounter );

    self.passwordLabel.text = nil;
    [self.activity startAnimating];
    [_emergencyPasswordQueue cancelAllOperations];
    [_emergencyPasswordQueue addOperationWithBlock:^{
        NSString *sitePassword = nil;
        if (_key && [siteName length])
            sitePassword = [MPAlgorithmDefault generateContentNamed:siteName ofType:siteType withCounter:siteCounter usingKey:_key];

        PearlMainQueue( ^{
            [self.activity stopAnimating];
            self.passwordLabel.text = sitePassword;
        } );
    }];
}

- (enum MPElementType)siteType {

    switch (self.typeControl.selectedSegmentIndex) {
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
            Throw(@"Unsupported type index: %ld", (long)self.typeControl.selectedSegmentIndex);
    }
}

- (void)reset {

    self.userNameField.text = nil;
    self.masterPasswordField.text = nil;
    self.siteField.text = nil;
    self.counterStepper.value = 1;
    self.typeControl.selectedSegmentIndex = 1;
    [self updateKey];
}

@end
