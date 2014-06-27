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

- (void)awakeFromNib {

    [super awakeFromNib];

    self.opaque = NO;
    self.backgroundColor = [NSColor clearColor];
    self.level = NSScreenSaverWindowLevel;
    self.alphaValue = 0;
}

- (BOOL)canBecomeKeyWindow {

    return YES;
}

#pragma mark - State

#pragma mark - Private

@end
