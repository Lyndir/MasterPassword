//
//  MPAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPPasswordWindowController.h"

@interface MPAppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSStatusItem                                         *statusItem;
@property (weak) IBOutlet NSMenuItem *unlockItem;
@property (weak) IBOutlet NSMenuItem *lockItem;
@property (weak) IBOutlet NSMenuItem *showItem;
@property (strong) IBOutlet NSMenu *statusMenu;

- (IBAction)activate:(id)sender;
- (IBAction)unlock:(id)sender;

@end
