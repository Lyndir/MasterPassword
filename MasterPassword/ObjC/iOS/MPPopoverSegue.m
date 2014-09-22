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
//  MPPopoverSegue.h
//  MPPopoverSegue
//
//  Created by lhunath on 2014-04-09.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPopoverSegue.h"

@implementation MPPopoverSegue {
}

- (void)perform {

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;

    if ([sourceViewController parentViewController] != destinationViewController) {
        // Winding
        [sourceViewController addChildViewController:destinationViewController];
        [sourceViewController.view addSubview:destinationViewController.view];
        CGRectSetY( destinationViewController.view.bounds, sourceViewController.view.frame.size.height );
        [UIView transitionWithView:sourceViewController.view duration:0.3f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    CGRectSetY( destinationViewController.view.bounds, 0 );
                }       completion:^(BOOL finished) {
                    if (finished)
                        [destinationViewController didMoveToParentViewController:sourceViewController];
                }];
    }
    else {
        // Unwinding
        [sourceViewController willMoveToParentViewController:nil];
        [UIView transitionWithView:sourceViewController.parentViewController.view duration:0.3f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    CGRectSetY( sourceViewController.view.bounds, sourceViewController.parentViewController.view.frame.size.height );
                }       completion:^(BOOL finished) {
                    if (finished) {
                        [sourceViewController.view removeFromSuperview];
                        [sourceViewController removeFromParentViewController];
                    }
                }];
    }
}

@end
