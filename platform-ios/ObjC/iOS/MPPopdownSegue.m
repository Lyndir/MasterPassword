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

static char UnwindingObserverKey;

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
                                                              metrics:nil views:NSDictionaryOfVariableBindings( popdownView )];

        [UIView animateWithDuration:0.3f animations:^{
            [[passwordsVC.popdownToTopConstraint updatePriority:1] layoutIfNeeded];
        }                completion:^(BOOL finished) {
            [popdownVC didMoveToParentViewController:passwordsVC];

            id<NSObject> observer = [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedOutNotification object:nil
                                                                                       queue:[NSOperationQueue mainQueue] usingBlock:
                            ^(NSNotification *note) {
                                [[[MPPopdownSegue alloc] initWithIdentifier:@"unwind-popdown" source:popdownVC
                                                                destination:passwordsVC] perform];
                            }];
            objc_setAssociatedObject( popdownVC, &UnwindingObserverKey, observer, OBJC_ASSOCIATION_RETAIN );
        }];
    }
    else {
        popdownVC = self.sourceViewController;
        for (passwordsVC = self.sourceViewController; passwordsVC && ![(id)passwordsVC isKindOfClass:[MPPasswordsViewController class]];
             passwordsVC = (id)passwordsVC.parentViewController);
        NSAssert( passwordsVC, @"Couldn't find passwords VC to pop back to." );

        [[NSNotificationCenter defaultCenter] removeObserver:objc_getAssociatedObject( popdownVC, &UnwindingObserverKey )];
        objc_setAssociatedObject( popdownVC, &UnwindingObserverKey, nil, OBJC_ASSOCIATION_RETAIN );

        [popdownVC willMoveToParentViewController:nil];
        [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionOverrideInheritedDuration animations:^{
            [[passwordsVC.popdownToTopConstraint updatePriority:UILayoutPriorityDefaultHigh] layoutIfNeeded];
        }                completion:^(BOOL finished) {
            [popdownVC.view removeFromSuperview];
            [popdownVC removeFromParentViewController];
        }];
    }
}

@end
