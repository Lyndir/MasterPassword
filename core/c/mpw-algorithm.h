//
//  mpw-algorithm.h
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-20.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

// NOTE: mpw is currently NOT thread-safe.
#include "mpw-types.h"

typedef enum(unsigned int, MPAlgorithmVersion) {
    /** V0 did math with chars whose signedness was platform-dependent. */
            MPAlgorithmVersion0,
    /** V1 miscounted the byte-length of multi-byte site names. */
            MPAlgorithmVersion1,
    /** V2 miscounted the byte-length of multi-byte user names. */
            MPAlgorithmVersion2,
    /** V3 is the current version. */
            MPAlgorithmVersion3,
};
#define MPAlgorithmVersionCurrent MPAlgorithmVersion3

/** Derive the master key for a user based on their name and master password.
 * @return A new MP_dkLen-byte allocated buffer or NULL if an allocation error occurred. */
const uint8_t *mpw_masterKeyForUser(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion);

/** Encode a password for the site from the given master key and site parameters.
 * @return A newly allocated string or NULL if an allocation error occurred. */
const char *mpw_passwordForSite(
        const uint8_t *masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext, const MPAlgorithmVersion algorithmVersion);
