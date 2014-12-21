//
//  mpw-algorithm.h
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-20.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#define MP_dkLen            64

/** Derive the master key for a user based on their name and master password.
  * @return A new MP_dkLen-byte allocated buffer or NULL if an allocation error occurred. */
const uint8_t *mpw_masterKeyForUser(
        const char *fullName, const char *masterPassword);

/** Encode a password for the site from the given master key and site parameters.
  * @return A newly allocated string or NULL if an allocation error occurred. */
const char *mpw_passwordForSite(
        const uint8_t *masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext);
