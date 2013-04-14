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
//  MPSetupViewController.h
//  MPSetupViewController
//
//  Created by lhunath on 2013-04-11.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPSetupViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISwitch *cloudSwitch;

- (IBAction)close:(UIBarButtonItem *)sender;

@end
