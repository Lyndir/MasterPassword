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

#import "MPPasswordWindowController.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPPasswordWindowController

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
        [self.siteField becomeFirstResponder];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowDidResignKeyNotification object:self.window
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
}

- (void)updateUser {

    [MPMacAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
        MPUserEntity *mainActiveUser = [[MPMacAppDelegate get] activeUserInContext:mainContext];
        if (mainActiveUser)
            self.userLabel.stringValue = strf( @"%@'s password for:", mainActiveUser.name );
        else
            self.userLabel.stringValue = @"";
    }];
}

#pragma mark - State

#pragma mark - Private

- (void)fadeIn {

    CGWindowID windowID = (CGWindowID)[self.window windowNumber];
    CGImageRef capturedImage = CGWindowListCreateImage( CGRectInfinite, kCGWindowListOptionOnScreenBelowWindow, windowID,
            kCGWindowImageBoundsIgnoreFraming );
    NSImage *screenImage = [[NSImage alloc] initWithCGImage:capturedImage size:NSMakeSize(
            CGImageGetWidth( capturedImage ) / self.window.backingScaleFactor,
            CGImageGetHeight( capturedImage ) / self.window.backingScaleFactor )];

    NSImage *smallImage = [[NSImage alloc] initWithSize:NSMakeSize(
            CGImageGetWidth( capturedImage ) / 20,
            CGImageGetHeight( capturedImage ) / 20 )];
    [smallImage lockFocus];
    [screenImage drawInRect:(NSRect){ .origin = CGPointZero, .size = smallImage.size, }
                   fromRect:NSZeroRect
                  operation:NSCompositeSourceOver
                   fraction:1.0];
    [smallImage unlockFocus];

    self.blurView.image = smallImage;

    [self.window setFrame:self.window.screen.frame display:YES];
    [[self.window animator] setAlphaValue:1.0];
}

- (void)fadeOut {

    [[self.window animator] setAlphaValue:0.0];
}

@end
