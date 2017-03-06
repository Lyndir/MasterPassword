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

#import "MPInitialWindowController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPInitialWindowController

#pragma mark - Life

- (void)windowDidLoad {

    [super windowDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window
                                                       queue:nil usingBlock:^(NSNotification *note) {
        [MPMacAppDelegate get].initialWindowController = nil;
    }];
}

#pragma mark - Actions

- (IBAction)iphoneAppStore:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/id510296984"]];
    [self close];
}

- (IBAction)androidPlayStore:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://masterpasswordapp.com"]];
    [self close];
}

- (IBAction)togglePreference:(id)sender {

    if (sender == self.openAtLoginButton)
        [[MPMacAppDelegate get] setLoginItemEnabled:self.openAtLoginButton.state == NSOnState];
}

@end
