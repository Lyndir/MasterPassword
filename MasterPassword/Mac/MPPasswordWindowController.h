//
//  MPPasswordWindowController.h
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPPasswordWindowController : NSWindowController <NSTextFieldDelegate> {
    
    NSString *_content;
}

@property (strong) NSString *content;

@property (weak) IBOutlet NSTextField *siteField;
@property (weak) IBOutlet NSTextField *contentField;
@property (weak) IBOutlet NSTextField *tipField;

- (void)unlock;

@end
