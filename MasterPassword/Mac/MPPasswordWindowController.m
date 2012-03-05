//
//  MPPasswordWindowController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordWindowController.h"

@interface MPPasswordWindowController ()

@end

@implementation MPPasswordWindowController
@synthesize siteField;
@synthesize contentField;

- (void)windowDidLoad {
    
    [super windowDidLoad];
    
    [self.contentField setStringValue:@""];
}

@end
