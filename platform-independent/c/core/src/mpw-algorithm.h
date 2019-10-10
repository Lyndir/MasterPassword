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

#ifndef _MPW_ALGORITHM_H
#define _MPW_ALGORITHM_H

#include "mpw-types.h"

typedef mpw_enum( unsigned int, MPAlgorithmVersion ) {
    /** V0 did math with chars whose signedness was platform-dependent. */
            MPAlgorithmVersionV0,
    /** V1 miscounted the byte-length of multi-byte site names. */
            MPAlgorithmVersionV1,
    /** V2 miscounted the byte-length of multi-byte user names. */
            MPAlgorithmVersionV2,
    /** V3 is the current version. */
            MPAlgorithmVersionV3,

    MPAlgorithmVersionCurrent = MPAlgorithmVersionV3,
    MPAlgorithmVersionFirst = MPAlgorithmVersionV0,
    MPAlgorithmVersionLast = MPAlgorithmVersionV3,
};

/** Derive the master key for a user based on their name and master password.
 * @return A buffer (allocated, MPMasterKeySize) or NULL if the fullName or masterPassword is missing, the algorithm is unknown, or an algorithm error occurred. */
const MPMasterKey mpw_master_key(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion);

/** Derive the site key for a user's site from the given master key and site parameters.
 * @return A buffer (allocated, MPSiteKeySize) or NULL if the masterKey or siteName is missing, the algorithm is unknown, or an algorithm error occurred. */
const MPSiteKey mpw_site_key(
        const MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext, const MPAlgorithmVersion algorithmVersion);

/** Generate a site result token from the given parameters.
 * @param resultParam A parameter for the resultType.  For stateful result types, the output of mpw_site_state.
 * @return A string (allocated) or NULL if the masterKey or siteName is missing, the algorithm is unknown, or an algorithm error occurred. */
const char *mpw_site_result(
        const MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion);

/** Encrypt a stateful site token for persistence.
 * @param resultParam A parameter for the resultType.  For stateful result types, the desired mpw_site_result.
 * @return A string (allocated) or NULL if the masterKey, siteName or resultParam is missing, the algorithm is unknown, or an algorithm error occurred. */
const char *mpw_site_state(
        const MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion);

/** @return An identicon (static) that represents the user's identity. */
const MPIdenticon mpw_identicon(
        const char *fullName, const char *masterPassword);
/** @return An encoded representation (shared) of the given identicon or NULL if the identicon is unset. */
const char *mpw_identicon_encode(
        const MPIdenticon identicon);
/** @return An identicon (static) decoded from the given encoded identicon representation or an identicon with empty fields if the identicon could not be parsed. */
const MPIdenticon mpw_identicon_encoded(
        const char *encoding);

#endif // _MPW_ALGORITHM_H
