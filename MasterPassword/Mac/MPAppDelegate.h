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

@property (assign) IBOutlet NSWindow                                    *window;
@property (strong) NSStatusItem                                         *statusItem;

- (IBAction)saveAction:(id)sender;

- (void)loadKey;

@end
