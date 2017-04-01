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
//  MPRootSegue.h
//  MPRootSegue
//
//  Created by lhunath on 2014-09-26.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPRootSegue.h"

@implementation MPRootSegue {
}

- (void)perform {

    UIViewController *sourceViewController = self.sourceViewController;
    UIViewController *destinationViewController = self.destinationViewController;
    [sourceViewController addChildViewController:destinationViewController];
    destinationViewController.view.frame = sourceViewController.view.bounds;
    destinationViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [sourceViewController.view addSubview:destinationViewController.view];
    [destinationViewController didMoveToParentViewController:sourceViewController];
    [sourceViewController setNeedsStatusBarAppearanceUpdate];
}

@end
