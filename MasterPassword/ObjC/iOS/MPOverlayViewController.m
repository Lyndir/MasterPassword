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
//  MPOverlayViewController.h
//  MPOverlayViewController
//
//  Created by lhunath on 2014-09-22.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPOverlayViewController.h"


@implementation MPOverlayViewController

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    if (![self.childViewControllers count])
        [self performSegueWithIdentifier:@"root" sender:self];
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController
                                      fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {

    return [[MPOverlaySegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
}

@end

@implementation MPOverlaySegue

- (void)perform {

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    MPOverlayViewController *containerViewController = self.sourceViewController;
    while (![containerViewController isKindOfClass:[MPOverlayViewController class]])
        containerViewController = (id)containerViewController.parentViewController;
    NSAssert( [containerViewController isKindOfClass:[MPOverlayViewController class]],
            @"Not an overlay container: %@", containerViewController );

    if (!destinationViewController.parentViewController) {
        // Winding
        [containerViewController addChildViewController:destinationViewController];
        [containerViewController.view addSubview:destinationViewController.view];
        CGRectSetY( destinationViewController.view.frame, containerViewController.view.frame.size.height );
        [UIView transitionWithView:containerViewController.view duration:0.3f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    CGRectSetY( destinationViewController.view.frame, 0 );
                }       completion:^(BOOL finished) {
                    if (finished)
                        [destinationViewController didMoveToParentViewController:containerViewController];
                }];
    }
    else {
        // Unwinding
        [sourceViewController willMoveToParentViewController:nil];
        [UIView transitionWithView:containerViewController.view duration:0.3f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    CGRectSetY( sourceViewController.view.bounds, containerViewController.view.frame.size.height );
                }       completion:^(BOOL finished) {
                    if (finished) {
                        [sourceViewController.view removeFromSuperview];
                        [sourceViewController removeFromParentViewController];
                    }
                }];
    }
}

@end
