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
#import "MPCell.h"

typedef NS_ENUM ( NSUInteger, MPPasswordCellMode ) {
    MPPasswordCellModePassword,
    MPPasswordCellModeSettings,
};

@interface MPPasswordCell : MPCell <UIScrollViewDelegate, UITextFieldDelegate>

- (void)setElement:(MPElementEntity *)element animated:(BOOL)animated;
- (void)setTransientSite:(NSString *)siteName animated:(BOOL)animated;
- (void)setMode:(MPPasswordCellMode)mode animated:(BOOL)animated;

@end
