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

typedef enum( unsigned int, MPAlgorithmVersion ) {
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
 * @return A new MP_dkLen-byte allocated buffer or NULL if an allocation error occurred. */
MPMasterKey mpw_masterKeyForUser(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion);

/** Encode a password for the site from the given master key and site parameters.
 * @return A newly allocated string or NULL if an allocation error occurred. */
const char *mpw_passwordForSite(
        MPMasterKey masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext, const MPAlgorithmVersion algorithmVersion);

#endif // _MPW_ALGORITHM_H
