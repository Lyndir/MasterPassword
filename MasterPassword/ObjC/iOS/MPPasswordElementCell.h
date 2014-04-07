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
//  MPPasswordElementCell.h
//  MPPasswordElementCell
//
//  Created by lhunath on 2014-04-03.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPPasswordCell.h"

@interface MPPasswordElementCell : MPPasswordCell

@property(nonatomic, copy) NSString *transientSite;

- (MPElementEntity *)mainElement;
- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context;
- (void)setElement:(MPElementEntity *)element;
- (void)reloadData;

@end
