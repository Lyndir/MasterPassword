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
MPSiteKey mpw_siteKey_v2(
        MPMasterKey masterKey, const char *siteName, const uint32_t siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext);
const char *mpw_sitePassword_v2(
        MPSiteKey siteKey, const MPPasswordType passwordType);
const char *mpw_encrypt_v2(
        MPMasterKey masterKey, const char *plainText);
const char *mpw_decrypt_v2(
        MPMasterKey masterKey, const char *cipherText);

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v3(
        const char *fullName, const char *masterPassword) {

    const char *keyScope = mpw_scopeForPurpose( MPKeyPurposeAuthentication );
    trc( "keyScope: %s\n", keyScope );

    // Calculate the master key salt.
    trc( "masterKeySalt: keyScope=%s | #fullName=%s | fullName=%s\n",
            keyScope, mpw_hex_l( htonl( strlen( fullName ) ) ), fullName );
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, keyScope );
    mpw_push_int( &masterKeySalt, &masterKeySaltSize, htonl( strlen( fullName ) ) );
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, fullName );
    if (!masterKeySalt) {
        err( "Could not allocate master key salt: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "  => masterKeySalt.id: %s\n", mpw_id_buf( masterKeySalt, masterKeySaltSize ) );

    // Calculate the master key.
    trc( "masterKey: scrypt( masterPassword, masterKeySalt, N=%lu, r=%u, p=%u )\n", MP_N, MP_r, MP_p );
    MPMasterKey masterKey = mpw_scrypt( MPMasterKeySize, masterPassword, masterKeySalt, masterKeySaltSize, MP_N, MP_r, MP_p );
    mpw_free( masterKeySalt, masterKeySaltSize );
    if (!masterKey) {
        err( "Could not allocate master key: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "  => masterKey.id: %s\n", mpw_id_buf( masterKey, MPMasterKeySize ) );

    return masterKey;
}

static MPSiteKey mpw_siteKey_v3(
        MPMasterKey masterKey, const char *siteName, const uint32_t siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext) {

    return mpw_siteKey_v2( masterKey, siteName, siteCounter, keyPurpose, keyContext );
}

static const char *mpw_sitePassword_v3(
        MPSiteKey siteKey, const MPPasswordType passwordType) {

    return mpw_sitePassword_v2( siteKey, passwordType );
}

static const char *mpw_encrypt_v3(
        MPMasterKey masterKey, const char *plainText) {

    return mpw_encrypt_v2( masterKey, plainText );
}

static const char *mpw_decrypt_v3(
        MPMasterKey masterKey, const char *cipherText) {

    return mpw_decrypt_v2( masterKey, cipherText );
}
