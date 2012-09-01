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
//  MPAppsViewController
//
//  Created by Maarten Billemont on 2012-08-31.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAppsViewController.h"
#import "LocalyticsSession.h"


@interface MPAppsViewController ()

@property (nonatomic, strong) NSMutableArray       *pageVCs;
@property (nonatomic, strong) UIPageViewController *pageViewController;


@end

@implementation MPAppsViewController {

}
@synthesize pagePositionView = _pagePositionView;
@synthesize pageVCs = _pageVCs;
@synthesize pageViewController = _pageViewController;


- (void)viewDidLoad {

    self.pageVCs = [NSMutableArray array];
    UIViewController *vc;
    @try {
        for (NSUInteger p = 0;
             (vc = [self.storyboard instantiateViewControllerWithIdentifier:PearlString(@"MPAppViewController_%u", p)]);
             ++p)
            [self.pageVCs addObject:vc];
    }
    @catch (NSException *e) {
        if (![e.name isEqualToString:NSInvalidArgumentException])
            [e raise];
    }

    self.pageViewController            = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl
                                                                         navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                       options:nil];
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate   = self;
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    self.pageViewController.view.frame = self.pagePositionView.frame;
    [self.pagePositionView removeFromSuperview];
    [self.pageViewController didMoveToParentViewController:self];

    [self.pageViewController setViewControllers:@[[self.pageVCs objectAtIndex:0]] direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO completion:nil];

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    [TestFlight passCheckpoint:MPCheckpointApps];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointApps attributes:nil];

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    [super viewWillDisappear:animated];
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {

    NSUInteger vcIndex = [self.pageVCs indexOfObject:viewController];
    return [self.pageVCs objectAtIndex:(vcIndex + [self.pageVCs count] - 1) % self.pageVCs.count];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {

    NSUInteger vcIndex = [self.pageVCs indexOfObject:viewController];
    return [self.pageVCs objectAtIndex:(vcIndex + 1) % self.pageVCs.count];
}

- (void)viewDidUnload {

    [self setPagePositionView:nil];
    [super viewDidUnload];
}

- (IBAction)exit {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
