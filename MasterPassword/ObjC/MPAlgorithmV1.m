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
//  MPAlgorithmV1
//
//  Created by Maarten Billemont on 17/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAlgorithmV1.h"
#import "MPEntities.h"

@implementation MPAlgorithmV1

- (MPAlgorithmVersion)version {

    return MPAlgorithmVersion1;
}

- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit {

    if ([site.algorithm version] != [self version] - 1)
        // Only migrate from previous version.
        return NO;

    if (!explicit) {
        if (site.type & MPSiteTypeClassGenerated) {
            // This migration requires explicit permission for types of the generated class.
            site.requiresExplicitMigration = YES;
            return NO;
        }
    }

    // Apply migration.
    site.requiresExplicitMigration = NO;
    site.algorithm = self;
    return YES;
}

@end
