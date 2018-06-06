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

// NOTE: mpw is currently NOT thread-safe.
#include "mpw-types.h"

#ifndef _MPW_ALGORITHM_H
#define _MPW_ALGORITHM_H

typedef mpw_enum( unsigned int, MPAlgorithmVersion ) {
    /** V0 did math with chars whose signedness was platform-dependent. */
            MPAlgorithmVersion0,
    /** V1 miscounted the byte-length of multi-byte site names. */
            MPAlgorithmVersion1,
    /** V2 miscounted the byte-length of multi-byte user names. */
            MPAlgorithmVersion2,
    /** V3 is the current version. */
            MPAlgorithmVersion3,

    MPAlgorithmVersionCurrent = MPAlgorithmVersion3,
    MPAlgorithmVersionFirst = MPAlgorithmVersion0,
    MPAlgorithmVersionLast = MPAlgorithmVersion3,
};

/** Derive the master key for a user based on their name and master password.
 * @return A new MPMasterKeySize-byte allocated buffer or NULL if an error occurred. */
MPMasterKey mpw_masterKey(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion);

/** Derive the site key for a user's site from the given master key and site parameters.
 * @return A new MPSiteKeySize-byte allocated buffer or NULL if an error occurred. */
MPSiteKey mpw_siteKey(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext, const MPAlgorithmVersion algorithmVersion);

/** Generate a site result token from the given parameters.
 * @param resultParam A parameter for the resultType.  For stateful result types, the output of mpw_siteState.
 * @return A newly allocated string or NULL if an error occurred. */
const char *mpw_siteResult(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion);

/** Encrypt a stateful site token for persistence.
 * @param resultParam A parameter for the resultType.  For stateful result types, the desired mpw_siteResult.
 * @return A newly allocated string or NULL if an error occurred. */
const char *mpw_siteState(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext,
        const MPResultType resultType, const char *resultParam,
        const MPAlgorithmVersion algorithmVersion);

/** @return A fingerprint for a user. */
MPIdenticon mpw_identicon(const char *fullName, const char *masterPassword);

#endif // _MPW_ALGORITHM_H
