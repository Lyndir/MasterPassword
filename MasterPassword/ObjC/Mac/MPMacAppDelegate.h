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

@interface MPMacAppDelegate : MPAppDelegate_Shared<NSApplicationDelegate>

@property(nonatomic, strong) RHStatusItemView *statusView;
@property(nonatomic, strong) MPPasswordWindowController *passwordWindow;
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
@property(nonatomic, weak) IBOutlet NSButton *openAtLoginButton;
@property(nonatomic, weak) IBOutlet NSButton *enableCloudButton;

- (IBAction)showPasswordWindow:(id)sender;
- (IBAction)togglePreference:(id)sender;
- (IBAction)newUser:(NSMenuItem *)sender;
- (IBAction)lock:(id)sender;
- (IBAction)rebuildCloud:(id)sender;
- (IBAction)corruptCloud:(id)sender;
- (IBAction)terminate:(id)sender;
- (IBAction)iphoneAppStore:(id)sender;
- (IBAction)showPopup:(id)sender;

@end
