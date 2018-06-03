//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPInitialWindowController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPInitialWindowController

#pragma mark - Life

- (void)windowDidLoad {

    [super windowDidLoad];

    PearlAddNotificationObserver( NSWindowWillCloseNotification, self.window, nil, ^(id host, NSNotification *note) {
        PearlRemoveNotificationObserversFrom( host );
        [MPMacAppDelegate get].initialWindowController = nil;
    } );
}

#pragma mark - Actions

- (IBAction)iphoneAppStore:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/id510296984"]];
    [self close];
}

- (IBAction)androidPlayStore:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://masterpassword.app"]];
    [self close];
}

- (IBAction)togglePreference:(id)sender {

    if (sender == self.openAtLoginButton)
        [[MPMacAppDelegate get] setLoginItemEnabled:self.openAtLoginButton.state == NSOnState];
}

@end
