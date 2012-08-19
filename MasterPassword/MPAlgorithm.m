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
#import "MPEntities.h"

id<MPAlgorithm> MPAlgorithmForVersion(NSUInteger version) {

    static NSMutableDictionary *versionToAlgorithm = nil;
    if (!versionToAlgorithm)
        versionToAlgorithm = [NSMutableDictionary dictionary];

    id<MPAlgorithm> algorithm = [versionToAlgorithm objectForKey:@(version)];
    if (!algorithm)
        if ((algorithm = [NSClassFromString(PearlString(@"MPAlgorithmV%u", version)) new]))
            [versionToAlgorithm setObject:algorithm forKey:@(version)];

    return algorithm;
}

id<MPAlgorithm> MPAlgorithmDefaultForBundleVersion(NSString *bundleVersion) {

    if (PearlCFBundleVersionCompare(bundleVersion, @"1.3") == NSOrderedAscending)
        // Pre-1.3
        return MPAlgorithmForVersion(0);

    return MPAlgorithmDefault;
}
