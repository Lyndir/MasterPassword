//
//  MPPasswordDialogController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordDialogController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "MPElementModel.h"

#define MPAlertUnlockMP     @"MPAlertUnlockMP"
#define MPAlertIncorrectMP  @"MPAlertIncorrectMP"
#define MPAlertCreateSite   @"MPAlertCreateSite"

@interface MPPasswordDialogController()

@property(nonatomic) BOOL inProgress;

@property(nonatomic, strong) NSOperationQueue *backgroundQueue;
@property(nonatomic, strong) NSAlert *loadingDataAlert;
@property(nonatomic) BOOL closing;

@end

@implementation MPPasswordDialogController

#pragma mark - Life

- (void)windowDidLoad {

    if ([[MPMacConfig get].dialogStyleHUD boolValue]) {
        self.window.styleMask = NSHUDWindowMask | NSTitledWindowMask | NSUtilityWindowMask | NSClosableWindowMask;
        self.userLabel.textColor = [NSColor whiteColor];
    }
    else {
        self.window.styleMask = NSTexturedBackgroundWindowMask | NSResizableWindowMask | NSTitledWindowMask | NSClosableWindowMask;
        self.userLabel.textColor = [NSColor controlTextColor];
    }

    self.backgroundQueue = [NSOperationQueue new];
    self.backgroundQueue.maxConcurrentOperationCount = 1;

    [[MPMacAppDelegate get] addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
//        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
//            if (![MPAlgorithmDefault migrateUser:[[MPMacAppDelegate get] activeUserInContext:moc]])
//                [NSAlert alertWithMessageText:@"Migration Needed" defaultButton:@"OK" alternateButton:nil otherButton:nil
//                    informativeTextWithFormat:@"Certain sites require explicit migration to get updated to the latest version of the "
//                            @"Master Password algorithm.  For these sites, a migration button will appear.  Migrating these sites will cause "
//                            @"their passwords to change.  You'll need to update your profile for that site with the new password."];
//            [moc saveToStore];
//        }];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:YES];
            [self updateElements];
        }];
    }                             forKeyPath:@"key" options:NSKeyValueObservingOptionInitial context:nil];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
            ^(NSNotification *note) {
                [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:NO];
                [self.siteField selectText:nil];
                [self updateElements];
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
                self.userLabel.stringValue = @"";
                self.siteField.stringValue = @"";
                self.elements = nil;

                [self ensureLoadedAndUnlockedOrCloseIfLoggedOut:YES];
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedInNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
            ^(NSNotification *note) {
                self.userLabel.stringValue = PearlString( @"%@'s password for:",
                        [[MPMacAppDelegate get] activeUserForMainThread].name );
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

#pragma mark - NSAlert

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertIncorrectMP) {
        [self close];
        return;
    }
    if (contextInfo == MPAlertUnlockMP) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Unlock" button.
                self.contentContainer.alphaValue = 0;
                self.inProgress = YES;

                NSString *password = [(NSSecureTextField *)alert.accessoryView stringValue];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
                    MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:moc];
                    NSString *userName = activeUser.name;
                    BOOL success = [[MPMacAppDelegate get] signInAsUser:activeUser saveInContext:moc
                                                    usingMasterPassword:password];
                    self.inProgress = NO;

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (success)
                            self.contentContainer.alphaValue = 1;
                        else {
                            [[NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                                    NSLocalizedDescriptionKey : PearlString( @"Incorrect master password for user %@", userName )
                            }]] beginSheetModalForWindow:self.window modalDelegate:self
                                          didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertIncorrectMP];
                        }
                    }];
                }];
                break;
            }

            case NSAlertSecondButtonReturn: {
                // "Change" button.
                NSAlert *alert_ = [NSAlert new];
                [alert_ addButtonWithTitle:@"Update"];
                [alert_ addButtonWithTitle:@"Cancel"];
                [alert_ setMessageText:@"Changing Master Password"];
                [alert_ setInformativeText:@"This will allow you to log in with a different master password.\n\n"
                        @"Note that you will only see the sites and passwords for the master password you log in with.\n"
                        @"If you log in with a different master password, your current sites will be unavailable.\n\n"
                        @"You can always change back to your current master password later.\n"
                        @"Your current sites and passwords will then become available again."];

                if ([alert_ runModal] == NSAlertFirstButtonReturn) {
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

            case NSAlertThirdButtonReturn: {
                // "Cancel" button.
                [self close];
                break;
            }

            default:
                break;
        }

        return;
    }
    if (contextInfo == MPAlertCreateSite) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Create" button.
                [[MPMacAppDelegate get] addElementNamed:[self.siteField stringValue] completion:^(MPElementEntity *element) {
                    if (element)
                        PearlMainQueue( ^{ [self updateElements]; } );
                }];
                break;
            }
            case NSAlertThirdButtonReturn:
                // "Cancel" button.
                break;
            default:
                break;
        }
    }
}

#pragma mark - NSCollectionViewDelegate

#pragma mark - NSTextFieldDelegate
- (void)doCommandBySelector:(SEL)commandSelector {

    if (commandSelector == @selector(insertNewline:))
        [self useSite];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

    if (commandSelector == @selector(cancel:))
        [self close];
    if (commandSelector == @selector(moveUp:))
        self.elementSelectionIndexes =
                [NSIndexSet indexSetWithIndex:MAX(self.elementSelectionIndexes.firstIndex, (NSUInteger)1) - 1];
    if (commandSelector == @selector(moveDown:))
        self.elementSelectionIndexes =
                [NSIndexSet indexSetWithIndex:MIN(self.elementSelectionIndexes.firstIndex + 1, self.elements.count - 1)];
    if (commandSelector == @selector(moveLeft:))
        [[self selectedView].animator setBoundsOrigin:NSZeroPoint];
    if (commandSelector == @selector(moveRight:))
        [[self selectedView].animator setBoundsOrigin:NSMakePoint( self.siteCollectionView.frame.size.width / 2, 0 )];
    if (commandSelector == @selector(insertNewline:))
        [self useSite];
    else
        return NO;

    return YES;
}

- (void)controlTextDidChange:(NSNotification *)note {

    if (note.object != self.siteField)
        return;

    // Update the site content as the site name changes.
    if ([[NSApp currentEvent] type] == NSKeyDown &&
        [[[NSApp currentEvent] charactersIgnoringModifiers] isEqualToString:@"\r"]) { // Return while completing.
        [self useSite];
        return;
    }

//    if ([[NSApp currentEvent] type] == NSKeyDown &&
//        [[[NSApp currentEvent] charactersIgnoringModifiers] characterAtIndex:0] == 0x1b) { // Escape while completing.
//        [self trySiteWithAction:NO];
//        return;
//    }

    [self updateElements];
}

#pragma mark - Private

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

            [self.siteField setStringValue:@""];

            NSAlert *alert = [NSAlert new];
            [alert addButtonWithTitle:@"Unlock"];
            [alert addButtonWithTitle:@"Change"];
            [alert addButtonWithTitle:@"Cancel"];
            [alert setMessageText:@"Master Password is locked."];
            [alert setInformativeText:PearlString( @"The master password is required to unlock the application for:\n\n%@", userName )];

            NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
            [alert setAccessoryView:passwordField];
            [alert layout];
            [alert beginSheetModalForWindow:self.window modalDelegate:self
                             didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertUnlockMP];
            [passwordField becomeFirstResponder];
        }];
    }];

    return unlocked;
}

- (void)updateElements {

    if (![MPMacAppDelegate get].key) {
        self.elements = nil;
        return;
    }

    NSString *query = [self.siteField.currentEditor string];
    [MPMacAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
        fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(%@ == '' OR name BEGINSWITH[cd] %@) AND user == %@",
                                                                  query, query, [[MPMacAppDelegate get] activeUserInContext:context]];

        NSError *error = nil;
        NSArray *siteResults = [context executeFetchRequest:fetchRequest error:&error];
        if (!siteResults) {
            err(@"While fetching elements for completion: %@", error);
            return;
        }

        NSMutableArray *newElements = [NSMutableArray arrayWithCapacity:[siteResults count]];
        for (MPElementEntity *element in siteResults)
            [newElements addObject:[[MPElementModel alloc] initWithEntity:element]];
        self.elements = newElements;
        if (!self.selectedElement)
            self.elementSelectionIndexes = [newElements count]? [NSIndexSet indexSetWithIndex:0]: nil;
    }];
}

- (NSUInteger)selectedIndex {

    if (!self.elementSelectionIndexes)
        return NSNotFound;
    NSUInteger selectedIndex = self.elementSelectionIndexes.firstIndex;
    if (selectedIndex >= self.elements.count)
        return NSNotFound;

    return selectedIndex;
}

- (NSBox *)selectedView {

    NSUInteger selectedIndex = [self selectedIndex];
    if (selectedIndex == NSNotFound)
        return nil;

    return (NSBox *)[self.siteCollectionView itemAtIndex:selectedIndex].view;
}

- (MPElementModel *)selectedElement {

    NSUInteger selectedIndex = [self selectedIndex];
    if (selectedIndex == NSNotFound)
        return nil;

    return (MPElementModel *)self.elements[selectedIndex];
}

- (void)setSelectedElement:(MPElementModel *)element {

    self.elementSelectionIndexes = [NSIndexSet indexSetWithIndex:[self.elements indexOfObject:element]];
}

- (void)useSite {

    MPElementModel *selectedElement = [self selectedElement];
    if (selectedElement) {
        // Performing action while content is available.  Copy it.
        [self copyContent:selectedElement.content];

        [self close];

        NSUserNotification *notification = [NSUserNotification new];
        notification.title = @"Password Copied";
        if (selectedElement.loginName.length)
            notification.subtitle = PearlString( @"%@ at %@", selectedElement.loginName, selectedElement.site );
        else
            notification.subtitle = selectedElement.site;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else {
        NSString *siteName = [self.siteField stringValue];
        if ([siteName length])
                // Performing action without content but a site name is written.
            [self createNewSite:siteName];
    }
}

- (void)copyContent:(NSString *)content {

    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    if (![[NSPasteboard generalPasteboard] setString:content forType:NSPasteboardTypeString]) {
        wrn(@"Couldn't copy password to pasteboard.");
        return;
    }

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        [[self.selectedElement entityInContext:moc] use];
        [moc saveToStore];
    }];
}

- (void)createNewSite:(NSString *)siteName {

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"Create"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Create site?"];
        [alert setInformativeText:PearlString( @"Do you want to create a new site named:\n\n%@", siteName )];
        [alert beginSheetModalForWindow:self.window modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertCreateSite];
    }];
}

#pragma mark - KVO

- (void)setElementSelectionIndexes:(NSIndexSet *)elementSelectionIndexes {

    // First reset bounds.
    PearlMainQueue(^{
        NSUInteger selectedIndex = self.elementSelectionIndexes.firstIndex;
        if (selectedIndex != NSNotFound && selectedIndex < self.elements.count)
            [[self selectedView].animator setBoundsOrigin:NSZeroPoint];
    } );

    _elementSelectionIndexes = elementSelectionIndexes;
}

- (void)insertObject:(MPElementModel *)model inElementsAtIndex:(NSUInteger)index {

    [self.elements insertObject:model atIndex:index];
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index {

    [self.elements removeObjectAtIndex:index];
}

@end
