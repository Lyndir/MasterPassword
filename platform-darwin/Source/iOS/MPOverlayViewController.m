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

@implementation MPOverlayViewController {
    NSMutableDictionary *_dismissSegueByButton;
}

- (void)awakeFromNib {

    [super awakeFromNib];

    _dismissSegueByButton = [NSMutableDictionary dictionary];
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [self performSegueWithIdentifier:@"root" sender:self];
}

- (UIViewController *)childViewControllerForStatusBarStyle {

    return [self.childViewControllers lastObject];
}

- (UIViewController *)childViewControllerForStatusBarHidden {

    return self.childViewControllerForStatusBarStyle;
}

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController
                                      fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {

    return [[MPOverlaySegue alloc] initWithIdentifier:identifier source:fromViewController destination:toViewController];
}

- (UIView *)addDismissButtonForSegue:(MPOverlaySegue *)segue {

    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [dismissButton addTarget:self action:@selector( dismissOverlay: ) forControlEvents:UIControlEventTouchUpInside];
    dismissButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5f];
    dismissButton.alpha = 0;
    dismissButton.frame = self.view.bounds;
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _dismissSegueByButton[[NSValue valueWithNonretainedObject:dismissButton]] =
            [[MPOverlaySegue alloc] initWithIdentifier:@"dismiss-overlay"
                                                source:segue.destinationViewController destination:segue.sourceViewController];

    [self.view addSubview:dismissButton];
    return dismissButton;
}

- (void)dismissOverlay:(UIButton *)dismissButton {

    NSValue *dismissSegueKey = [NSValue valueWithNonretainedObject:dismissButton];
    [((UIStoryboardSegue *)_dismissSegueByButton[dismissSegueKey]) perform];
}

- (void)removeDismissButtonForViewController:(UIViewController *)viewController {

    UIButton *dismissButton = nil;
    for (NSValue *dismissButtonValue in [_dismissSegueByButton allKeys])
        if (((UIStoryboardSegue *)_dismissSegueByButton[dismissButtonValue]).sourceViewController == viewController) {
            dismissButton = [dismissButtonValue nonretainedObjectValue];
            NSAssert([self.view.subviews containsObject:dismissButton], @"Missing dismiss button in dictionary.");
        }
    if (!dismissButton)
        return;

    NSValue *dismissSegueKey = [NSValue valueWithNonretainedObject:dismissButton];
    [_dismissSegueByButton removeObjectForKey:dismissSegueKey];

    [UIView animateWithDuration:0.1f animations:^{
        dismissButton.alpha = 0;
    }                completion:^(BOOL finished) {
        [dismissButton removeFromSuperview];
    }];
}

@end

@implementation MPOverlaySegue

+ (instancetype)dismissViewController:(UIViewController *)viewController {

    return [[self alloc] initWithIdentifier:nil source:viewController destination:viewController];
}

- (void)perform {

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    MPOverlayViewController *containerViewController = self.sourceViewController;
    while (containerViewController && ![(id)containerViewController isKindOfClass:[MPOverlayViewController class]])
        containerViewController = (id)containerViewController.parentViewController;
    NSAssert( [containerViewController isKindOfClass:[MPOverlayViewController class]],
            @"Not an overlay container: %@", containerViewController );

    if (!destinationViewController.parentViewController) {
        // Winding
        [containerViewController addChildViewController:destinationViewController];
        UIView *dismissButton = [containerViewController addDismissButtonForSegue:self];

        destinationViewController.view.frame = containerViewController.view.bounds;
        destinationViewController.view.translatesAutoresizingMaskIntoConstraints = YES;
        destinationViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [containerViewController.view addSubview:destinationViewController.view];
        [containerViewController setNeedsStatusBarAppearanceUpdate];

        CGRectSetY( destinationViewController.view.frame, 100 );
        destinationViewController.view.transform = CGAffineTransformMakeScale( 1.2f, 1.2f );
        destinationViewController.view.alpha = 0;

        [UIView transitionWithView:containerViewController.view duration:0.3f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    destinationViewController.view.transform = CGAffineTransformIdentity;
                    CGRectSetY( destinationViewController.view.frame, 0 );
                    destinationViewController.view.alpha = 1;
                    dismissButton.alpha = 1;
                }       completion:^(BOOL finished) {
                    [destinationViewController didMoveToParentViewController:containerViewController];
                    [containerViewController setNeedsStatusBarAppearanceUpdate];
                }];
    }
    else {
        // Unwinding
        [sourceViewController willMoveToParentViewController:nil];
        [UIView transitionWithView:containerViewController.view duration:0.2f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    CGRectSetY( sourceViewController.view.frame, 100 );
                    sourceViewController.view.transform = CGAffineTransformMakeScale( 0.8f, 0.8f );
                    sourceViewController.view.alpha = 0;
                    [containerViewController removeDismissButtonForViewController:sourceViewController];
                }       completion:^(BOOL finished) {
                    if (finished) {
                        [sourceViewController.view removeFromSuperview];
                        [sourceViewController removeFromParentViewController];
                        [containerViewController setNeedsStatusBarAppearanceUpdate];
                    }
                }];
    }
}

@end
