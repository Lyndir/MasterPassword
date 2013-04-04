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

#import <Foundation/Foundation.h>


@interface MPAppsViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *pagePositionView;

- (IBAction)exit;

@end
