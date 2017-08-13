//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPAlgorithmV3.h"
#import "MPEntities.h"

@implementation MPAlgorithmV3

- (MPAlgorithmVersion)version {

    return MPAlgorithmVersion3;
}

- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit {

    if ([site.algorithm version] != [self version] - 1)
        // Only migrate from previous version.
        return NO;

    if (!explicit) {
        if (site.type & MPResultTypeClassTemplate &&
            site.user.name.length != [site.user.name dataUsingEncoding:NSUTF8StringEncoding].length) {
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
