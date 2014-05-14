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
//  MPPasswordLargeDeleteCell.h
//  MPPasswordLargeDeleteCell
//
//  Created by lhunath on 2014-03-19.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordLargeDeleteCell.h"

@implementation MPPasswordLargeDeleteCell

#pragma mark - Lifecycle

- (MPElementEntity *)saveContentTypeWithElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context {

    return element;
}

@end
