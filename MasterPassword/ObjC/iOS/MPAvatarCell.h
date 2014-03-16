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

#import <Foundation/Foundation.h>
#import "MPEntities.h"
@class MPAvatarCell;

/* Avatar with a "+" symbol. */
extern const long MPAvatarAdd;

typedef NS_ENUM(NSUInteger, MPAvatarMode) {
    MPAvatarModeLowered,
    MPAvatarModeRaisedButInactive,
    MPAvatarModeRaisedAndActive
};

@interface MPAvatarCell : UICollectionViewCell 
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) long avatar;
@property (assign, nonatomic) MPAvatarMode mode;
@property (assign, nonatomic) float visibility;

+ (NSString *)reuseIdentifier;

@end
