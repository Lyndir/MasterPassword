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

static MPMasterKey mpw_masterKeyForUser_v3(const char *fullName, const char *masterPassword) {

    const char *mpKeyScope = mpw_scopeForPurpose( MPKeyPurposeAuthentication );
    trc( "-- mpw_masterKeyForUser_v3\n" );
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
        err( "Could not allocate master key salt: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "masterKeySalt ID: %s\n", mpw_id_buf( masterKeySalt, masterKeySaltSize ) );

    // Calculate the master key.
    // masterKey = scrypt( masterPassword, masterKeySalt )
    const uint8_t *masterKey = mpw_scrypt( MPMasterKeySize, masterPassword, masterKeySalt, masterKeySaltSize, MP_N, MP_r, MP_p );
    mpw_free( masterKeySalt, masterKeySaltSize );
    if (!masterKey) {
        err( "Could not allocate master key: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "masterKey ID: %s\n", mpw_id_buf( masterKey, MPMasterKeySize ) );

    return masterKey;
}

static MPSiteKey mpw_siteKey_v3(
        MPMasterKey masterKey, const char *siteName, const uint32_t siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext) {

    const char *keyScope = mpw_scopeForPurpose( keyPurpose );
    trc( "-- mpw_siteKey_v3\n" );
    trc( "siteName: %s\n", siteName );
    trc( "siteCounter: %d\n", siteCounter );
    trc( "keyPurpose: %d\n", keyPurpose );
    trc( "keyScope: %s, keyContext: %s\n", keyScope, keyContext? "<empty>": keyContext );
    trc( "siteKey: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)\n",
            keyScope, mpw_hex_l( htonl( strlen( siteName ) ) ), siteName,
            mpw_hex_l( htonl( siteCounter ) ),
            mpw_hex_l( htonl( keyContext? strlen( keyContext ): 0 ) ), keyContext? "(null)": keyContext );

    // Calculate the site seed.
    // siteKey = hmac-sha256( masterKey, keyScope . #siteName . siteName . siteCounter . #keyContext . keyContext )
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
    if (!siteSalt) {
        err( "Could not allocate site salt: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "siteSalt ID: %s\n", mpw_id_buf( siteSalt, siteSaltSize ) );

    MPSiteKey siteKey = mpw_hmac_sha256( masterKey, MPMasterKeySize, siteSalt, siteSaltSize );
    mpw_free( siteSalt, siteSaltSize );
    if (!siteKey || !siteSaltSize) {
        err( "Could not allocate site key: %s\n", strerror( errno ) );
        mpw_free( siteSalt, siteSaltSize );
        return NULL;
    }
    trc( "siteKey ID: %s\n", mpw_id_buf( siteKey, MPSiteKeySize ) );

    return siteKey;
}

static const char *mpw_sitePassword_v3(
        MPSiteKey siteKey, const MPPasswordType passwordType) {

    trc( "-- mpw_sitePassword_v3\n" );
    trc( "passwordType: %d\n", passwordType );

    // Determine the template.
    const char *template = mpw_templateForType( passwordType, siteKey[0] );
    trc( "type %d, template: %s\n", passwordType, template );
    if (!template)
        return NULL;
    if (strlen( template ) > MPSiteKeySize) {
        err( "Template too long for password seed: %lu\n", strlen( template ) );
        return NULL;
    }

    // Encode the password from the seed using the template.
    char *const sitePassword = calloc( strlen( template ) + 1, sizeof( char ) );
    for (size_t c = 0; c < strlen( template ); ++c) {
        sitePassword[c] = mpw_characterFromClass( template[c], siteKey[c + 1] );
        trc( "class %c, index %u (0x%02X) -> character: %c\n", template[c], siteKey[c + 1], siteKey[c + 1],
                sitePassword[c] );
    }

    return sitePassword;
}

const char *mpw_encrypt_v3(
        MPMasterKey masterKey, const char *plainText) {

    return NULL; // TODO: aes128_cbc
}

const char *mpw_decrypt_v3(
        MPMasterKey masterKey, const char *cipherText) {

    return NULL; // TODO: aes128_cbc
}
