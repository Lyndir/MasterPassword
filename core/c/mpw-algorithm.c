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
