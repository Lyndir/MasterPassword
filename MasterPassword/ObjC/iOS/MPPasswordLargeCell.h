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
#import "MPPasswordCell.h"

typedef NS_ENUM (NSUInteger, MPContentFieldMode) {
    MPContentFieldModePassword,
    MPContentFieldModeUser,
};

@interface MPPasswordLargeCell : MPPasswordCell <UITextFieldDelegate>

@property(nonatomic) MPElementType type;
@property(nonatomic) MPContentFieldMode contentFieldMode;
@property(nonatomic, strong) IBOutlet UILabel *typeLabel;
@property(nonatomic, strong) IBOutlet UITextField *contentField;
@property(nonatomic, strong) IBOutlet UIButton *upgradeButton;

+ (instancetype)dequeueCellWithType:(MPElementType)type fromCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;

- (void)resolveContentOfCellTypeForTransientSite:(NSString *)siteName usingKey:(MPKey *)key result:(void (^)(NSString *))resultBlock;
- (void)resolveContentOfCellTypeForElement:(MPElementEntity *)element usingKey:(MPKey *)key result:(void (^)(NSString *))resultBlock;

- (MPElementEntity *)saveContentTypeWithElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context;

@end
