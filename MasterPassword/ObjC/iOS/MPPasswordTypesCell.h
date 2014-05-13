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
//  MPPasswordTypesCell.h
//  MPPasswordTypesCell
//
//  Created by lhunath on 2014-03-27.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPCell.h"
#import "MPPasswordCell.h"
#import "MPPasswordElementCell.h"
#import "MPPasswordsViewController.h"

@interface MPPasswordTypesCell : MPPasswordElementCell <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(nonatomic, strong) IBOutlet UICollectionView *contentCollectionView;
@property(nonatomic, strong) id<MPAlgorithm> algorithm;

@property(nonatomic) MPElementType activeType;
+ (instancetype)dequeueCellForElement:(MPElementEntity *)element
                   fromCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)dequeueCellForTransientSite:(NSString *)siteName
                   fromCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;

@end
