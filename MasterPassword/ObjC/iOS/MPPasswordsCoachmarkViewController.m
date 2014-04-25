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
//  MPPasswordsCoachmarkViewController.h
//  MPPasswordsCoachmarkViewController
//
//  Created by lhunath on 2014-04-23.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordsCoachmarkViewController.h"
#import "MPPasswordLargeGeneratedCell.h"
#import "MPPasswordLargeStoredCell.h"

@implementation MPPasswordsCoachmarkViewController

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.item == 0) {
        MPPasswordLargeGeneratedCell *cell = [MPPasswordLargeGeneratedCell dequeueCellWithType:MPElementTypeGeneratedLong
                                                                            fromCollectionView:collectionView atIndexPath:indexPath];
        [cell reloadWithTransientSite:@"apple.com"];

        return cell;
    }
    else if (indexPath.item == 1) {
        MPPasswordLargeStoredCell *cell = [MPPasswordLargeStoredCell dequeueCellWithType:MPElementTypeStoredPersonal
                                                                      fromCollectionView:collectionView atIndexPath:indexPath];
        [cell reloadWithTransientSite:@"gmail.com"];
        [cell.contentField setText:@"PaS$w0rD"];

        return cell;
    }

    Throw(@"Unexpected item for indexPath: %@", indexPath);
}

@end
