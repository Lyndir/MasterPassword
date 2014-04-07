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
//  MPPasswordSmallCell.h
//  MPPasswordSmallCell
//
//  Created by lhunath on 2014-03-28.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordElementCell.h"
#import "MPPasswordSmallCell.h"

@implementation MPPasswordSmallCell {
}

+ (instancetype)dequeueCellForElement:(MPElementEntity *)element fromCollectionView:(UICollectionView *)collectionView
                          atIndexPath:(NSIndexPath *)indexPath {

    NSString *reuseIdentifier;
    if (element.type & MPElementTypeClassGenerated)
        reuseIdentifier = NSStringFromClass( [MPPasswordSmallGeneratedCell class] );
    else if (element.type & MPElementTypeClassStored)
        reuseIdentifier = NSStringFromClass( [MPPasswordSmallStoredCell class] );
    else
        Throw(@"Unexpected password type: %@", [MPAlgorithmDefault nameOfType:element.type]);

    MPPasswordSmallCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    [cell setElement:element];

    return cell;
}

@end

@implementation MPPasswordSmallGeneratedCell
@end

@implementation MPPasswordSmallStoredCell
@end
