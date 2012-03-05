//
//  MPPasswordWindowController.h
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPPasswordWindowController : NSWindowController <NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *siteField;
@property (weak) IBOutlet NSTextField *contentField;

@end
