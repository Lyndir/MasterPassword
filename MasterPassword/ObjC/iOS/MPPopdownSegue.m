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
//  MPPopdownSegue.h
//  MPPopdownSegue
//
//  Created by lhunath on 2014-04-17.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPopdownSegue.h"
#import "MPPasswordsViewController.h"

@implementation MPPopdownSegue {
}

- (void)perform {

    MPPasswordsViewController *passwordsVC;
    UIViewController *popdownVC;
    if ([self.sourceViewController isKindOfClass:[MPPasswordsViewController class]]) {
        passwordsVC = self.sourceViewController;
        popdownVC = self.destinationViewController;
        UIView *popdownView = popdownVC.view;
        popdownView.translatesAutoresizingMaskIntoConstraints = NO;

        [passwordsVC addChildViewController:popdownVC];
        [passwordsVC.popdownContainer addSubview:popdownView];
        [passwordsVC.popdownContainer addConstraintsWithVisualFormats:@[ @"H:|[popdownView]|", @"V:|[popdownView]|" ] options:0
                                                              metrics:nil views:NSDictionaryOfVariableBindings(popdownView)];

        [UIView animateWithDuration:0.3f animations:^{
            passwordsVC.popdownToTopConstraint.priority = 1;
            passwordsVC.popdownToNavigationBarConstraint.priority = UILayoutPriorityDefaultHigh;

            [passwordsVC.popdownToNavigationBarConstraint apply];
            [passwordsVC.popdownToTopConstraint apply];
        }                completion:^(BOOL finished) {
            if (finished)
                [popdownVC didMoveToParentViewController:passwordsVC];
        }];
    }
    else if ([self.destinationViewController isKindOfClass:[MPPasswordsViewController class]]) {
        popdownVC = self.sourceViewController;
        passwordsVC = self.destinationViewController;

        [popdownVC willMoveToParentViewController:nil];
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionOverrideInheritedDuration animations:^{
            passwordsVC.popdownToTopConstraint.priority = UILayoutPriorityDefaultHigh;
            passwordsVC.popdownToNavigationBarConstraint.priority = 1;

            [passwordsVC.popdownToNavigationBarConstraint apply];
            [passwordsVC.popdownToTopConstraint apply];
        }                completion:^(BOOL finished) {
            if (finished) {
                [popdownVC.view removeFromSuperview];
                [popdownVC removeFromParentViewController];
            }
        }];
    }
}

@end
