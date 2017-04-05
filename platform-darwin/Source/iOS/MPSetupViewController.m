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

#import "MPSetupViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPSetupViewController

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    if (self.rememberLoginSwitch)
        self.rememberLoginSwitch.on = [[MPiOSConfig get].rememberLogin boolValue];
    if (self.showPasswordsSwitch)
        self.showPasswordsSwitch.on = ![[MPiOSConfig get].hidePasswords boolValue];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    if (self.rememberLoginSwitch)
        [MPiOSConfig get].rememberLogin = @(self.rememberLoginSwitch.on);
    if (self.showPasswordsSwitch)
        [MPiOSConfig get].hidePasswords = @(!self.showPasswordsSwitch.on);
}

- (IBAction)close:(UIBarButtonItem *)sender {

    [MPiOSConfig get].showSetup = @NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
