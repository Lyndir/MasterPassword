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

#import <Foundation/Foundation.h>

@interface MPOverlayViewController : UIViewController
@end

@interface MPOverlaySegue : UIStoryboardSegue

+ (instancetype)dismissViewController:(UIViewController *)viewController;

@end
