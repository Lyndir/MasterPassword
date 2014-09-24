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
//  MPAlgorithm
//
//  Created by Maarten Billemont on 16/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAlgorithm.h"

id<MPAlgorithm> MPAlgorithmForVersion(NSUInteger version) {

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
