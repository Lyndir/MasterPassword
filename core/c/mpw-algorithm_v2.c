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

#include <string.h>
#include <errno.h>
#include <arpa/inet.h>

#include "mpw-types.h"
#include "mpw-util.h"

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U

// Inherited functions.
MPMasterKey mpw_masterKey_v1(
        const char *fullName, const char *masterPassword);
const char *mpw_sitePassword_v1(
        MPSiteKey siteKey, const MPPasswordType passwordType);
const char *mpw_encrypt_v1(
        MPMasterKey masterKey, const char *plainText);
const char *mpw_decrypt_v1(
        MPMasterKey masterKey, const char *cipherText);

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v2(
        const char *fullName, const char *masterPassword) {

    return mpw_masterKey_v1( fullName, masterPassword );
}

static MPSiteKey mpw_siteKey_v2(
        MPMasterKey masterKey, const char *siteName, const MPCounterValue siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext) {

    const char *keyScope = mpw_scopeForPurpose( keyPurpose );
    trc( "keyScope: %s\n", keyScope );

    // TODO: Implement MPCounterValueTOTP

    // Calculate the site seed.
    trc( "siteSalt: keyScope=%s | #siteName=%s | siteName=%s | siteCounter=%s | #keyContext=%s | keyContext=%s\n",
            keyScope, mpw_hex_l( htonl( strlen( siteName ) ) ), siteName, mpw_hex_l( htonl( siteCounter ) ),
            keyContext? mpw_hex_l( htonl( strlen( keyContext ) ) ): NULL, keyContext );
    size_t siteSaltSize = 0;
    uint8_t *siteSalt = NULL;
    mpw_push_string( &siteSalt, &siteSaltSize, keyScope );
    mpw_push_int( &siteSalt, &siteSaltSize, htonl( strlen( siteName ) ) );
    mpw_push_string( &siteSalt, &siteSaltSize, siteName );
    mpw_push_int( &siteSalt, &siteSaltSize, htonl( siteCounter ) );
    if (keyContext) {
        mpw_push_int( &siteSalt, &siteSaltSize, htonl( strlen( keyContext ) ) );
        mpw_push_string( &siteSalt, &siteSaltSize, keyContext );
    }
    if (!siteSalt || !siteSaltSize) {
        err( "Could not allocate site salt: %s\n", strerror( errno ) );
        mpw_free( siteSalt, siteSaltSize );
        return NULL;
    }
    trc( "  => siteSalt.id: %s\n", mpw_id_buf( siteSalt, siteSaltSize ) );

    trc( "siteKey: hmac-sha256( masterKey.id=%s, siteSalt )\n",
            mpw_id_buf( masterKey, MPMasterKeySize ) );
    MPSiteKey siteKey = mpw_hmac_sha256( masterKey, MPMasterKeySize, siteSalt, siteSaltSize );
    mpw_free( siteSalt, siteSaltSize );
    if (!siteKey) {
        err( "Could not allocate site key: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "  => siteKey.id: %s\n", mpw_id_buf( siteKey, MPSiteKeySize ) );

    return siteKey;
}

static const char *mpw_sitePassword_v2(
        MPSiteKey siteKey, const MPPasswordType passwordType) {

    return mpw_sitePassword_v1( siteKey, passwordType );
}

static const char *mpw_encrypt_v2(
        MPMasterKey masterKey, const char *plainText) {

    return mpw_encrypt_v1( masterKey, plainText );
}

static const char *mpw_decrypt_v2(
        MPMasterKey masterKey, const char *cipherText) {

    return mpw_decrypt_v1( masterKey, cipherText );
}
