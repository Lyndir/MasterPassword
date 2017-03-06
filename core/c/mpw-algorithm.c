//
//  mpw-algorithm.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-20.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include "mpw-algorithm.h"
#include "mpw-algorithm_v0.c"
#include "mpw-algorithm_v1.c"
#include "mpw-algorithm_v2.c"
#include "mpw-algorithm_v3.c"

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_hash             PearlHashSHA256

const uint8_t *mpw_masterKeyForUser(const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    if (!fullName || !masterPassword)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_masterKeyForUser_v0( fullName, masterPassword );
        case MPAlgorithmVersion1:
            return mpw_masterKeyForUser_v1( fullName, masterPassword );
        case MPAlgorithmVersion2:
            return mpw_masterKeyForUser_v2( fullName, masterPassword );
        case MPAlgorithmVersion3:
            return mpw_masterKeyForUser_v3( fullName, masterPassword );
        default:
            ftl( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}

const char *mpw_passwordForSite(const uint8_t *masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext, const MPAlgorithmVersion algorithmVersion) {

    if (!masterKey || !siteName)
        return NULL;

    switch (algorithmVersion) {
        case MPAlgorithmVersion0:
            return mpw_passwordForSite_v0( masterKey, siteName, siteType, siteCounter, siteVariant, siteContext );
        case MPAlgorithmVersion1:
            return mpw_passwordForSite_v1( masterKey, siteName, siteType, siteCounter, siteVariant, siteContext );
        case MPAlgorithmVersion2:
            return mpw_passwordForSite_v2( masterKey, siteName, siteType, siteCounter, siteVariant, siteContext );
        case MPAlgorithmVersion3:
            return mpw_passwordForSite_v3( masterKey, siteName, siteType, siteCounter, siteVariant, siteContext );
        default:
            ftl( "Unsupported version: %d", algorithmVersion );
            return NULL;
    }
}
