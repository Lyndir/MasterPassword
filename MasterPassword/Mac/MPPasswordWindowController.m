//
//  MPPasswordWindowController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordWindowController.h"
#import "MPAppDelegate_Key.h"
#import "MPElementEntity.h"
#import "MPElementGeneratedEntity.h"

@interface MPPasswordWindowController ()

@property (nonatomic, strong) NSString                      *oldSiteName;
@property (nonatomic, strong) NSArray /* MPElementEntity */ *siteResults;

@end

@implementation MPPasswordWindowController
@synthesize oldSiteName, siteResults;
@synthesize siteField;
@synthesize contentField;
@synthesize tipField;

- (void)windowDidLoad {
    
    [self.contentField setStringValue:@""];
    [self.tipField setStringValue:@""];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.siteField selectText:self];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSApplication sharedApplication] hide:self];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification object:self.siteField queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      NSString *newSiteName = [self.siteField stringValue];
                                                      BOOL shouldComplete = [self.oldSiteName length] < [newSiteName length];
                                                      self.oldSiteName = newSiteName;
                                                      
                                                      if ([self trySite])
                                                          shouldComplete = NO;
                                                      
                                                      if (shouldComplete)
                                                          [[[note userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
                                                  }];
    
    [super windowDidLoad];
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    
    NSString *query = [[control stringValue] substringWithRange:charRange];
    if (![query length] || ![MPAppDelegate get].keyHashHex)
        return nil;
    
    NSFetchRequest *fetchRequest = [MPAppDelegate.managedObjectModel
                                    fetchRequestFromTemplateWithName:@"MPElements"
                                    substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           query,                                   @"query",
                                                           [MPAppDelegate get].keyHashHex,          @"mpHashHex",
                                                           nil]];
    [fetchRequest setSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
    
    NSError *error = nil;
    self.siteResults = [[MPAppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if (error)
        err(@"Couldn't fetch elements: %@", error);
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithCapacity:[self.siteResults count] + 1];
    if (self.siteResults)
        for (MPElementEntity *element in self.siteResults)
            [mutableResults addObject:element.name];
    //    [mutableResults addObject:query]; // For when the app should be able to create new sites.
    return mutableResults;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {
    
    if (commandSelector == @selector(cancel:))
        [self.window close];
    if (commandSelector == @selector(insertNewline:) && [[self.contentField stringValue] length]) {
        [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        if ([[NSPasteboard generalPasteboard] setString:[self.contentField stringValue] forType:NSPasteboardTypeString]) {
            self.tipField.alphaValue = 1;
            [self.tipField setStringValue:@"Copied!"];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0f * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.2f];
                [self.tipField.animator setAlphaValue:0];
                [NSAnimationContext endGrouping];
            });
            return YES;
        } else
            wrn(@"Couldn't copy password to pasteboard.");
    }
    
    return NO;  
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    if (obj.object == self.siteField)
        [self trySite];
}

- (BOOL)trySite {
    
    MPElementEntity *result = [self findElement];
    if (!result) {
        [self.contentField setStringValue:@""];
        [self.tipField setStringValue:@""];
        return NO;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *description = [result description];
        [result use];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentField setStringValue:description];
            [self.tipField setStringValue:@"Hit enter to copy the password."];
            self.tipField.alphaValue = 1;
        });
    });
    
    // For when the app should be able to create new sites.
    /*
     else
     [[MPAppDelegate get].managedObjectContext performBlock:^{
     MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPElementGeneratedEntity class])
     inManagedObjectContext:[MPAppDelegate get].managedObjectContext];
     assert([element isKindOfClass:ClassFromMPElementType(element.type)]);
     assert([MPAppDelegate get].keyHashHex);
     
     element.name = siteName;
     element.mpHashHex = [MPAppDelegate get].keyHashHex;
     
     NSString *description = [element description];
     [element use];
     
     dispatch_async(dispatch_get_main_queue(), ^{
     [self.contentField setStringValue:description? description: @""];
     });
     }];
     */
    
    return YES;
}

- (MPElementEntity *)findElement {
    
    for (MPElementEntity *element in self.siteResults)
        if ([element.name isEqualToString:[self.siteField stringValue]])
            return element;
    
    return nil;
}

@end
