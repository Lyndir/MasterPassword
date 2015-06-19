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
//  MPInitialWindowController.h
//  MPInitialWindowController
//
//  Created by lhunath on 2014-06-29.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface MPInitialWindowController : NSWindowController

@property(nonatomic, weak) IBOutlet NSButton *openAtLoginButton;

- (IBAction)iphoneAppStore:(id)sender;
- (IBAction)androidPlayStore:(id)sender;
- (IBAction)togglePreference:(id)sender;

@end
