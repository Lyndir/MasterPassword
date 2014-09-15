/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPPasswordWindowController.h
//  MPPasswordWindowController
//
//  Created by lhunath on 2014-06-18.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MPPasswordWindowController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPElementModel.h"
#import "MPAppDelegate_Key.h"
#import "PearlProfiler.h"

#define MPAlertIncorrectMP      @"MPAlertIncorrectMP"
#define MPAlertChangeMP         @"MPAlertChangeMP"
#define MPAlertCreateSite       @"MPAlertCreateSite"
#define MPAlertChangeType       @"MPAlertChangeType"
#define MPAlertChangeLogin      @"MPAlertChangeLogin"
#define MPAlertChangeContent    @"MPAlertChangeContent"
#define MPAlertDeleteSite       @"MPAlertDeleteSite"

@interface MPPasswordWindowController()

@property(nonatomic, copy) NSString *currentSiteText;
@property(nonatomic, strong) CAGradientLayer *siteGradient;
@end

@implementation MPPasswordWindowController { BOOL _skipTextChange; }

#pragma mark - Life

- (void)windowDidLoad {

    [super windowDidLoad];

//    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillBecomeActiveNotification object:nil
//                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//        [self fadeIn];
//    }];
//    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillResignActiveNotification object:nil
//                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//        [self fadeOut];
//    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidBecomeKeyNotification object:self.window
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self fadeIn];
        [self updateUser];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSWindow *sheet = [self.window attachedSheet];
        if (sheet)
            [NSApp endSheet:sheet];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillResignActiveNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self fadeOut];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedInNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updateUser];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPSignedOutNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updateUser];
    }];
    [self observeKeyPath:@"elementsController.selection"
               withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self updateSelection];
    }];

    NSSearchFieldCell *siteFieldCell = self.siteField.cell;
    siteFieldCell.searchButtonCell = nil;
    siteFieldCell.cancelButtonCell = nil;

    self.siteGradient = [CAGradientLayer layer];
    self.siteGradient.colors = @[ (__bridge id)[NSColor whiteColor].CGColor, (__bridge id)[NSColor clearColor].CGColor ];
    self.siteGradient.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.siteGradient.frame = self.siteTable.bounds;
    self.siteTable.superview.superview.layer.mask = self.siteGradient;

    self.siteTable.controller = self;
}

- (void)flagsChanged:(NSEvent *)theEvent {

    BOOL alternatePressed = (theEvent.modifierFlags & NSAlternateKeyMask) != 0;
    if (alternatePressed != self.alternatePressed) {
        self.alternatePressed = alternatePressed;
        [self.selectedElement updateContent];

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

- (void)doCommandBySelector:(SEL)commandSelector {

    dbg( @"doCommandBySelector: %@", NSStringFromSelector( commandSelector ) );
    [self handleCommand:commandSelector];
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

    dbg( @"@control:%@ textView:%@ doCommandBySelector:%@", control, fieldEditor, NSStringFromSelector( commandSelector ) );
    if (control == self.siteField) {
        if ([NSStringFromSelector( commandSelector ) rangeOfString:@"delete"].location == 0) {
            _skipTextChange = YES;
            return NO;
        }
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
    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:moc];
        NSString *userName = activeUser.name;
        BOOL success = [[MPMacAppDelegate get] signInAsUser:activeUser saveInContext:moc usingMasterPassword:self.masterPassword];

        PearlMainQueue( ^{
            self.masterPassword = nil;
            [self.progressView stopAnimation:self];
            if (!success)
                [[NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                        NSLocalizedDescriptionKey : strf( @"Incorrect master password for user %@", userName )
                }]] beginSheetModalForWindow:self.window modalDelegate:self
                              didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertIncorrectMP];
        } );
    }];
}

- (IBAction)doSearchElements:(id)sender {

    [self updateElements];
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {

    dbg( @"textView:%@doCommandBySelector:%@", textView, NSStringFromSelector( commandSelector ) );
    return [self handleCommand:commandSelector];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {

    return (NSInteger)[self.elements count];
}

#pragma mark - NSTableViewDelegate

#pragma mark - NSAlert

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertIncorrectMP)
        return;
    if (contextInfo == MPAlertChangeMP) {
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
                        [alert_ beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:NULL contextInfo:nil];

                        if ([MPMacAppDelegate get].key)
                            [[MPMacAppDelegate get] signOutAnimated:YES];
                    } );
                }];
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
                [[MPMacAppDelegate get] addElementNamed:[self.siteField stringValue] completion:^(MPElementEntity *element, NSManagedObjectContext *context) {
                    if (element)
                        PearlMainQueue( ^{ [self updateElements]; } );
                }];
                break;
            }
            default:
                break;
        }
    }
    if (contextInfo == MPAlertChangeType) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Save" button.
                MPElementType type = (MPElementType)[self.passwordTypesMatrix.selectedCell tag];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *entity = [[MPMacAppDelegate get] changeElement:[self.selectedElement entityInContext:context]
                                                                      saveInContext:context toType:type];
                    if ([entity isKindOfClass:[MPElementStoredEntity class]] && ![(MPElementStoredEntity *)entity contentObject].length)
                        PearlMainQueue( ^{
                            [self changePassword:nil];
                        } );
                }];
                break;
            }
            default:
                break;
        }
    }
    if (contextInfo == MPAlertChangeLogin) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Save" button.
                NSString *loginName = [(NSSecureTextField *)alert.accessoryView stringValue];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *entity = [self.selectedElement entityInContext:context];
                    entity.loginName = loginName;
                    [context saveToStore];
                }];
                break;
            }
            default:
                break;
        }
    }
    if (contextInfo == MPAlertChangeContent) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Save" button.
                NSString *password = [(NSSecureTextField *)alert.accessoryView stringValue];
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *entity = [self.selectedElement entityInContext:context];
                    [entity.algorithm savePassword:password toElement:entity usingKey:[MPMacAppDelegate get].key];
                    [context saveToStore];
                }];
                break;
            }
            default:
                break;
        }
    }
    if (contextInfo == MPAlertDeleteSite) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Delete" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    [context deleteObject:[self.selectedElement entityInContext:context]];
                    [context saveToStore];
                }];
                break;
            }
            default:
                break;
        }
    }
}

#pragma mark - State

- (NSString *)query {

    return [self.siteField.stringValue stringByReplacingCharactersInRange:self.siteField.currentEditor.selectedRange withString:@""]?: @"";
}

- (void)insertObject:(MPElementModel *)model inElementsAtIndex:(NSUInteger)index {

    [self.elements insertObject:model atIndex:index];
}

- (void)removeObjectFromElementsAtIndex:(NSUInteger)index {

    [self.elements removeObjectAtIndex:index];
}

- (MPElementModel *)selectedElement {

    return [self.elementsController.selectedObjects firstObject];
}

#pragma mark - Actions

- (IBAction)settings:(id)sender {

    [self fadeOut:NO];
    [[MPMacAppDelegate get] showPopup:sender];
}

- (IBAction)deleteElement:(id)sender {

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Delete Site?"];
    [alert setInformativeText:strf( @"Do you want to delete the site named:\n\n%@", self.selectedElement.siteName )];
    [alert beginSheetModalForWindow:self.window modalDelegate:self
                     didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertDeleteSite];
}

- (IBAction)changeLogin:(id)sender {

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Change Login Name"];
    [alert setInformativeText:strf( @"Enter the login name for: %@", self.selectedElement.siteName )];
    NSTextField *loginField = [[NSTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
    loginField.stringValue = self.selectedElement.loginName?: @"";
    [loginField selectText:self];
    [alert setAccessoryView:loginField];
    [alert layout];
    [alert beginSheetModalForWindow:self.window modalDelegate:self
                     didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertChangeLogin];
}

- (IBAction)resetMasterPassword:(id)sender {

    MPUserEntity *activeUser = [MPMacAppDelegate get].activeUserForMainThread;

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Reset My Master Password"];
    [alert setInformativeText:strf( @"This will allow you to change %@'s master password.\n\n"
            @"WARNING: All your site passwords will change.  Do this only if you've forgotten your "
            @"master password and are fully prepared to change all your sites' passwords to the new ones.", activeUser.name )];
    [alert beginSheetModalForWindow:self.window modalDelegate:self
                     didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertChangeMP];
}

- (IBAction)changePassword:(id)sender {

    if (!self.selectedElement.stored)
        return;

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Change Password"];
    [alert setInformativeText:strf( @"Enter the new password for: %@", self.selectedElement.siteName )];
    [alert setAccessoryView:[[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )]];
    [alert layout];
    [alert beginSheetModalForWindow:self.window modalDelegate:self
                     didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertChangeContent];
}

- (IBAction)changeType:(id)sender {

    MPElementModel *element = self.selectedElement;
    NSArray *types = [element.algorithm allTypesStartingWith:MPElementTypeGeneratedPIN];
    [self.passwordTypesMatrix renewRows:(NSInteger)[types count] columns:1];
    for (NSUInteger t = 0; t < [types count]; ++t) {
        MPElementType type = [types[t] unsignedIntegerValue];
        NSString *title = [element.algorithm nameOfType:type];
        if (type & MPElementTypeClassGenerated)
            title = [element.algorithm generatePasswordForSiteNamed:element.siteName ofType:type
                                                        withCounter:element.counter usingKey:[MPMacAppDelegate get].key];

        NSButtonCell *cell = [self.passwordTypesMatrix cellAtRow:(NSInteger)t column:0];
        cell.tag = type;
        cell.state = type == element.type? NSOnState: NSOffState;
        cell.title = title;
    }

    NSAlert *alert = [NSAlert new];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Change Password Type"];
    [alert setInformativeText:strf( @"Choose a new password type for: %@", element.siteName )];
    [alert setAccessoryView:self.passwordTypesBox];
    [alert layout];
    [alert beginSheetModalForWindow:self.window modalDelegate:self
                     didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertChangeType];
}

#pragma mark - Private

- (BOOL)handleCommand:(SEL)commandSelector {

    if (commandSelector == @selector( moveUp: )) {
        [self.elementsController selectPrevious:self];
        return YES;
    }
    if (commandSelector == @selector( moveDown: )) {
        [self.elementsController selectNext:self];
        return YES;
    }
    if (commandSelector == @selector( insertNewline: )) {
        [self useSite];
        return YES;
    }
    if (commandSelector == @selector( cancel: ) || commandSelector == @selector( cancelOperation: )) {
        [self fadeOut];
        return YES;
    }

    return NO;
}

- (void)useSite {

    MPElementModel *selectedElement = [self selectedElement];
    if (selectedElement) {
        // Performing action while content is available.  Copy it.
        [self copyContent:selectedElement.content];

        [self fadeOut];

        NSUserNotification *notification = [NSUserNotification new];
        notification.title = @"Password Copied";
        if (selectedElement.loginName.length)
            notification.subtitle = strf( @"%@ at %@", selectedElement.loginName, selectedElement.siteName );
        else
            notification.subtitle = selectedElement.siteName;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else {
        NSString *siteName = [self.siteField stringValue];
        if ([siteName length])
            // Performing action without content but a site name is written.
            [self createNewSite:siteName];
    }
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

        [self updateElements];
    }];
}

- (void)updateElements {

    if (![MPMacAppDelegate get].key) {
        self.elements = nil;
        return;
    }

    PearlProfiler *profiler = [PearlProfiler profilerForTask:@"updateElements"];
    NSString *query = [self query];
    [profiler finishJob:@"query"];
    [MPMacAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
        fetchRequest.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastUsed" ascending:NO]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(%@ == '' OR name BEGINSWITH[cd] %@) AND user == %@",
                                                                  query, query, [[MPMacAppDelegate get] activeUserInContext:context]];
        [profiler finishJob:@"setup fetch"];

        NSError *error = nil;
        NSArray *siteResults = [context executeFetchRequest:fetchRequest error:&error];
        if (!siteResults) {
            err( @"While fetching elements for completion: %@", error );
            return;
        }
        [profiler finishJob:@"do fetch"];

        NSMutableArray *newElements = [NSMutableArray arrayWithCapacity:[siteResults count]];
        for (MPElementEntity *element in siteResults)
            [newElements addObject:[[MPElementModel alloc] initWithEntity:element]];
        [profiler finishJob:@"make models"];
        self.elements = newElements;
        [profiler finishJob:@"update elements"];
    }];
    [profiler finishJob:@"done"];
}

- (void)updateSelection {

    if (_skipTextChange) {
        _skipTextChange = NO;
        return;
    }

    NSString *siteName = self.selectedElement.siteName;
    if (!siteName)
        return;

    if ([self.window isKeyWindow] && [self.siteField isEqual:[self.window firstResponder]]) {
        NSRange siteNameQueryRange = [siteName rangeOfString:[self query]];
        self.siteField.stringValue = siteName;

        if (siteNameQueryRange.location == 0)
            self.siteField.currentEditor.selectedRange =
                    NSMakeRange( siteNameQueryRange.length, siteName.length - siteNameQueryRange.length );
    }

    [self.siteTable scrollRowToVisible:(NSInteger)self.elementsController.selectionIndex];
    [self updateGradient];
}

- (void)updateGradient {

    NSView *siteScrollView = self.siteTable.superview.superview;
    NSRect selectedCellFrame = [self.siteTable frameOfCellAtColumn:0 row:((NSInteger)self.elementsController.selectionIndex)];
    CGFloat selectedOffset = [siteScrollView convertPoint:selectedCellFrame.origin fromView:self.siteTable].y;
    CGFloat gradientOpacity = selectedOffset / siteScrollView.bounds.size.height;
    self.siteGradient.colors = @[
            (__bridge id)[NSColor whiteColor].CGColor,
            (__bridge id)[NSColor colorWithDeviceWhite:1 alpha:gradientOpacity].CGColor
    ];
}

- (void)createNewSite:(NSString *)siteName {

    PearlMainQueue( ^{
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"Create"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Create site?"];
        [alert setInformativeText:strf( @"Do you want to create a new site named:\n\n%@", siteName )];
        [alert beginSheetModalForWindow:self.window modalDelegate:self
                         didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertCreateSite];
    } );
}

- (void)copyContent:(NSString *)content {

    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    if (![[NSPasteboard generalPasteboard] setString:content forType:NSPasteboardTypeString]) {
        wrn( @"Couldn't copy password to pasteboard." );
        return;
    }

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        [[self.selectedElement entityInContext:moc] use];
        [moc saveToStore];
    }];
}

- (void)fadeIn {

    if ([self.window isOnActiveSpace] && self.window.alphaValue)
        return;

    PearlProfiler *profiler = [PearlProfiler profilerForTask:@"fadeIn"];
    CGDirectDisplayID displayID = [self.window.screen.deviceDescription[@"NSScreenNumber"] unsignedIntValue];
    CGImageRef capturedImage = CGDisplayCreateImage( displayID );
    if (!capturedImage || CGImageGetWidth( capturedImage ) <= 1) {
        wrn( @"Failed to capture screen image for display: %d", displayID );
        return;
    }

    [profiler finishJob:@"captured window: %d, on screen: %@", displayID, self.window.screen.deviceDescription];
    NSImage *screenImage = [[NSImage alloc] initWithCGImage:capturedImage size:NSMakeSize(
            CGImageGetWidth( capturedImage ) / self.window.backingScaleFactor,
            CGImageGetHeight( capturedImage ) / self.window.backingScaleFactor )];
    [profiler finishJob:@"image size: %@, bytes: %ld", NSStringFromSize( screenImage.size ), screenImage.TIFFRepresentation.length];

    NSImage *smallImage = [[NSImage alloc] initWithSize:NSMakeSize(
            CGImageGetWidth( capturedImage ) / 20,
            CGImageGetHeight( capturedImage ) / 20 )];
    CFRelease( capturedImage );
    [smallImage lockFocus];
    [screenImage drawInRect:(NSRect){ .origin = CGPointZero, .size = smallImage.size, }
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1.0];
    [smallImage unlockFocus];
    [profiler finishJob:@"small image size: %@, bytes: %ld", NSStringFromSize( screenImage.size ), screenImage.TIFFRepresentation.length];

    self.blurView.image = smallImage;
    [profiler finishJob:@"assigned image"];

    [self.window setFrame:self.window.screen.frame display:YES];
    [profiler finishJob:@"assigned frame"];
    [NSAnimationContext currentContext].timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    self.window.animator.alphaValue = 1.0;
    [profiler finishJob:@"animating window"];
}

- (void)fadeOut {

    [self fadeOut:YES];
}

- (void)fadeOut:(BOOL)hide {

    if (![NSApp isActive] && !self.window.alphaValue)
        return;

    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [self close];

        if (hide)
            [NSApp hide:self];
    }];
    [NSAnimationContext currentContext].timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [self.window animator].alphaValue = 0.0;
}

@end
