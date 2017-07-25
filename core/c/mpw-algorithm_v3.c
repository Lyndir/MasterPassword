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

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_hash             PearlHashSHA256

static MPMasterKey mpw_masterKeyForUser_v3(const char *fullName, const char *masterPassword) {

    const char *mpKeyScope = mpw_scopeForVariant( MPSiteVariantPassword );
    trc( "algorithm: v%d\n", 3 );
    trc( "fullName: %s (%zu)\n", fullName, strlen( fullName ) );
    trc( "masterPassword: %s\n", masterPassword );
    trc( "key scope: %s\n", mpKeyScope );

    // Calculate the master key salt.
    // masterKeySalt = mpKeyScope . #fullName . fullName
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, mpKeyScope );
    mpw_push_int( &masterKeySalt, &masterKeySaltSize, htonl( strlen( fullName ) ) );
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, fullName );
    if (!masterKeySalt) {
        ftl( "Could not allocate master key salt: %d\n", errno );
        return NULL;
    }
    trc( "masterKeySalt ID: %s\n", mpw_id_buf( masterKeySalt, masterKeySaltSize ) );

    // Calculate the master key.
    // masterKey = scrypt( masterPassword, masterKeySalt )
    const uint8_t *masterKey = mpw_scrypt( MPMasterKeySize, masterPassword, masterKeySalt, masterKeySaltSize, MP_N, MP_r, MP_p );
    mpw_free( masterKeySalt, masterKeySaltSize );
    if (!masterKey) {
        ftl( "Could not allocate master key: %d\n", errno );
        return NULL;
    }
    trc( "masterKey ID: %s\n", mpw_id_buf( masterKey, MPMasterKeySize ) );

    return masterKey;
}

static const char *mpw_passwordForSite_v3(MPMasterKey masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext) {

    const char *siteScope = mpw_scopeForVariant( siteVariant );
    trc( "algorithm: v%d\n", 3 );
    trc( "siteName: %s\n", siteName );
    trc( "siteCounter: %d\n", siteCounter );
    trc( "siteVariant: %d\n", siteVariant );
    trc( "siteType: %d\n", siteType );
    trc( "site scope: %s, context: %s\n", siteScope, siteContext? "<empty>": siteContext );
    trc( "seed from: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)\n",
            siteScope, mpw_hex_l( htonl( strlen( siteName ) ) ), siteName,
            mpw_hex_l( htonl( siteCounter ) ),
            mpw_hex_l( htonl( siteContext? strlen( siteContext ): 0 ) ), siteContext? "(null)": siteContext );

    // Calculate the site seed.
    // sitePasswordSeed = hmac-sha256( masterKey, siteScope . #siteName . siteName . siteCounter . #siteContext . siteContext )
    size_t sitePasswordInfoSize = 0;
    uint8_t *sitePasswordInfo = NULL;
    mpw_push_string( &sitePasswordInfo, &sitePasswordInfoSize, siteScope );
    mpw_push_int( &sitePasswordInfo, &sitePasswordInfoSize, htonl( strlen( siteName ) ) );
    mpw_push_string( &sitePasswordInfo, &sitePasswordInfoSize, siteName );
    mpw_push_int( &sitePasswordInfo, &sitePasswordInfoSize, htonl( siteCounter ) );
    if (siteContext) {
        mpw_push_int( &sitePasswordInfo, &sitePasswordInfoSize, htonl( strlen( siteContext ) ) );
        mpw_push_string( &sitePasswordInfo, &sitePasswordInfoSize, siteContext );
    }
    if (!sitePasswordInfo) {
        ftl( "Could not allocate site seed info: %d\n", errno );
        return NULL;
    }
    trc( "sitePasswordInfo ID: %s\n", mpw_id_buf( sitePasswordInfo, sitePasswordInfoSize ) );

    const uint8_t *sitePasswordSeed = mpw_hmac_sha256( masterKey, MPMasterKeySize, sitePasswordInfo, sitePasswordInfoSize );
    mpw_free( sitePasswordInfo, sitePasswordInfoSize );
    if (!sitePasswordSeed) {
        ftl( "Could not allocate site seed: %d\n", errno );
        return NULL;
    }
    trc( "sitePasswordSeed ID: %s\n", mpw_id_buf( sitePasswordSeed, 32 ) );

    // Determine the template.
    const char *template = mpw_templateForType( siteType, sitePasswordSeed[0] );
    trc( "type %d, template: %s\n", siteType, template );
    if (strlen( template ) > 32) {
        ftl( "Template too long for password seed: %lu", strlen( template ) );
        mpw_free( sitePasswordSeed, sizeof( sitePasswordSeed ) );
        return NULL;
    }

    // Encode the password from the seed using the template.
    char *const sitePassword = calloc( strlen( template ) + 1, sizeof( char ) );
    for (size_t c = 0; c < strlen( template ); ++c) {
        sitePassword[c] = mpw_characterFromClass( template[c], sitePasswordSeed[c + 1] );
        trc( "class %c, index %u (0x%02X) -> character: %c\n", template[c], sitePasswordSeed[c + 1], sitePasswordSeed[c + 1],
                sitePassword[c] );
    }
    mpw_free( sitePasswordSeed, sizeof( sitePasswordSeed ) );

    return sitePassword;
}
