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

#include "mpw-util.h"

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U
#define MP_otp_window       5 * 60 /* s */

// Inherited functions.
MPMasterKey mpw_masterKey_v0(
        const char *fullName, const char *masterPassword);
MPSiteKey mpw_siteKey_v0(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext);
const char *mpw_sitePasswordFromCrypt_v0(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText);
const char *mpw_sitePasswordFromDerive_v0(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam);
const char *mpw_siteState_v0(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state);

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v1(
        const char *fullName, const char *masterPassword) {

    return mpw_masterKey_v0( fullName, masterPassword );
}

static MPSiteKey mpw_siteKey_v1(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext) {

    return mpw_siteKey_v0( masterKey, siteName, siteCounter, keyPurpose, keyContext );
}

static const char *mpw_sitePasswordFromTemplate_v1(
        MPMasterKey __unused masterKey, MPSiteKey siteKey, MPResultType resultType, const char __unused *resultParam) {

    // Determine the template.
    uint8_t seedByte = siteKey[0];
    const char *template = mpw_templateForType( resultType, seedByte );
    trc( "template: %u => %s", seedByte, template );
    if (!template)
        return NULL;
    if (strlen( template ) > MPSiteKeySize) {
        err( "Template too long for password seed: %zu", strlen( template ) );
        return NULL;
    }

    // Encode the password from the seed using the template.
    char *const sitePassword = calloc( strlen( template ) + 1, sizeof( char ) );
    for (size_t c = 0; c < strlen( template ); ++c) {
        seedByte = siteKey[c + 1];
        sitePassword[c] = mpw_characterFromClass( template[c], seedByte );
        trc( "  - class: %c, index: %3u (0x%02hhX) => character: %c",
                template[c], seedByte, seedByte, sitePassword[c] );
    }
    trc( "  => password: %s", sitePassword );

    return sitePassword;
}

static const char *mpw_sitePasswordFromCrypt_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText) {

    return mpw_sitePasswordFromCrypt_v0( masterKey, siteKey, resultType, cipherText );
}

static const char *mpw_sitePasswordFromDerive_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    return mpw_sitePasswordFromDerive_v0( masterKey, siteKey, resultType, resultParam );
}

static const char *mpw_siteState_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state) {

    return mpw_siteState_v0( masterKey, siteKey, resultType, state );
}
