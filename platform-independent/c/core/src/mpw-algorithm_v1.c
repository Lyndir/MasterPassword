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

#include "mpw-algorithm_v1.h"
#include "mpw-util.h"

MP_LIBS_BEGIN
#include <string.h>
MP_LIBS_END

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U
#define MP_otp_window       5 * 60 /* s */

// Algorithm version overrides.
MPMasterKey mpw_master_key_v1(
        const char *fullName, const char *masterPassword) {

    return mpw_master_key_v0( fullName, masterPassword );
}

MPSiteKey mpw_site_key_v1(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext) {

    return mpw_site_key_v0( masterKey, siteName, siteCounter, keyPurpose, keyContext );
}

const char *mpw_site_template_password_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    // Determine the template.
    uint8_t seedByte = siteKey[0];
    const char *template = mpw_type_template( resultType, seedByte );
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
        sitePassword[c] = mpw_class_character( template[c], seedByte );
        trc( "  - class: %c, index: %3u (0x%02hhX) => character: %c",
                template[c], seedByte, seedByte, sitePassword[c] );
    }
    trc( "  => password: %s", sitePassword );

    return sitePassword;
}

const char *mpw_site_crypted_password_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *cipherText) {

    return mpw_site_crypted_password_v0( masterKey, siteKey, resultType, cipherText );
}

const char *mpw_site_derived_password_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    return mpw_site_derived_password_v0( masterKey, siteKey, resultType, resultParam );
}

const char *mpw_site_state_v1(
        MPMasterKey masterKey, MPSiteKey siteKey, MPResultType resultType, const char *state) {

    return mpw_site_state_v0( masterKey, siteKey, resultType, state );
}
