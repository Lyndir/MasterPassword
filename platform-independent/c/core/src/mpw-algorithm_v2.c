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
#include <time.h>

#include "mpw-util.h"

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U
#define MP_otp_window       5 * 60 /* s */

// Inherited functions.
MPMasterKey mpw_masterKey_v1(
        const char *fullName, const char *masterPassword);
const char *mpw_sitePasswordFromTemplate_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_sitePasswordFromCrypt_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText);
const char *mpw_sitePasswordFromDerive_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_siteState_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state);

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v2(
        const char *fullName, const char *masterPassword) {

    return mpw_masterKey_v1( fullName, masterPassword );
}

static MPSiteKey mpw_siteKey_v2(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext) {

    const char *keyScope = mpw_scopeForPurpose( keyPurpose );
    trc( "keyScope: %s", keyScope );

    // OTP counter value.
    if (siteCounter == MPCounterValueTOTP)
        siteCounter = ((uint32_t)time( NULL ) / MP_otp_window) * MP_otp_window;

    // Calculate the site seed.
    trc( "siteSalt: keyScope=%s | #siteName=%s | siteName=%s | siteCounter=%s | #keyContext=%s | keyContext=%s",
            keyScope, mpw_hex_l( (uint32_t)strlen( siteName ) ), siteName, mpw_hex_l( siteCounter ),
            keyContext? mpw_hex_l( (uint32_t)strlen( keyContext ) ): NULL, keyContext );
    size_t siteSaltSize = 0;
    uint8_t *siteSalt = NULL;
    mpw_push_string( &siteSalt, &siteSaltSize, keyScope );
    mpw_push_int( &siteSalt, &siteSaltSize, (uint32_t)strlen( siteName ) );
    mpw_push_string( &siteSalt, &siteSaltSize, siteName );
    mpw_push_int( &siteSalt, &siteSaltSize, siteCounter );
    if (keyContext) {
        mpw_push_int( &siteSalt, &siteSaltSize, (uint32_t)strlen( keyContext ) );
        mpw_push_string( &siteSalt, &siteSaltSize, keyContext );
    }
    if (!siteSalt) {
        err( "Could not allocate site salt: %s", strerror( errno ) );
        return NULL;
    }
    trc( "  => siteSalt.id: %s", mpw_id_buf( siteSalt, siteSaltSize ) );

    trc( "siteKey: hmac-sha256( masterKey.id=%s, siteSalt )",
            mpw_id_buf( masterKey, MPMasterKeySize ) );
    MPSiteKey siteKey = mpw_hash_hmac_sha256( masterKey, MPMasterKeySize, siteSalt, siteSaltSize );
    mpw_free( &siteSalt, siteSaltSize );
    if (!siteKey) {
        err( "Could not derive site key: %s", strerror( errno ) );
        return NULL;
    }
    trc( "  => siteKey.id: %s", mpw_id_buf( siteKey, MPSiteKeySize ) );

    return siteKey;
}

static const char *mpw_sitePasswordFromTemplate_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    return mpw_sitePasswordFromTemplate_v1( masterKey, siteKey, resultType, resultParam );
}

static const char *mpw_sitePasswordFromCrypt_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText) {

    return mpw_sitePasswordFromCrypt_v1( masterKey, siteKey, resultType, cipherText );
}

static const char *mpw_sitePasswordFromDerive_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    return mpw_sitePasswordFromDerive_v1( masterKey, siteKey, resultType, resultParam );
}

static const char *mpw_siteState_v2(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state) {

    return mpw_siteState_v1( masterKey, siteKey, resultType, state );
}
