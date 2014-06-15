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
#import "MPPasswordsViewController.h"
#import "MPPasswordLargeCell.h"

@interface MPPasswordTypesCell : MPPasswordCell <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(nonatomic, strong) IBOutlet UICollectionView *contentCollectionView;

@property(nonatomic, weak) MPPasswordsViewController *passwordsViewController;
@property(nonatomic, copy) NSString *transientSite;

@property(nonatomic, strong) id<MPAlgorithm> algorithm;
@property(nonatomic) MPElementType activeType;

- (MPElementEntity *)mainElement;
- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context;
- (void)setElement:(MPElementEntity *)element;
- (void)reloadData;
- (void)reloadData:(MPPasswordLargeCell *)cell;

+ (instancetype)dequeueCellForElement:(MPElementEntity *)element
                   fromCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)dequeueCellForTransientSite:(NSString *)siteName
                   fromCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;

@end
