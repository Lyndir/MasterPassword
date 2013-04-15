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
//  MPElementListAllViewController
//
//  Created by Maarten Billemont on 2013-01-31.
//  Copyright 2013 lhunath (Maarten Billemont). All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPElementListController.h"

@interface MPElementListAllViewController : MPElementListController
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

- (IBAction)close:(id)sender;
- (IBAction)add:(id)sender;

@end
