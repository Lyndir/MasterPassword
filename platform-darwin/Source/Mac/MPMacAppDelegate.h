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

#import <Cocoa/Cocoa.h>
#import "MPAppDelegate_Shared.h"
#import "MPSitesWindowController.h"
#import "MPInitialWindowController.h"

@interface MPMacAppDelegate : MPAppDelegate_Shared<NSApplicationDelegate>

@property(nonatomic, strong) NSStatusItem *statusView;
@property(nonatomic, strong) MPSitesWindowController *sitesWindowController;
@property(nonatomic, strong) MPInitialWindowController *initialWindowController;
@property(nonatomic, weak) IBOutlet NSMenuItem *lockItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *showItem;
@property(nonatomic, strong) IBOutlet NSMenu *statusMenu;
@property(nonatomic, weak) IBOutlet NSMenuItem *hidePasswordsItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *rememberPasswordItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *openAtLoginItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *showFullScreenItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *savePasswordItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *createUserItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *deleteUserItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *usersItem;

- (IBAction)showPasswordWindow:(id)sender;
- (void)setLoginItemEnabled:(BOOL)enabled;
- (IBAction)togglePreference:(id)sender;
- (IBAction)newUser:(NSMenuItem *)sender;
- (IBAction)lock:(id)sender;
- (IBAction)terminate:(id)sender;
- (IBAction)showPopup:(id)sender;

@end
