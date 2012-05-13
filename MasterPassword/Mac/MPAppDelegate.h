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

@interface MPAppDelegate : MPAppDelegate_Shared <NSApplicationDelegate>

@property (strong) NSStatusItem                                         *statusItem;
@property (strong) MPPasswordWindowController                           *passwordWindow;
@property (weak) IBOutlet NSMenuItem                                    *lockItem;
@property (weak) IBOutlet NSMenuItem                                    *showItem;
@property (strong) IBOutlet NSMenu                                      *statusMenu;
@property (weak) IBOutlet NSMenuItem                                    *useICloudItem;
@property (weak) IBOutlet NSMenuItem                                    *rememberPasswordItem;
@property (weak) IBOutlet NSMenuItem                                    *savePasswordItem;

+ (MPAppDelegate *)get;

- (IBAction)activate:(id)sender;
- (IBAction)togglePreference:(NSMenuItem *)sender;

@end
