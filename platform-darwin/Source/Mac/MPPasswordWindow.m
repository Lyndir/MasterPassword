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
//  MPPasswordWindow.h
//  MPPasswordWindow
//
//  Created by lhunath on 2014-06-19.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordWindow.h"

@implementation MPPasswordWindow

#pragma mark - Life

- (BOOL)canBecomeKeyWindow {

    return YES;
}

#pragma mark - State

- (void)update {

    if ([[MPMacConfig get].fullScreen boolValue]) {
        [self setLevel:NSScreenSaverWindowLevel];
        [self setFrame:self.screen.frame display:YES];
    }
    else if (self.level != NSNormalWindowLevel) {
        [self setLevel:NSNormalWindowLevel];
        [self setFrame:NSMakeRect( 0, 0, 640, 600 ) display:NO];
        [self center];
    }

    [super update];
}

#pragma mark - Private

@end
