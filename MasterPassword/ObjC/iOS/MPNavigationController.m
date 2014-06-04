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
//  MPNavigationController.h
//  MPNavigationController
//
//  Created by lhunath on 2014-06-03.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPNavigationController.h"
#import "MPWebViewController.h"

@implementation MPNavigationController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"web"])
        ((MPWebViewController *)segue.destinationViewController).initialURL = sender;
}

@end
