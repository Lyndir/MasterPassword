//
//  MPMacAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPAppDelegate_Shared.h"
#import "RHStatusItemView.h"
#import "MPPasswordWindowController.h"
#import "MPInitialWindowController.h"

@interface MPMacAppDelegate : MPAppDelegate_Shared<NSApplicationDelegate>

@property(nonatomic, strong) RHStatusItemView *statusView;
@property(nonatomic, strong) MPPasswordWindowController *passwordWindowController;
@property(nonatomic, strong) MPInitialWindowController *initialWindowController;
@property(nonatomic, weak) IBOutlet NSMenuItem *lockItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *showItem;
@property(nonatomic, strong) IBOutlet NSMenu *statusMenu;
@property(nonatomic, weak) IBOutlet NSMenuItem *useCloudItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *hidePasswordsItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *rememberPasswordItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *openAtLoginItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *savePasswordItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *createUserItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *deleteUserItem;
@property(nonatomic, weak) IBOutlet NSMenuItem *usersItem;

- (IBAction)showPasswordWindow:(id)sender;
- (void)setLoginItemEnabled:(BOOL)enabled;
- (IBAction)togglePreference:(id)sender;
- (IBAction)newUser:(NSMenuItem *)sender;
- (IBAction)lock:(id)sender;
- (IBAction)rebuildCloud:(id)sender;
- (IBAction)corruptCloud:(id)sender;
- (IBAction)terminate:(id)sender;
- (IBAction)showPopup:(id)sender;

@end
