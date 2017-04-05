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

#import "MPAlgorithm.h"

id<MPAlgorithm> MPAlgorithmForVersion(MPAlgorithmVersion version) {

    static NSMutableDictionary *versionToAlgorithm = nil;
    if (!versionToAlgorithm)
        versionToAlgorithm = [NSMutableDictionary dictionary];

    id<MPAlgorithm> algorithm = versionToAlgorithm[@(version)];
    if (!algorithm && (algorithm = (id<MPAlgorithm>)[NSClassFromString( strf( @"MPAlgorithmV%lu", (unsigned long)version ) ) new]))
        versionToAlgorithm[@(version)] = algorithm;

    return algorithm;
}

id<MPAlgorithm> MPAlgorithmDefaultForBundleVersion(NSString *bundleVersion) {

    if (PearlCFBundleVersionCompare( bundleVersion, @"1.3" ) == NSOrderedAscending)
        // Pre-1.3
        return MPAlgorithmForVersion( 0 );
    if (PearlCFBundleVersionCompare( bundleVersion, @"2.1" ) == NSOrderedAscending)
        // Pre-2.1
        return MPAlgorithmForVersion( 1 );

    return MPAlgorithmDefault;
}

NSString *NSStringFromTimeToCrack(TimeToCrack timeToCrack) {

    if (timeToCrack.universes > 1)
        return strl( @"> age of the universe" );
    else if (timeToCrack.years > 1)
        return strl( @"%d years", timeToCrack.years );
    else if (timeToCrack.months > 1)
        return strl( @"%d months", timeToCrack.months );
    else if (timeToCrack.weeks > 1)
        return strl( @"%d weeks", timeToCrack.weeks );
    else if (timeToCrack.days > 1)
        return strl( @"%d days", timeToCrack.days );
    else if (timeToCrack.hours > 1)
        return strl( @"%d hours", timeToCrack.hours );
    else
        return strl( @"trivial" );
}
