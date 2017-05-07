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

#import "MPPopdownSegue.h"
#import "MPSitesViewController.h"

@implementation MPPopdownSegue

- (void)perform {

    MPSitesViewController *passwordsVC;
    UIViewController *popdownVC;
    if ([self.sourceViewController isKindOfClass:[MPSitesViewController class]]) {
        passwordsVC = self.sourceViewController;
        popdownVC = self.destinationViewController;
        UIView *popdownView = popdownVC.view;
        popdownView.translatesAutoresizingMaskIntoConstraints = NO;

        [passwordsVC addChildViewController:popdownVC];
        [passwordsVC.popdownContainer addSubview:popdownView];
        [passwordsVC.popdownContainer addConstraintsWithVisualFormats:@[ @"H:|[popdownView]|", @"V:|[popdownView]|" ] options:0
                                                              metrics:nil views:NSDictionaryOfVariableBindings( popdownView )];

        [passwordsVC.popdownToTopConstraint layoutIfNeeded];
        [passwordsVC.view endEditing:YES];

        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:1
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [[passwordsVC.popdownToTopConstraint updatePriority:1] layoutIfNeeded];
                }        completion:^(BOOL finished) {
                    [popdownVC didMoveToParentViewController:passwordsVC];

                    PearlAddNotificationObserverTo( popdownVC, MPSignedOutNotification, nil, [NSOperationQueue mainQueue],
                            ^(id host, NSNotification *note) {
                                [[[MPPopdownSegue alloc] initWithIdentifier:@"unwind-popdown" source:popdownVC destination:passwordsVC]
                                        perform];
                            } );
                }];
    }
    else {
        popdownVC = self.sourceViewController;
        for (passwordsVC = self.sourceViewController; passwordsVC && ![(id)passwordsVC isKindOfClass:[MPSitesViewController class]];
             passwordsVC = (id)passwordsVC.parentViewController);
        NSAssert( passwordsVC, @"Couldn't find passwords VC to pop back to." );

        PearlRemoveNotificationObserversFrom( popdownVC );

        [popdownVC willMoveToParentViewController:nil];
        [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionOverrideInheritedDuration
                         animations:^{
                             [[passwordsVC.popdownToTopConstraint updatePriority:UILayoutPriorityDefaultHigh] layoutIfNeeded];
                         } completion:^(BOOL finished) {
                    [popdownVC.view removeFromSuperview];
                    [popdownVC removeFromParentViewController];
                }];
    }
}

@end
