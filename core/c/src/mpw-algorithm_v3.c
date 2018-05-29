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

#include "mpw-util.h"

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U
#define MP_otp_window       5 * 60 /* s */

// Inherited functions.
MPSiteKey mpw_siteKey_v2(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext);
const char *mpw_sitePasswordFromTemplate_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_sitePasswordFromCrypt_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText);
const char *mpw_sitePasswordFromDerive_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_siteState_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state);

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v3(
        const char *fullName, const char *masterPassword) {

    const char *keyScope = mpw_scopeForPurpose( MPKeyPurposeAuthentication );
    trc( "keyScope: %s", keyScope );

    // Calculate the master key salt.
    trc( "masterKeySalt: keyScope=%s | #fullName=%s | fullName=%s",
            keyScope, mpw_hex_l( (uint32_t)strlen( fullName ) ), fullName );
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, keyScope );
    mpw_push_int( &masterKeySalt, &masterKeySaltSize, (uint32_t)strlen( fullName ) );
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, fullName );
    if (!masterKeySalt) {
        err( "Could not allocate master key salt: %s", strerror( errno ) );
        return NULL;
    }
    trc( "  => masterKeySalt.id: %s", mpw_id_buf( masterKeySalt, masterKeySaltSize ) );

    // Calculate the master key.
    trc( "masterKey: scrypt( masterPassword, masterKeySalt, N=%lu, r=%u, p=%u )", MP_N, MP_r, MP_p );
    MPMasterKey masterKey = mpw_kdf_scrypt( MPMasterKeySize,
            (uint8_t *)masterPassword, strlen( masterPassword ), masterKeySalt, masterKeySaltSize, MP_N, MP_r, MP_p );
    mpw_free( &masterKeySalt, masterKeySaltSize );
    if (!masterKey) {
        err( "Could not derive master key: %s", strerror( errno ) );
        return NULL;
    }
    trc( "  => masterKey.id: %s", mpw_id_buf( masterKey, MPMasterKeySize ) );

    return masterKey;
}

static MPSiteKey mpw_siteKey_v3(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext) {

    return mpw_siteKey_v2( masterKey, siteName, siteCounter, keyPurpose, keyContext );
}

static const char *mpw_sitePasswordFromTemplate_v3(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    return mpw_sitePasswordFromTemplate_v2( masterKey, siteKey, resultType, resultParam );
}

static const char *mpw_sitePasswordFromCrypt_v3(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText) {

    return mpw_sitePasswordFromCrypt_v2( masterKey, siteKey, resultType, cipherText );
}

static const char *mpw_sitePasswordFromDerive_v3(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    return mpw_sitePasswordFromDerive_v2( masterKey, siteKey, resultType, resultParam );
}

static const char *mpw_siteState_v3(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state) {

    return mpw_siteState_v2( masterKey, siteKey, resultType, state );
}
