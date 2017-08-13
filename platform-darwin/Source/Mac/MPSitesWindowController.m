//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import <QuartzCore/QuartzCore.h>
#import "MPSitesWindowController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"

@interface MPSitesWindowController()

@property(nonatomic, strong) CAGradientLayer *siteGradient;

@end

@implementation MPSitesWindowController

#pragma mark - Life

- (void)windowDidLoad {

    prof_new( @"windowDidLoad" );
    [super windowDidLoad];
    prof_rewind( @"super" );

    [self replaceFonts:self.window.contentView];
    prof_rewind( @"replaceFonts" );

    PearlAddNotificationObserver( NSWindowDidBecomeKeyNotification, self.window, [NSOperationQueue mainQueue],
            ^(id host, NSNotification *note) {
                prof_new( @"didBecomeKey" );
                [self.window makeKeyAndOrderFront:nil];
                prof_rewind( @"fadeIn" );
                [self updateUser];
                prof_finish( @"updateUser" );
            } );
    PearlAddNotificationObserver( NSWindowWillCloseNotification, self.window, [NSOperationQueue mainQueue],
            ^(id host, NSNotification *note) {
                PearlRemoveNotificationObservers();

                NSWindow *sheet = [self.window attachedSheet];
                if (sheet)
                    [self.window endSheet:sheet];
            } );
    PearlAddNotificationObserver( NSApplicationWillResignActiveNotification, nil, [NSOperationQueue mainQueue],
            ^(id host, NSNotification *note) {
                [self.window close];
            } );
    PearlAddNotificationObserver( MPSignedInNotification, nil, [NSOperationQueue mainQueue], ^(id host, NSNotification *note) {
        [self updateUser];
    } );
    PearlAddNotificationObserver( MPSignedOutNotification, nil, [NSOperationQueue mainQueue], ^(id host, NSNotification *note) {
        [self updateUser];
    } );
    [self observeKeyPath:@"sitesController.selection" withBlock:^(id from, id to, NSKeyValueChange cause, id self) {
        [self updateSelection];
    }];
    prof_rewind( @"observers" );

    NSSearchFieldCell *siteFieldCell = self.siteField.cell;
    siteFieldCell.searchButtonCell = nil;
    siteFieldCell.cancelButtonCell = nil;

    self.siteGradient = [CAGradientLayer layer];
    self.siteGradient.colors = @[ (__bridge id)[NSColor whiteColor].CGColor, (__bridge id)[NSColor clearColor].CGColor ];
    self.siteGradient.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.siteGradient.frame = self.siteTable.bounds;
    self.siteTable.superview.superview.layer.mask = self.siteGradient;

    self.siteTable.controller = self;
    prof_finish( @"ui" );
}

- (void)replaceFonts:(NSView *)view {

    if (view.window.backingScaleFactor == 1)
        [view enumerateViews:^(NSView *subview, BOOL *stop, BOOL *recurse) {
            if ([subview respondsToSelector:@selector( setFont: )]) {
                NSFont *font = [(id)subview font];
                if ([font.fontName isEqualToString:@"HelveticaNeue-Thin"])
                    [(id)subview setFont:[NSFont fontWithName:@"HelveticaNeue" matrix:font.matrix]];
                if ([font.fontName isEqualToString:@"HelveticaNeue-Light"])
                    [(id)subview setFont:[NSFont fontWithName:@"HelveticaNeue" matrix:font.matrix]];
            }
        }            recurse:YES];
}

- (void)flagsChanged:(NSEvent *)theEvent {

    BOOL shiftPressed = (theEvent.modifierFlags & NSShiftKeyMask) != 0;
    if (shiftPressed != self.shiftPressed)
        self.shiftPressed = shiftPressed;

    BOOL alternatePressed = (theEvent.modifierFlags & NSAlternateKeyMask) != 0;
    if (alternatePressed != self.alternatePressed) {
        self.alternatePressed = alternatePressed;
        self.showVersionContainer = self.alternatePressed || self.selectedSite.outdated;
        [self.selectedSite updateContent];

        if (self.locked) {
            NSTextField *passwordField = self.securePasswordField;
            if (self.securePasswordField.isHidden)
                passwordField = self.revealPasswordField;
            [passwordField becomeFirstResponder];
            [[passwordField currentEditor] moveToEndOfLine:nil];
        }
    }

    [super flagsChanged:theEvent];
}

#pragma mark - NSResponder

// Handle any unhandled editor command.
- (void)doCommandBySelector:(SEL)commandSelector {

    [self handleCommand:commandSelector];
}

#pragma mark - NSTextFieldDelegate

// Editor command in a text field.
- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

    if (control == self.siteField) {
        if ([NSStringFromSelector( commandSelector ) rangeOfString:@"delete"].location == 0)
            return NO;
    }
    if (control == self.securePasswordField || control == self.revealPasswordField) {
        if (commandSelector == @selector( insertNewline: ))
            return NO;
    }

    return [self handleCommand:commandSelector];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {

    if (control == self.siteField)
        [fieldEditor replaceCharactersInRange:fieldEditor.selectedRange withString:@""];

    return YES;
}

- (IBAction)doUnlockUser:(id)sender {

    [self.progressView startAnimation:self];
    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:context];
        NSString *userName = activeUser.name;
        BOOL success = [[MPMacAppDelegate get] signInAsUser:activeUser saveInContext:context usingMasterPassword:self.masterPassword];

        PearlMainQueue( ^{
            self.masterPassword = nil;
            [self.progressView stopAnimation:self];
            if (!success)
                [[NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                        NSLocalizedDescriptionKey: strf( @"Incorrect master password for user %@", userName )
                }]] beginSheetModalForWindow:self.window completionHandler:nil];
        } );
    }];
}

- (IBAction)doSearchSites:(id)sender {

    [self updateSites];
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {

    return [self handleCommand:commandSelector];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {

    return (NSInteger)[self.sites count];
}

#pragma mark - NSTableViewDelegate

- (void)tableView:(NSTableView *)tableView didAddRowView:(NSTableRowView *)rowView forRow:(NSInteger)row {

    [self replaceFonts:rowView];
}

#pragma mark - State

- (void)insertObject:(MPSiteModel *)model inSitesAtIndex:(NSUInteger)index {

    [self.sites insertObject:model atIndex:index];
}

- (void)removeObjectFromSitesAtIndex:(NSUInteger)index {

    [self.sites removeObjectAtIndex:index];
}

- (MPSiteModel *)selectedSite {

    return [self.sitesController.selectedObjects firstObject];
}

#pragma mark - Actions

- (IBAction)settings:(id)sender {

    [self.window close];
    [[MPMacAppDelegate get] showPopup:sender];
}

- (IBAction)deleteSite:(id)sender {

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Delete Site?"];
    [alert setInformativeText:strf( @"Do you want to delete the site named:\n\n%@", self.selectedSite.name )];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Delete" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    [context deleteObject:[self.selectedSite entityInContext:context]];
                    [context saveToStore];
                }];
                break;
            }
            default:
                break;
        }
    }];
}

- (IBAction)changeLogin:(id)sender {

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Change Login Name"];
    [alert setInformativeText:strf( @"Your login name for: %@", self.selectedSite.name )];
    NSTextField *loginField = [NSTextField new];
    [loginField bind:@"value" toObject:self.selectedSite withKeyPath:@"loginName" options:nil];
    NSButton *generatedField = [NSButton new];
    [generatedField setButtonType:NSSwitchButton];
    [generatedField bind:@"value" toObject:self.selectedSite withKeyPath:@"loginGenerated" options:nil];
    generatedField.title = @"Generated";
    NSStackView *stackView = [NSStackView stackViewWithViews:@[ loginField, generatedField ]];
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.frame = NSMakeRect( 0, 0, 200, 44 );
    [stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[loginField(200)]"
                                                                      options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings( loginField, stackView )]];
    [stackView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[generatedField(200)]"
                                                                      options:0 metrics:nil
                                                                        views:NSDictionaryOfVariableBindings( generatedField, stackView )]];
    [alert setAccessoryView:stackView];
    [alert layout];
    [loginField selectText:self];

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Save" button.
                NSString *loginName = [loginField stringValue];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPSiteEntity *entity = [self.selectedSite entityInContext:context];
                    entity.loginName = !self.selectedSite.loginGenerated && [loginName length]? loginName: nil;
                    [context saveToStore];
                    [self.selectedSite updateContent];
                }];
                break;
            }
            default:
                break;
        }
    }];
}

- (IBAction)resetMasterPassword:(id)sender {

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Reset My Master Password"];
    [alert setInformativeText:strf( @"This will allow you to change %@'s master password.\n\n"
                    @"WARNING: All your site passwords will change.  Do this only if you've forgotten your "
                    @"master password and are fully prepared to change all your sites' passwords to the new ones.",
            [MPMacAppDelegate get].activeUserForMainThread.name )];

    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Reset" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:context];
                    NSString *activeUserName = activeUser.name;
                    activeUser.keyID = nil;
                    [[MPMacAppDelegate get] forgetSavedKeyFor:activeUser];
                    [context saveToStore];

                    PearlMainQueue( ^{
                        NSAlert *alert_ = [NSAlert new];
                        alert_.messageText = @"Master Password Reset";
                        alert_.informativeText = strf( @"%@'s master password has been reset.\n\nYou can now set a new one by logging in.",
                                activeUserName );
                        [alert_ beginSheetModalForWindow:self.window completionHandler:nil];

                        if ([MPMacAppDelegate get].key)
                            [[MPMacAppDelegate get] signOutAnimated:YES];
                    } );
                }];
            }
            default:
                break;
        }
    }];
}

- (IBAction)changePassword:(id)sender {

    if (!self.selectedSite.stored)
        return;

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Change Password"];
    [alert setInformativeText:strf( @"Enter the new password for: %@", self.selectedSite.name )];
    NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
    [alert setAccessoryView:passwordField];
    [alert layout];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Save" button.
                NSString *password = [passwordField stringValue];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPSiteEntity *entity = [self.selectedSite entityInContext:context];
                    [entity.algorithm savePassword:password toSite:entity usingKey:[MPMacAppDelegate get].key];
                    [context saveToStore];
                    [self.selectedSite updateContent];
                }];
                break;
            }
            default:
                break;
        }
    }];
}

- (IBAction)changeType:(id)sender {

    MPSiteModel *site = self.selectedSite;
    NSArray *types = [site.algorithm allTypes];
    [self.passwordTypesMatrix renewRows:(NSInteger)[types count] columns:1];
    for (NSUInteger t = 0; t < [types count]; ++t) {
        MPResultType type = (MPResultType)[types[t] unsignedIntegerValue];
        NSString *title = [site.algorithm nameOfType:type];
        if (type & MPResultTypeClassTemplate)
            title = strf( @"%@ – %@", [site.algorithm mpwTemplateForSiteNamed:site.name ofType:type withCounter:site.counter
                                                                     usingKey:[MPMacAppDelegate get].key], title );

        NSButtonCell *cell = [self.passwordTypesMatrix cellAtRow:(NSInteger)t column:0];
        cell.tag = type;
        cell.state = type == site.type? NSOnState: NSOffState;
        cell.title = title;
    }

    self.passwordTypesBox.title = strf( @"Choose a password type for %@:", site.name );

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Change Password Type"];
    [alert setAccessoryView:self.passwordTypesBox];
    [alert layout];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Save" button.
                MPResultType type = (MPResultType)[self.passwordTypesMatrix.selectedCell tag];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPSiteEntity *entity = [[MPMacAppDelegate get] changeSite:[self.selectedSite entityInContext:context]
                                                                saveInContext:context toType:type];
                    if ([entity isKindOfClass:[MPStoredSiteEntity class]] && ![(MPStoredSiteEntity *)entity contentObject].length)
                        PearlMainQueue( ^{
                            [self changePassword:nil];
                        } );
                }];
                break;
            }
            default:
                break;
        }
    }];
}

- (IBAction)securityQuestions:(id)sender {

    MPSiteModel *site = self.selectedSite;
    self.securityQuestionsBox.title = strf( @"Answer to security questions for %@:", site.name );

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Copy Answer"];
    [alert addButtonWithTitle:@"Close"];
    [alert setMessageText:@"Security Questions"];
    [alert setAccessoryView:self.securityQuestionsBox];
    [alert layout];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Copy Answer" button.
                [self copyContent:self.securityAnswerField.stringValue];
                [self.window close];
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark - Private

- (BOOL)handleCommand:(SEL)commandSelector {

    if (commandSelector == @selector( moveUp: )) {
        [self.sitesController selectPrevious:self];
        return YES;
    }
    if (commandSelector == @selector( moveDown: )) {
        [self.sitesController selectNext:self];
        return YES;
    }
    if (commandSelector == @selector( insertNewline: )) {
        [self useSite];
        return YES;
    }
    if (commandSelector == @selector( cancel: ) || commandSelector == @selector( cancelOperation: )) {
        [self.window close];
        return YES;
    }

    return NO;
}

- (void)useSite {

    MPSiteModel *selectedSite = [self selectedSite];
    if (!selectedSite)
        return;

    if (selectedSite.transient) {
        [self createNewSite:selectedSite.name];
        return;
    }

    // Performing action while content is available.  Copy it.
    [self copyContent:self.shiftPressed? selectedSite.answer: selectedSite.content];
    [NSApp hide:nil];

    NSUserNotification *notification = [NSUserNotification new];
    notification.title = @"Password Copied";
    if (selectedSite.loginName.length)
        notification.subtitle = strf( @"%@ at %@", selectedSite.loginName, selectedSite.name );
    else
        notification.subtitle = selectedSite.name;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)updateUser {

    [MPMacAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
        self.locked = YES;
        self.newUser = YES;

        self.inputLabel.stringValue = @"";
        self.siteField.stringValue = @"";

        MPUserEntity *mainActiveUser = [[MPMacAppDelegate get] activeUserInContext:mainContext];
        if (mainActiveUser) {
            self.newUser = mainActiveUser.keyID == nil;

            if ([MPMacAppDelegate get].key) {
                self.inputLabel.stringValue = strf( @"%@'s password for:", mainActiveUser.name );
                self.locked = NO;
                [self.siteField becomeFirstResponder];
            }
            else {
                self.inputLabel.stringValue = strf( @"Enter %@'s master password:", mainActiveUser.name );
                NSTextField *passwordField = self.securePasswordField;
                if (self.securePasswordField.isHidden)
                    passwordField = self.revealPasswordField;
                [passwordField becomeFirstResponder];
            }
        }

        [self updateSites];
    }];
}

- (void)updateSites {

    NSAssert( [NSOperationQueue currentQueue] == [NSOperationQueue mainQueue], @"updateSites should be called on the main queue." );
    if (![MPMacAppDelegate get].key) {
        self.sites = nil;
        return;
    }

    static NSRegularExpression *fuzzyRE;
    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        fuzzyRE = [NSRegularExpression regularExpressionWithPattern:@"(.)" options:0 error:nil];
    } );

    prof_new( @"updateSites" );
    NSString *queryString = self.siteField.stringValue;
    NSString *queryPattern = [[queryString stringByReplacingMatchesOfExpression:fuzzyRE withTemplate:@"*$1"] stringByAppendingString:@"*"];
    prof_rewind( @"queryPattern" );
    NSMutableArray *fuzzyGroups = [NSMutableArray new];
    [fuzzyRE enumerateMatchesInString:queryString options:0 range:NSMakeRange( 0, queryString.length )
                           usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                               [fuzzyGroups addObject:[queryString substringWithRange:result.range]];
                           }];
    prof_rewind( @"fuzzyRE" );
    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        prof_rewind( @"moc" );

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
        fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO] ];
        fetchRequest.predicate =
                [NSPredicate predicateWithFormat:@"name LIKE[cd] %@ AND user == %@", queryPattern, [MPMacAppDelegate get].activeUserOID];
        prof_rewind( @"fetchRequest" );

        NSError *error = nil;
        NSArray *siteResults = [context executeFetchRequest:fetchRequest error:&error];
        if (!siteResults) {
            prof_finish( @"executeFetchRequest: %@ // %@", fetchRequest.predicate, [error fullDescription] );
            MPError( error, @"While fetching sites for completion." );
            return;
        }
        prof_rewind( @"executeFetchRequest: %@", fetchRequest.predicate );

        BOOL exact = NO;
        NSMutableArray *newSites = [NSMutableArray arrayWithCapacity:[siteResults count]];
        for (MPSiteEntity *site in siteResults) {
            [newSites addObject:[[MPSiteModel alloc] initWithEntity:site fuzzyGroups:fuzzyGroups]];
            exact |= [site.name isEqualToString:queryString];
        }
        prof_rewind( @"newSites: %u, exact: %d", (uint)[siteResults count], exact );
        if (!exact && [queryString length]) {
            MPUserEntity *activeUser = [[MPAppDelegate_Shared get] activeUserInContext:context];
            [newSites addObject:[[MPSiteModel alloc] initWithName:queryString forUser:activeUser]];
        }
        prof_finish( @"newSites: %@", newSites );

        dbg( @"newSites: %@", newSites );
        if (![newSites isEqualToArray:self.sites])
            PearlMainQueue( ^{
                self.sites = newSites;
            } );
    }];
}

- (void)updateSelection {

    [self.siteTable scrollRowToVisible:(NSInteger)self.sitesController.selectionIndex];

    NSView *siteScrollView = self.siteTable.superview.superview;
    NSRect selectedCellFrame = [self.siteTable frameOfCellAtColumn:0 row:((NSInteger)self.sitesController.selectionIndex)];
    CGFloat selectedOffset = [siteScrollView convertPoint:selectedCellFrame.origin fromView:self.siteTable].y;
    CGFloat gradientOpacity = selectedOffset / siteScrollView.bounds.size.height;
    self.siteGradient.colors = @[
            (__bridge id)[NSColor whiteColor].CGColor,
            (__bridge id)[NSColor colorWithDeviceWhite:1 alpha:1 - (1 - gradientOpacity) * 4 / 5].CGColor,
            (__bridge id)[NSColor colorWithDeviceWhite:1 alpha:gradientOpacity].CGColor
    ];

    self.showVersionContainer = self.alternatePressed || self.selectedSite.outdated;
    [self.sitePasswordTipField setAttributedStringValue:straf( @"Your password for %@:", self.selectedSite.displayedName )];
}

- (void)createNewSite:(NSString *)siteName {

    PearlMainQueue( ^{
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"Create"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Create site?"];
        [alert setInformativeText:strf( @"Do you want to create a new site named:\n\n%@", siteName )];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn: {
                    // "Create" button.
                    [[MPMacAppDelegate get] addSiteNamed:[self.siteField stringValue] completion:
                            ^(MPSiteEntity *site, NSManagedObjectContext *context) {
                                if (site)
                                    PearlMainQueue( ^{ [self updateSites]; } );
                            }];
                    break;
                }
                default:
                    break;
            }
        }];
    } );
}

- (void)copyContent:(NSString *)content {

    [[NSPasteboard generalPasteboard] declareTypes:@[ NSStringPboardType ] owner:nil];
    if (![[NSPasteboard generalPasteboard] setString:content forType:NSPasteboardTypeString]) {
        wrn( @"Couldn't copy password to pasteboard." );
        return;
    }

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        [[self.selectedSite entityInContext:context] use];
        [context saveToStore];
    }];
}

@end
