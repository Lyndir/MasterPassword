//
//  MPPasswordWindowController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordWindowController.h"
#import "MPAppDelegate.h"

@interface MPPasswordWindowController ()

@property (nonatomic, assign) BOOL completingSiteName;

@end

@implementation MPPasswordWindowController
@synthesize completingSiteName;
@synthesize siteField;
@synthesize contentField;

- (void)windowDidLoad {
    
    [self.contentField setStringValue:@""];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSApplication sharedApplication] hide:self];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification object:self.siteField queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if (!self.completingSiteName) {
                                                          self.completingSiteName = YES;
                                                          [[[note userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
                                                          self.completingSiteName = NO;
                                                      }
                                                  }];
    
    [super windowDidLoad];
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    
    NSString *query = [[control stringValue] substringWithRange:charRange];
    NSFetchRequest *fetchRequest = [MPAppDelegate.managedObjectModel
                                    fetchRequestFromTemplateWithName:@"MPElements"
                                    substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           query,                                   @"query",
                                                           [MPAppDelegate get].keyPhraseHashHex,    @"mpHashHex",
                                                           nil]];

    return [NSArray arrayWithObjects:@"cow", @"milk", @"hippopotamus", nil];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    if (obj.object == self.siteField) {
//        NSString *siteName = [self.siteField stringValue];
        
//        [self.contentField setStringValue:];
    }
}

@end
