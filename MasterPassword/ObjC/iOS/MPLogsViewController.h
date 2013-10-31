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
//  MPLogsViewController.h
//  MPLogsViewController
//
//  Created by lhunath on 2013-04-29.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPLogsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *logView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *levelControl;

- (IBAction)action:(id)sender;
- (IBAction)toggleLevelControl:(UISegmentedControl *)sender;
- (IBAction)refresh:(UIBarButtonItem *)sender;
- (IBAction)mail:(UIBarButtonItem *)sender;
@end
