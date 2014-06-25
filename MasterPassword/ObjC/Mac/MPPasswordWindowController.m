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

#define MPAlertIncorrectMP  @"MPAlertIncorrectMP"
#define MPAlertCreateSite   @"MPAlertCreateSite"

@interface MPPasswordWindowController()

@property(nonatomic, copy) NSString *currentSiteText;
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
    [self.elementsController observeKeyPath:@"selection"
                                  withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [self updateSelection];
    }];

    NSSearchFieldCell *siteFieldCell = self.siteField.cell;
    siteFieldCell.searchButtonCell = nil;
    siteFieldCell.cancelButtonCell = nil;
}

#pragma mark - NSResponder

- (void)doCommandBySelector:(SEL)commandSelector {

    [self handleCommand:commandSelector];
}

#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor doCommandBySelector:(SEL)commandSelector {

    if (control == self.passwordField) {
        if (commandSelector == @selector( insertNewline: )) {
            NSString *password = self.passwordField.stringValue;
            [self.progressView startAnimation:self];
            [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
                MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:moc];
                NSString *userName = activeUser.name;
                BOOL success = [[MPMacAppDelegate get] signInAsUser:activeUser saveInContext:moc usingMasterPassword:password];

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.progressView stopAnimation:self];
                    if (!success)
                        [[NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                                NSLocalizedDescriptionKey : PearlString( @"Incorrect master password for user %@", userName )
                        }]] beginSheetModalForWindow:self.window modalDelegate:self
                                      didEndSelector:@selector( alertDidEnd:returnCode:contextInfo: ) contextInfo:MPAlertIncorrectMP];
                }];
            }];
            return YES;
        }
    }

    if (control == self.siteField) {
        if (commandSelector == @selector( moveUp: )) {
            [self.elementsController selectPrevious:self];
            return YES;
        }
        if (commandSelector == @selector( moveDown: )) {
            [self.elementsController selectNext:self];
            return YES;
        }
        if ([NSStringFromSelector( commandSelector ) rangeOfString:@"delete"].location == 0) {
            _skipTextChange = YES;
            return NO;
        }
    }

    return [self handleCommand:commandSelector];
}

- (IBAction)doSearchElements:(id)sender {

    [self updateElements];
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {

    return [self handleCommand:commandSelector];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {

    return (NSInteger)[self.elements count];
}

#pragma mark - NSAlert

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertIncorrectMP)
        return;
    if (contextInfo == MPAlertCreateSite) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn: {
                // "Create" button.
                [[MPMacAppDelegate get] addElementNamed:[self.siteField stringValue] completion:^(MPElementEntity *element) {
                    if (element)
                        [self updateElements];
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

#pragma mark - State

- (NSString *)query {

    return [self.siteField.stringValue stringByReplacingCharactersInRange:self.siteField.currentEditor.selectedRange withString:@""];
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

#pragma mark - Private

- (BOOL)handleCommand:(SEL)commandSelector {

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

- (void)updateUser {

    [MPMacAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
        self.passwordField.hidden = YES;
        self.siteField.hidden = YES;
        self.siteTable.hidden = YES;

        self.inputLabel.stringValue = @"";
        self.passwordField.stringValue = @"";
        self.siteField.stringValue = @"";

        MPUserEntity *mainActiveUser = [[MPMacAppDelegate get] activeUserInContext:mainContext];
        if (mainActiveUser) {
            if ([MPMacAppDelegate get].key) {
                self.inputLabel.stringValue = strf( @"%@'s password for:", mainActiveUser.name );
                self.siteField.hidden = NO;
                self.siteTable.hidden = NO;
                [self.siteField becomeFirstResponder];
            }
            else {
                self.inputLabel.stringValue = strf( @"Enter %@'s master password:", mainActiveUser.name );
                self.passwordField.hidden = NO;
                [self.passwordField becomeFirstResponder];
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

    NSRange siteNameQueryRange = [siteName rangeOfString:[self query]];
    self.siteField.stringValue = siteName;

    if (siteNameQueryRange.location == 0)
        self.siteField.currentEditor.selectedRange = NSMakeRange( siteNameQueryRange.length, siteName.length - siteNameQueryRange.length );
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
            notification.subtitle = PearlString( @"%@ at %@", selectedElement.loginName, selectedElement.siteName );
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

- (void)createNewSite:(NSString *)siteName {

    PearlMainQueue( ^{
        NSAlert *alert = [NSAlert new];
        [alert addButtonWithTitle:@"Create"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Create site?"];
        [alert setInformativeText:PearlString( @"Do you want to create a new site named:\n\n%@", siteName )];
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
    CGWindowID windowID = (CGWindowID)[self.window windowNumber];
    CGImageRef capturedImage = CGWindowListCreateImage( CGRectInfinite, kCGWindowListOptionOnScreenBelowWindow, windowID,
            kCGWindowImageBoundsIgnoreFraming );
    [profiler finishJob:@"captured window: %d, on screen: %@", windowID, self.window.screen];
    NSImage *screenImage = [[NSImage alloc] initWithCGImage:capturedImage size:NSMakeSize(
            CGImageGetWidth( capturedImage ) / self.window.backingScaleFactor,
            CGImageGetHeight( capturedImage ) / self.window.backingScaleFactor )];
    [profiler finishJob:@"image size: %@, bytes: %ld", NSStringFromSize( screenImage.size ), screenImage.TIFFRepresentation.length ];

    NSImage *smallImage = [[NSImage alloc] initWithSize:NSMakeSize(
            CGImageGetWidth( capturedImage ) / 20,
            CGImageGetHeight( capturedImage ) / 20 )];
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
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [[self.window animator] setAlphaValue:1.0];
    [profiler finishJob:@"animating window"];
}

- (void)fadeOut {

    if (![NSApp isActive] && !self.window.alphaValue)
        return;

    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [self close];
        [NSApp hide:self];
    }];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
    [[self.window animator] setAlphaValue:0.0];
}

@end
