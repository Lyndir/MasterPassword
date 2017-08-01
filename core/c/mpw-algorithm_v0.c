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

static const char *mpw_templateForType_v0(MPPasswordType type, uint16_t seedByte) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = templates && count? templates[seedByte % count]: NULL;
    free( templates );
    return template;
}

static const char mpw_characterFromClass_v0(char characterClass, uint16_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    return classCharacters[seedByte % strlen( classCharacters )];
}

static MPMasterKey mpw_masterKeyForUser_v0(const char *fullName, const char *masterPassword) {

    const char *mpKeyScope = mpw_scopeForPurpose( MPKeyPurposeAuthentication );
    trc( "algorithm: v%d\n", 0 );
    trc( "fullName: %s (%zu)\n", fullName, mpw_utf8_strlen( fullName ) );
    trc( "masterPassword: %s\n", masterPassword );
    trc( "key scope: %s\n", mpKeyScope );

    // Calculate the master key salt.
    // masterKeySalt = mpKeyScope . #fullName . fullName
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, mpKeyScope );
    mpw_push_int( &masterKeySalt, &masterKeySaltSize, htonl( mpw_utf8_strlen( fullName ) ) );
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

static MPSiteKey mpw_siteKey_v0(
        MPMasterKey masterKey, const char *siteName, const uint32_t siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext) {

    const char *keyScope = mpw_scopeForPurpose( keyPurpose );
    trc( "-- mpw_siteKey_v0\n" );
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
    mpw_push_int( &siteSalt, &siteSaltSize, htonl( mpw_utf8_strlen( siteName ) ) );
    mpw_push_string( &siteSalt, &siteSaltSize, siteName );
    mpw_push_int( &siteSalt, &siteSaltSize, htonl( siteCounter ) );
    if (keyContext) {
        mpw_push_int( &siteSalt, &siteSaltSize, htonl( mpw_utf8_strlen( keyContext ) ) );
        mpw_push_string( &siteSalt, &siteSaltSize, keyContext );
    }
    if (!siteSalt || !siteSaltSize) {
        ftl( "Could not allocate site salt: %d\n", errno );
        mpw_free( siteSalt, siteSaltSize );
        return NULL;
    }
    trc( "siteSalt ID: %s\n", mpw_id_buf( siteSalt, siteSaltSize ) );

    MPSiteKey siteKey = mpw_hmac_sha256( masterKey, MPMasterKeySize, siteSalt, siteSaltSize );
    mpw_free( siteSalt, siteSaltSize );
    if (!siteKey) {
        ftl( "Could not allocate site key: %d\n", errno );
        return NULL;
    }
    trc( "siteKey ID: %s\n", mpw_id_buf( siteKey, MPSiteKeySize ) );

    return siteKey;
}

static const char *mpw_sitePassword_v0(
        MPSiteKey siteKey, const MPPasswordType passwordType) {

    trc( "-- mpw_sitePassword_v0\n" );
    trc( "passwordType: %d\n", passwordType );

    // Determine the template.
    const char *_siteKey = (const char *)siteKey;
    const char *template = mpw_templateForType_v0( passwordType, htons( _siteKey[0] ) );
    trc( "type %d, template: %s\n", passwordType, template );
    if (strlen( template ) > MPSiteKeySize) {
        ftl( "Template too long for password seed: %lu", strlen( template ) );
        mpw_free( _siteKey, sizeof( _siteKey ) );
        return NULL;
    }

    // Encode the password from the seed using the template.
    char *const sitePassword = calloc( strlen( template ) + 1, sizeof( char ) );
    for (size_t c = 0; c < strlen( template ); ++c) {
        sitePassword[c] = mpw_characterFromClass_v0( template[c], htons( _siteKey[c + 1] ) );
        trc( "class %c, index %u (0x%02X) -> character: %c\n",
                template[c], htons( _siteKey[c + 1] ), htons( _siteKey[c + 1] ), sitePassword[c] );
    }

    return sitePassword;
}
