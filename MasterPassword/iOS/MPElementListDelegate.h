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
//  MPElementListDelegate
//
//  Created by Maarten Billemont on 2013-01-31.
//  Copyright 2013 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPElementEntity.h"

@protocol MPElementListDelegate <NSObject>

- (void)didSelectElement:(MPElementEntity *)element;

@end
