//
//  MPPasswordWindowController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordWindowController.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
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

    [self setContent:@""];
    [self.tipField setStringValue:@""];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self unlock];
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

- (void)unlock {

    if (![MPAppDelegate get].key)
     // Try and load the key from the keychain.
        [[MPAppDelegate get] loadStoredKey];

    if (![MPAppDelegate get].key)
     // Ask the user to set the key through his master password.
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MPAppDelegate get].key)
                return;

            NSAlert           *alert         = [NSAlert alertWithMessageText:@"Master Password is locked."
                                                               defaultButton:@"Unlock" alternateButton:@"Change" otherButton:@"Quit"
                                                   informativeTextWithFormat:@"Your master password is required to unlock the application."];
            NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
            [alert setAccessoryView:passwordField];
            [alert layout];
            [passwordField becomeFirstResponder];
            [alert beginSheetModalForWindow:self.window modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
        });
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    switch (returnCode) {
        case NSAlertAlternateReturn:
            // "Change" button.
            if ([[NSAlert alertWithMessageText:@"Changing Master Password"
                                 defaultButton:nil alternateButton:[PearlStrings get].commonButtonCancel otherButton:nil
                                                                                           informativeTextWithFormat:
                                                                                            @"This will allow you to log in with a different master password.\n\n"
                                                                                             @"Note that you will only see the sites and passwords for the master password you log in with.\n"
                                                                                             @"If you log in with a different master password, your current sites will be unavailable.\n\n"
                                                                                             @"You can always change back to your current master password later.\n"
                                                                                             @"Your current sites and passwords will then become available again."] runModal]
             == 1)
                [[MPAppDelegate get] forgetKey];
            break;

        case NSAlertOtherReturn:
            // "Quit" button.
            [[NSApplication sharedApplication] terminate:self];
            return;

        case NSAlertDefaultReturn:
            // "Unlock" button.
            [[MPAppDelegate get] tryMasterPassword:[(NSSecureTextField *)alert.accessoryView stringValue]];
    }
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {

    NSString *query = [[control stringValue] substringWithRange:charRange];
    if (![query length] || ![MPAppDelegate get].keyID)
        return nil;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses_" ascending:NO]];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"(%@ == '' OR name BEGINSWITH[cd] %@) AND user == %@",
                                                                    query, query, [MPAppDelegate get].activeUser];

    NSError *error = nil;
    self.siteResults = [[MPAppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if (error)
    err(@"Couldn't fetch elements: %@", error);

    NSMutableArray           *mutableResults = [NSMutableArray arrayWithCapacity:[self.siteResults count] + 1];
    if (self.siteResults)
        for (MPElementEntity *element in self.siteResults)
            [mutableResults addObject:element.name];
    //    [mutableResults addObject:query]; // For when the app should be able to create new sites.
    return mutableResults;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

    if (commandSelector == @selector(cancel:)) {
        [self.window close];
        return YES;
    }
    if (commandSelector == @selector(insertNewline:) && [self.content length]) {
        [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
        if ([[NSPasteboard generalPasteboard] setString:self.content forType:NSPasteboardTypeString]) {
            self.tipField.alphaValue = 1;
            [self.tipField setStringValue:@"Copied!"];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                [NSAnimationContext beginGrouping];
                [[NSAnimationContext currentContext] setDuration:0.2f];
                [self.tipField.animator setAlphaValue:0];
                [NSAnimationContext endGrouping];
            });

            [[self findElement] use];
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

- (NSString *)content {

    return _content;
}

- (void)setContent:(NSString *)content {

    _content = content;

    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor      = [NSColor colorWithDeviceWhite:0.0f alpha:0.6f];
    shadow.shadowOffset     = NSMakeSize(1.0f, -1.0f);
    shadow.shadowBlurRadius = 1.2f;

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSCenterTextAlignment;

    [self.contentField setAttributedStringValue:
                        [[NSAttributedString alloc] initWithString:_content
                                                        attributes:[[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                                         shadow, NSShadowAttributeName,
                                                         paragraph, NSParagraphStyleAttributeName,
                                                         nil]]];
}

- (BOOL)trySite {

    MPElementEntity *result = [self findElement];
    if (!result) {
        [self setContent:@""];
        [self.tipField setStringValue:@""];
        return NO;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *description = [result.content description];
        if (!description)
            description = @"";

        dispatch_async(dispatch_get_main_queue(), ^{
            [self setContent:description];
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
     assert([MPAppDelegate get].keyID);
     
     element.name = siteName;
     element.keyID = [MPAppDelegate get].keyID;
     
     NSString *description = [element.content description];
     [element use];
     
     dispatch_async(dispatch_get_main_queue(), ^{
     [self setContent:description];
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
