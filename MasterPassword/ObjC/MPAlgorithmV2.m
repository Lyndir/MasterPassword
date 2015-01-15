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
//  MPAlgorithmV2
//
//  Created by Maarten Billemont on 17/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import <objc/runtime.h>
#import "MPAlgorithmV2.h"
#import "MPEntities.h"

@implementation MPAlgorithmV2

- (MPAlgorithmVersion)version {

    return MPAlgorithmVersion2;
}

- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit {

    if (site.version != [self version] - 1)
        // Only migrate from previous version.
        return NO;

    if (!explicit) {
        if (site.type & MPSiteTypeClassGenerated && site.name.length != [site.name dataUsingEncoding:NSUTF8StringEncoding].length) {
            // This migration requires explicit permission for types of the generated class.
            site.requiresExplicitMigration = YES;
            return NO;
        }
    }

    // Apply migration.
    site.requiresExplicitMigration = NO;
    site.version = [self version];
    return YES;
}

@end
