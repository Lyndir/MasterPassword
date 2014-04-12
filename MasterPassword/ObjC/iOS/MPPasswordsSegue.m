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
//  MPPasswordsSegue.h
//  MPPasswordsSegue
//
//  Created by lhunath on 2014-04-12.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordsSegue.h"
#import "MPPasswordsViewController.h"

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

        [self.sourceViewController addChildViewController:passwordsVC];
        [[passwordsVC.parentViewController view] addSubview:passwordsVC.view];
        passwordsVC.active = NO;
        [passwordsVC setActive:YES animated:self.animated completion:^(BOOL finished) {
            if (!finished)
                return;

            [passwordsVC didMoveToParentViewController:passwordsVC.parentViewController];
        }];
    } else if ([self.sourceViewController isKindOfClass:[MPPasswordsViewController class]]) {
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
