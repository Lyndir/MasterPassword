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
//  MPAvatarCell.h
//  MPAvatarCell
//
//  Created by lhunath on 2014-03-11.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPPasswordCell

#pragma mark - Life cycle

- (void)prepareForReuse {

    [super prepareForReuse];
    [self updateAnimated:NO];
}

// Unblocks animations for all CALayer properties (eg. shadowOpacity)
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {

    id<CAAction> defaultAction = [super actionForLayer:layer forKey:event];
    if (defaultAction == (id)[NSNull null] && [event isEqualToString:@"position"])
        return defaultAction;

    return NSNullToNil(defaultAction);
}

#pragma mark - Properties

- (void)setSelected:(BOOL)selected {

    [super setSelected:selected];

    [self updateAnimated:YES];
}

- (void)setHighlighted:(BOOL)highlighted {

    [super setHighlighted:highlighted];

    [self updateAnimated:YES];
}

#pragma mark - Private

- (void)updateAnimated:(BOOL)animated {

    if (![NSThread isMainThread]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateAnimated:animated];
        }];
        return;
    }

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        self.layer.shadowOpacity = self.selected? 1: self.highlighted? 0.3f: 0;
    }];
}

@end
