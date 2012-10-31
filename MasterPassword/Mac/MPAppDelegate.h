//
//  MPAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPAppDelegate_Shared.h"
#import "MPPasswordWindowController.h"

@interface MPAppDelegate : MPAppDelegate_Shared<NSApplicationDelegate>

@property (nonatomic, strong) NSStatusItem               *statusItem;
@property (nonatomic, strong) MPPasswordWindowController *passwordWindow;
@property (nonatomic, weak) IBOutlet NSMenuItem          *lockItem;
@property (nonatomic, weak) IBOutlet NSMenuItem          *showItem;
@property (nonatomic, strong) IBOutlet NSMenu            *statusMenu;
@property (nonatomic, weak) IBOutlet NSMenuItem          *useICloudItem;
@property (nonatomic, weak) IBOutlet NSMenuItem          *rememberPasswordItem;
@property (nonatomic, weak) IBOutlet NSMenuItem          *savePasswordItem;
@property (nonatomic, weak) IBOutlet NSMenuItem          *createUserItem;
@property (nonatomic, weak) IBOutlet NSMenuItem          *usersItem;

+ (MPAppDelegate *)get;

- (IBAction)activate:(id)sender;
- (IBAction)togglePreference:(NSMenuItem *)sender;
- (IBAction)newUser:(NSMenuItem *)sender;
- (IBAction)signOut:(id)sender;

@end
