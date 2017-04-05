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

#import "MPPasswordsSegue.h"
#import "MPPasswordsViewController.h"
#import "MPCombinedViewController.h"

@implementation MPPasswordsSegue {
}

- (id)initWithIdentifier:(NSString *)identifier source:(UIViewController *)source destination:(UIViewController *)destination {

    if (!(self = [super initWithIdentifier:identifier source:source destination:destination]))
        return nil;

    self.animated = YES;

    return self;
}

- (void)perform {

    if ([self.destinationViewController isKindOfClass:[MPPasswordsViewController class]]) {
        __weak MPPasswordsViewController *passwordsVC = self.destinationViewController;
        MPCombinedViewController *combinedVC = self.sourceViewController;
        [combinedVC addChildViewController:passwordsVC];
        passwordsVC.active = NO;

        UIView *passwordsView = passwordsVC.view;
        passwordsView.frame = combinedVC.view.bounds;
        passwordsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [combinedVC.view insertSubview:passwordsView belowSubview:combinedVC.usersVC.view];

        [passwordsVC setActive:YES animated:self.animated completion:^(BOOL finished) {
            if (!finished)
                return;

            [passwordsVC didMoveToParentViewController:combinedVC];
        }];
    }
    else if ([self.sourceViewController isKindOfClass:[MPPasswordsViewController class]]) {
        __weak MPPasswordsViewController *passwordsVC = self.sourceViewController;

        [passwordsVC willMoveToParentViewController:nil];
        [passwordsVC setActive:NO animated:self.animated completion:^(BOOL finished) {
            if (!finished)
                return;

            [passwordsVC.view removeFromSuperview];
            [passwordsVC removeFromParentViewController];
        }];
    }
}

@end
