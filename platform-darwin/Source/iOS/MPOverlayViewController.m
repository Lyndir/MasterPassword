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

#import "MPOverlayViewController.h"

@interface MPOverlayViewController()

@property(nonatomic, strong) NSMutableDictionary *dismissSegueByButton;

@end

@implementation MPOverlayViewController

- (void)awakeFromNib {

    [super awakeFromNib];

    self.dismissSegueByButton = [NSMutableDictionary dictionary];
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
    dismissButton.visible = NO;
    dismissButton.frame = self.view.bounds;
    dismissButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dismissSegueByButton[[NSValue valueWithNonretainedObject:dismissButton]] =
            [[MPOverlaySegue alloc] initWithIdentifier:@"dismiss-overlay"
                                                source:segue.destinationViewController destination:segue.sourceViewController];

    [self.view addSubview:dismissButton];
    return dismissButton;
}

- (void)dismissOverlay:(UIButton *)dismissButton {

    NSValue *dismissSegueKey = [NSValue valueWithNonretainedObject:dismissButton];
    [((UIStoryboardSegue *)self.dismissSegueByButton[dismissSegueKey]) perform];
}

- (void)removeDismissButtonForViewController:(UIViewController *)viewController {

    UIButton *dismissButton = nil;
    for (NSValue *dismissButtonValue in [self.dismissSegueByButton allKeys])
        if (((UIStoryboardSegue *)self.dismissSegueByButton[dismissButtonValue]).sourceViewController == viewController) {
            dismissButton = [dismissButtonValue nonretainedObjectValue];
            NSAssert( [self.view.subviews containsObject:dismissButton], @"Missing dismiss button in dictionary." );
        }
    if (!dismissButton)
        return;

    NSValue *dismissSegueKey = [NSValue valueWithNonretainedObject:dismissButton];
    [self.dismissSegueByButton removeObjectForKey:dismissSegueKey];

    [UIView animateWithDuration:0.1f animations:^{
        dismissButton.visible = NO;
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
        destinationViewController.view.visible = NO;

        [UIView transitionWithView:containerViewController.view duration:0.3f
                           options:UIViewAnimationOptionAllowAnimatedContent animations:^{
                    destinationViewController.view.transform = CGAffineTransformIdentity;
                    CGRectSetY( destinationViewController.view.frame, 0 );
                    destinationViewController.view.visible = YES;
                    dismissButton.visible = YES;
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
                    sourceViewController.view.visible = NO;
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
