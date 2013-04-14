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

#define MPAlertUnlockMP     @"MPAlertUnlockMP"
#define MPAlertIncorrectMP  @"MPAlertIncorrectMP"


@interface MPPasswordWindowController ()

@property (nonatomic, strong) NSArray /* MPElementEntity */ *siteResults;
@property (nonatomic) BOOL inProgress;
@property (nonatomic) BOOL siteFieldPreventCompletion;

@end

@implementation MPPasswordWindowController

- (void)windowDidLoad {

    [self setContent:@""];
    [self.tipField setStringValue:@""];

    [[MPAppDelegate get] addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        [self.userLabel setStringValue:PearlString(@"%@'s password for:", [MPAppDelegate get].activeUser.name)];
    }                          forKeyPath:@"activeUser" options:NSKeyValueObservingOptionInitial context:nil];
    [[MPAppDelegate get] addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        if (![MPAppDelegate get].key) {
            [self unlock];
            return;
        }
        
        [MPAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
            MPUserEntity *activeUser = [MPAppDelegate get].activeUser;
            if (![MPAlgorithmDefault migrateUser:activeUser])
                [NSAlert alertWithMessageText:@"Migration Needed" defaultButton:@"OK" alternateButton:nil otherButton:nil
                    informativeTextWithFormat:@"Certain sites require explicit migration to get updated to the latest version of the "
                 @"Master Password algorithm.  For these sites, a migration button will appear.  Migrating these sites will cause "
                 @"their passwords to change.  You'll need to update your profile for that site with the new password."];
            [moc saveToStore];
        }];
    }                          forKeyPath:@"key" options:NSKeyValueObservingOptionInitial context:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if (!self.inProgress)
                                                          [self unlock];
                                                      [self.siteField selectText:self];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSApplication sharedApplication] hide:self];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedOutNotification object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.window close];
                                                  }];

    [super windowDidLoad];
}

- (void)unlock {

    if (![MPAppDelegate get].activeUser)
        // No user to sign in with.
        return;
    if ([MPAppDelegate get].key)
        // Already logged in.
        return;
    if ([[MPAppDelegate get] signInAsUser:[MPAppDelegate get].activeUser usingMasterPassword:nil])
        // Load the key from the keychain.
        return;

    if (![MPAppDelegate get].key)
     // Ask the user to set the key through his master password.
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([MPAppDelegate get].key)
                return;

            self.content = @"";
            [self.siteField setStringValue:@""];
            [self.tipField setStringValue:@""];

            NSAlert           *alert         = [NSAlert alertWithMessageText:@"Master Password is locked."
                                                               defaultButton:@"Unlock" alternateButton:@"Change" otherButton:@"Cancel"
                                                   informativeTextWithFormat:@"The master password is required to unlock the application for:\n\n%@", [MPAppDelegate get].activeUser.name];
            NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
            [alert setAccessoryView:passwordField];
            [alert layout];
            [passwordField becomeFirstResponder];
            [alert beginSheetModalForWindow:self.window modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertUnlockMP];
        });
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertIncorrectMP) {
        [self.window close];
        return;
    }
    if (contextInfo == MPAlertUnlockMP) {
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
                 == 1) {
                    [MPAppDelegate get].activeUser.keyID = nil;
                    [[MPAppDelegate get] forgetSavedKeyFor:[MPAppDelegate get].activeUser];
                    [[MPAppDelegate get] signOutAnimated:YES];
                }
                break;

            case NSAlertOtherReturn:
                // "Cancel" button.
                [self.window close];
                return;

            case NSAlertDefaultReturn: {
                // "Unlock" button.
                self.contentContainer.alphaValue = 0;
                [self.progressView startAnimation:nil];
                self.inProgress = YES;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    BOOL success    = [[MPAppDelegate get] signInAsUser:[MPAppDelegate get].activeUser
                                                    usingMasterPassword:[(NSSecureTextField *)alert.accessoryView stringValue]];
                    self.inProgress = NO;

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressView stopAnimation:nil];

                        if (success)
                            self.contentContainer.alphaValue = 1;
                        else {
                            [[NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                             NSLocalizedDescriptionKey : PearlString(@"Incorrect master password for user %@",
                                                                     [MPAppDelegate get].activeUser.name)
                            }]] beginSheetModalForWindow:self.window modalDelegate:self
                                          didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertIncorrectMP];
                        }
                    });
                });
            }

            default:
                break;
        }

        return;
    }
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {

    NSString *query = [[control stringValue] substringWithRange:charRange];
    if (![query length] || ![MPAppDelegate get].key)
        return nil;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
    fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses_" ascending:NO]];
    fetchRequest.predicate       = [NSPredicate predicateWithFormat:@"(name BEGINSWITH[cd] %@) AND user == %@",
                                                                    query, [MPAppDelegate get].activeUser];

    NSError *error = nil;
    self.siteResults = [[MPAppDelegate managedObjectContextForThreadIfReady] executeFetchRequest:fetchRequest error:&error];
    if (error)
    err(@"While fetching elements for completion: %@", error);

    if ([self.siteResults count] == 1) {
        [textView setString:[(MPElementEntity *)[self.siteResults objectAtIndex:0] name]];
        [textView setSelectedRange:NSMakeRange([query length], [[textView string] length] - [query length])];
        if ([self trySite])
            return nil;
    }

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
    if ((self.siteFieldPreventCompletion = [NSStringFromSelector(commandSelector) hasPrefix:@"delete"]))
        return NO;
    if (commandSelector == @selector(insertNewline:) && [self.content length]) {
        if ([self trySite])
            [self copyContents];
        return YES;
    }

    return NO;
}

- (void)copyContents {

    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    if (![[NSPasteboard generalPasteboard] setString:self.content forType:NSPasteboardTypeString]) {
        wrn(@"Couldn't copy password to pasteboard.");
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        self.tipField.alphaValue = 1;
        [self.tipField setStringValue:@"Copied!  Hit ⎋ (ESC) to close window."];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0.2f];
            [self.tipField.animator setAlphaValue:0];
            [NSAnimationContext endGrouping];
        });
    });

    [[self findElement] use];
}

- (void)controlTextDidEndEditing:(NSNotification *)note {

    if (note.object != self.siteField)
        return;

    [self trySite];
}

- (void)controlTextDidChange:(NSNotification *)note {

    if (note.object != self.siteField)
        return;

    // Update the site content as the site name changes.
    BOOL hasValidSite = [self trySite];

    if ([[NSApp currentEvent] type] == NSKeyDown && [[[NSApp currentEvent] charactersIgnoringModifiers] isEqualToString:@"\r"]) {
        if (hasValidSite)
            [self copyContents];
        return;
    }

    if (self.siteFieldPreventCompletion) {
        self.siteFieldPreventCompletion = NO;
        return;
    }

    self.siteFieldPreventCompletion = YES;
    [(NSText *)[note.userInfo objectForKey:@"NSFieldEditor"] complete:self];
    self.siteFieldPreventCompletion = NO;
}

- (NSString *)content {

    return _content;
}

- (void)setContent:(NSString *)content {

    _content = content;

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSCenterTextAlignment;

    [self.contentField setAttributedStringValue:
                        [[NSAttributedString alloc] initWithString:_content
                                                        attributes:[[NSMutableDictionary alloc] initWithObjectsAndKeys:
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
            [self.tipField setStringValue:@"Hit ⌤ (ENTER) to copy the password."];
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
