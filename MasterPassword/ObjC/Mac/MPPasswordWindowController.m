//
//  MPPasswordWindowController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordWindowController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

#define MPAlertUnlockMP     @"MPAlertUnlockMP"
#define MPAlertIncorrectMP  @"MPAlertIncorrectMP"
#define MPAlertCreateSite   @"MPAlertCreateSite"
#define MPAlertChangeType   @"MPAlertChangeType"

@interface MPPasswordWindowController()

@property(nonatomic) BOOL inProgress;
@property(nonatomic) BOOL siteFieldPreventCompletion;

@property(nonatomic, strong) NSOperationQueue *backgroundQueue;
@property(nonatomic, strong) NSAlert *loadingDataAlert;
@property(nonatomic) BOOL closing;
@end

@implementation MPPasswordWindowController {
    NSManagedObjectID *_activeElementOID;
}

- (void)windowDidLoad {

    if ([[MPMacConfig get].dialogStyleHUD boolValue]) {
        self.window.styleMask = NSHUDWindowMask | NSTitledWindowMask | NSUtilityWindowMask | NSClosableWindowMask;
        self.siteLabel.textColor = [NSColor whiteColor];
    }
    else {
        self.window.styleMask = NSTexturedBackgroundWindowMask | NSResizableWindowMask | NSTitledWindowMask | NSClosableWindowMask;
        self.siteLabel.textColor = [NSColor controlTextColor];
    }

    self.backgroundQueue = [NSOperationQueue new];
    self.backgroundQueue.maxConcurrentOperationCount = 1;

    [self setContent:@""];
    [self.tipField setStringValue:@""];

    [self.userLabel setStringValue:PearlString( @"%@'s password for:", [[MPMacAppDelegate get] activeUserForMainThread].name )];
    [[MPMacAppDelegate get] addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
//        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
//            if (![MPAlgorithmDefault migrateUser:[[MPMacAppDelegate get] activeUserInContext:moc]])
//                [NSAlert alertWithMessageText:@"Migration Needed" defaultButton:@"OK" alternateButton:nil otherButton:nil
//                    informativeTextWithFormat:@"Certain sites require explicit migration to get updated to the latest version of the "
//                            @"Master Password algorithm.  For these sites, a migration button will appear.  Migrating these sites will cause "
//                            @"their passwords to change.  You'll need to update your profile for that site with the new password."];
//            [moc saveToStore];
//        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:YES];
        });
    }                             forKeyPath:@"key" options:NSKeyValueObservingOptionInitial context:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
     ^(NSNotification *note) {
        [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:NO];
        [self.siteField selectText:nil];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
     ^(NSNotification *note) {
         NSWindow *sheet = [self.window attachedSheet];
         if (sheet)
             [NSApp endSheet:sheet];
         
         [NSApp hide:nil];
         self.closing = NO;
     }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedOutNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
     ^(NSNotification *note) {
        _activeElementOID = nil;
        [self.siteField setStringValue:@""];
        [self.typeField deselectItemAtIndex:[self.typeField indexOfSelectedItem]];
        [self trySiteWithAction:NO];
        [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:YES];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidChangeNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
     ^(NSNotification *note) {
        [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:NO];
    }];

    [super windowDidLoad];
}

- (void)close {

    self.closing = YES;
    [super close];
}

- (BOOL)ensureLoadedAndUnlockedOrCloseIfLoggedOut:(BOOL)closeIfLoggedOut {

    if (![self ensureStoreLoaded])
        return NO;

    if (self.closing || self.inProgress || !self.window.isKeyWindow)
        return NO;

    return [self ensureUnlocked:closeIfLoggedOut];
}

- (BOOL)ensureStoreLoaded {

    if ([MPMacAppDelegate managedObjectContextForMainThreadIfReady]) {
        // Store loaded.
        if (self.loadingDataAlert.window)
            [NSApp endSheet:self.loadingDataAlert.window];

        return YES;
    }

    [self.loadingDataAlert = [NSAlert alertWithMessageText:@"Opening Your Data" defaultButton:@"..." alternateButton:nil otherButton:nil
                                 informativeTextWithFormat:@""]
            beginSheetModalForWindow:self.window modalDelegate:self
                      didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];

    return NO;
}

- (BOOL)ensureUnlocked:(BOOL)closeIfLoggedOut {

    __block BOOL unlocked = NO;
    [MPMacAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *moc) {
        MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:moc];
        NSString *userName = activeUser.name;
        if (!activeUser) {
            // No user to sign in with.
            if (closeIfLoggedOut)
                [self close];
            return;
        }
        if ([MPMacAppDelegate get].key) {
            // Already logged in.
            unlocked = YES;
            return;
        }
        if (activeUser.saveKey && closeIfLoggedOut) {
            // App was locked, don't instantly unlock again.
            [self close];
            return;
        }
        if ([[MPMacAppDelegate get] signInAsUser:activeUser saveInContext:moc usingMasterPassword:nil]) {
            // Loaded the key from the keychain.
            unlocked = YES;
            return;
        }

        // Ask the user to set the key through his master password.
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if ([MPMacAppDelegate get].key)
                return;

            self.content = @"";
            [self.siteField setStringValue:@""];
            [self.typeField deselectItemAtIndex:[self.typeField indexOfSelectedItem]];
            [self.tipField setStringValue:@""];

            NSAlert *alert = [NSAlert alertWithMessageText:@"Master Password is locked."
                                             defaultButton:@"Unlock" alternateButton:@"Change" otherButton:@"Cancel"
                                 informativeTextWithFormat:@"The master password is required to unlock the application for:\n\n%@",
                                                           userName];
            NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
            [alert setAccessoryView:passwordField];
            [alert layout];
            [passwordField becomeFirstResponder];
            [alert beginSheetModalForWindow:self.window modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertUnlockMP];
        }];
    }];

    return unlocked;
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertIncorrectMP) {
        [self close];
        return;
    }
    if (contextInfo == MPAlertUnlockMP) {
        switch (returnCode) {
            case NSAlertAlternateReturn: {
                // "Change" button.
                NSInteger returnCode_ = [[NSAlert
                        alertWithMessageText:@"Changing Master Password" defaultButton:nil
                             alternateButton:[PearlStrings get].commonButtonCancel otherButton:nil informativeTextWithFormat:
                                @"This will allow you to log in with a different master password.\n\n"
                                        @"Note that you will only see the sites and passwords for the master password you log in with.\n"
                                        @"If you log in with a different master password, your current sites will be unavailable.\n\n"
                                        @"You can always change back to your current master password later.\n"
                                        @"Your current sites and passwords will then become available again."]
                        runModal];

                if (returnCode_ == NSAlertDefaultReturn) {
                    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                        MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:context];
                        activeUser.keyID = nil;
                        [[MPMacAppDelegate get] forgetSavedKeyFor:activeUser];
                        [[MPMacAppDelegate get] signOutAnimated:YES];
                        [context saveToStore];
                    }];
                }
                break;
            }

            case NSAlertOtherReturn: {
                // "Cancel" button.
                [self close];
                break;
            }

            case NSAlertDefaultReturn: {
                // "Unlock" button.
                self.contentContainer.alphaValue = 0;
                [self.progressView startAnimation:nil];
                self.inProgress = YES;

                NSString *password = [(NSSecureTextField *)alert.accessoryView stringValue];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
                    MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:moc];
                    NSString *userName = activeUser.name;
                    BOOL success = [[MPMacAppDelegate get] signInAsUser:activeUser saveInContext:moc
                                                    usingMasterPassword:password];
                    self.inProgress = NO;

                    dispatch_async( dispatch_get_current_queue(), ^{
                        [self.progressView stopAnimation:nil];

                        if (success)
                            self.contentContainer.alphaValue = 1;
                        else {
                            [[NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                                    NSLocalizedDescriptionKey : PearlString( @"Incorrect master password for user %@", userName )
                            }]] beginSheetModalForWindow:self.window modalDelegate:self
                                          didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertIncorrectMP];
                        }
                    } );
                }];
                break;
            }

            default:
                break;
        }

        return;
    }
    if (contextInfo == MPAlertCreateSite) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                [[MPMacAppDelegate get] addElementNamed:[self.siteField stringValue] completion:^(MPElementEntity *element) {
                    if (element) {
                        _activeElementOID = element.objectID;
                        [self trySiteWithAction:NO];
                    }
                }];
                break;
            }
            default:
                break;
        }
    }
    if (contextInfo == MPAlertChangeType) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                MPElementType type = [self selectedType];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *activeElement = [self activeElementInContext:context];
                    _activeElementOID = [[MPMacAppDelegate get] changeElement:activeElement inContext:context
                                                                       toType:type].objectID;
                    [context saveToStore];

                    dispatch_async( dispatch_get_main_queue(), ^{
                        [self trySiteWithAction:NO];
                    } );
                }];
                break;
            }
            default:
                break;
        }
    }
}

- (MPElementType)selectedType {

    if (self.typeField.indexOfSelectedItem == 0)
        return MPElementTypeGeneratedMaximum;
    if (self.typeField.indexOfSelectedItem == 1)
        return MPElementTypeGeneratedLong;
    if (self.typeField.indexOfSelectedItem == 2)
        return MPElementTypeGeneratedMedium;
    if (self.typeField.indexOfSelectedItem == 3)
        return MPElementTypeGeneratedBasic;
    if (self.typeField.indexOfSelectedItem == 4)
        return MPElementTypeGeneratedShort;
    if (self.typeField.indexOfSelectedItem == 5)
        return MPElementTypeGeneratedPIN;
    if (self.typeField.indexOfSelectedItem == 6)
        return MPElementTypeStoredPersonal;
    if (self.typeField.indexOfSelectedItem == 7)
        return MPElementTypeStoredDevicePrivate;

    wrn(@"Unsupported type selected: %li, assuming Long.", self.typeField.indexOfSelectedItem);
    return MPElementTypeGeneratedLong;
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification {

    if (notification.object == self.typeField) {
        if ([self.typeField indexOfSelectedItem] < 0)
            return;
        MPElementEntity *activeElement = [self activeElementForMainThread];
        MPElementType selectedType = [self selectedType];
        if (!activeElement || activeElement.type == selectedType || !(selectedType & MPElementTypeClassGenerated))
            return;

        [[NSAlert alertWithMessageText:@"Change Password Type" defaultButton:@"Change Password"
                       alternateButton:@"Cancel" otherButton:nil
             informativeTextWithFormat:@"Changing the password type for this site will cause the password to change.\n"
                     @"You will need to update your account with the new password."]
                beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                             contextInfo:MPAlertChangeType];
    }
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {

    NSString *query = [[textView string] substringWithRange:charRange];
    if (![query length] || ![MPMacAppDelegate get].key)
        return nil;

    __block NSMutableArray *mutableResults = [NSMutableArray array];
    [MPMacAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
        fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(name BEGINSWITH[cd] %@) AND user == %@",
                                                                  query, [[MPMacAppDelegate get] activeUserInContext:context]];

        NSError *error = nil;
        NSArray *siteResults = [context executeFetchRequest:fetchRequest error:&error];
        if (!siteResults)
        err(@"While fetching elements for completion: %@", error);
        else if ([siteResults count]) {
            _activeElementOID = ((NSManagedObject *)[siteResults objectAtIndex:0]).objectID;
            for (MPElementEntity *element in siteResults)
                [mutableResults addObject:element.name];
        }
        else
            _activeElementOID = nil;
    }];

    if ([mutableResults count] < 2) {
        //[textView setString:[(MPElementEntity *)[siteResults objectAtIndex:0] name]];
        //[textView setSelectedRange:NSMakeRange( [query length], [[textView string] length] - [query length] )];
        [self trySiteWithAction:NO];
    }

    return mutableResults;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

    if (commandSelector == @selector(cancel:)) { // Escape without completion.
        [self close];
        return YES;
    }
    if ((self.siteFieldPreventCompletion = [NSStringFromSelector( commandSelector ) hasPrefix:@"delete"])) { // Backspace any time.
        _activeElementOID = nil;
        [self trySiteWithAction:NO];
        return NO;
    }
    if (commandSelector == @selector(insertNewline:)) { // Return without completion.
        [self trySiteWithAction:YES];
        return YES;
    }

    return NO;
}

- (void)controlTextDidEndEditing:(NSNotification *)note {

    if (note.object != self.siteField)
        return;

    [self trySiteWithAction:NO];
}

- (void)controlTextDidChange:(NSNotification *)note {

    if (note.object != self.siteField)
        return;

    // Update the site content as the site name changes.
    if ([[NSApp currentEvent] type] == NSKeyDown &&
        [[[NSApp currentEvent] charactersIgnoringModifiers] isEqualToString:@"\r"]) { // Return while completing.
        [self trySiteWithAction:YES];
        return;
    }

    if ([[NSApp currentEvent] type] == NSKeyDown &&
        [[[NSApp currentEvent] charactersIgnoringModifiers] characterAtIndex:0] == 0x1b) { // Escape while completing.
        _activeElementOID = nil;
        [self trySiteWithAction:NO];
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

- (MPElementEntity *)activeElementForMainThread {

    return [self activeElementInContext:[MPMacAppDelegate managedObjectContextForMainThreadIfReady]];
}

- (MPElementEntity *)activeElementInContext:(NSManagedObjectContext *)moc {

    if (!_activeElementOID)
        return nil;

    NSError *error;
    MPElementEntity *activeElement = (MPElementEntity *)[moc existingObjectWithID:_activeElementOID error:&error];
    if (!activeElement)
    err(@"Couldn't retrieve active element: %@", error);

    return activeElement;
}

- (void)setContent:(NSString *)content {

    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSCenterTextAlignment;

    [self.contentField setAttributedStringValue:[[NSAttributedString alloc] initWithString:content attributes:@{
            NSParagraphStyleAttributeName : paragraph
    }]];
}

- (void)trySiteWithAction:(BOOL)doAction {

    NSString *siteName = [self.siteField stringValue];
    [self.progressView startAnimation:nil];
    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        BOOL actionHandled = NO;
        MPElementEntity *activeElement = [self activeElementInContext:context];
        NSString *content = [activeElement.content description];
        NSString *typeName = [activeElement typeShortName];
        if (!content)
            content = @"";

        if (doAction) {
            if ([content length]) {
                // Performing action while content is available.  Copy it.
                [self copyContent:content];
            }
            else if ([siteName length]) {
                // Performing action without content but a site name is written.
                [self createNewSite:siteName];
                actionHandled = YES;
            }
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self setContent:content];
            [self.progressView stopAnimation:nil];
            if (![[self.typeField stringValue] isEqualToString:typeName])
                [self.typeField selectItemWithObjectValue:typeName];

            self.tipField.alphaValue = 1;
            if (actionHandled)
                [self.tipField setStringValue:@""];
            else if ([content length] == 0) {
                if ([siteName length])
                    [self.tipField setStringValue:@"Hit ⌤ (ENTER) to create a new site."];
                else
                    [self.tipField setStringValue:@""];
            }
            else if (!doAction)
                [self.tipField setStringValue:@"Hit ⌤ (ENTER) to copy the password."];
            else {
                [self.tipField setStringValue:@"Copied!  Hit ⎋ (ESC) to close window."];
                dispatch_after( dispatch_time( DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC) ), dispatch_get_main_queue(), ^{
                    [NSAnimationContext beginGrouping];
                    [[NSAnimationContext currentContext] setDuration:0.2f];
                    [self.tipField.animator setAlphaValue:0];
                    [NSAnimationContext endGrouping];
                } );
            }
        }];
    }];
}

- (void)copyContent:(NSString *)content {

    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    if (![[NSPasteboard generalPasteboard] setString:content forType:NSPasteboardTypeString]) {
        wrn(@"Couldn't copy password to pasteboard.");
        return;
    }

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        [[self activeElementInContext:moc] use];
        [moc saveToStore];
    }];
}

- (void)createNewSite:(NSString *)siteName {

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSAlert *alert = [NSAlert alertWithMessageText:@"Create site?"
                                         defaultButton:@"Create" alternateButton:nil otherButton:@"Cancel"
                             informativeTextWithFormat:@"Do you want to create a new site named:\n\n%@", siteName];
        [alert beginSheetModalForWindow:self.window modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertCreateSite];
    }];
}

@end
