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
#include "base64.h"

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U

// Algorithm version helpers.
static const char *mpw_templateForType_v0(MPPasswordType type, uint16_t seedByte) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = templates && count? templates[seedByte % count]: NULL;
    free( templates );
    return template;
}

static const char mpw_characterFromClass_v0(char characterClass, uint16_t seedByte) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    if (!classCharacters)
        return '\0';

    return classCharacters[seedByte % strlen( classCharacters )];
}

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v0(
        const char *fullName, const char *masterPassword) {

    const char *keyScope = mpw_scopeForPurpose( MPKeyPurposeAuthentication );
    trc( "keyScope: %s\n", keyScope );

    // Calculate the master key salt.
    trc( "masterKeySalt: keyScope=%s | #fullName=%s | fullName=%s\n",
            keyScope, mpw_hex_l( htonl( mpw_utf8_strlen( fullName ) ) ), fullName );
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, keyScope );
    mpw_push_int( &masterKeySalt, &masterKeySaltSize, htonl( mpw_utf8_strlen( fullName ) ) );
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

static MPSiteKey mpw_siteKey_v0(
        MPMasterKey masterKey, const char *siteName, const uint32_t siteCounter,
        const MPKeyPurpose keyPurpose, const char *keyContext) {

    const char *keyScope = mpw_scopeForPurpose( keyPurpose );
    trc( "keyScope: %s\n", keyScope );

    // Calculate the site seed.
    trc( "siteSalt: keyScope=%s | #siteName=%s | siteName=%s | siteCounter=%s | #keyContext=%s | keyContext=%s\n",
            keyScope, mpw_hex_l( htonl( mpw_utf8_strlen( siteName ) ) ), siteName, mpw_hex_l( htonl( siteCounter ) ),
            keyContext? mpw_hex_l( htonl( mpw_utf8_strlen( keyContext ) ) ): NULL, keyContext );
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

static const char *mpw_sitePassword_v0(
        MPSiteKey siteKey, const MPPasswordType passwordType) {

    // Determine the template.
    const char *_siteKey = (const char *)siteKey;
    const char *template = mpw_templateForType_v0( passwordType, htons( _siteKey[0] ) );
    trc( "template: %u => %s\n", htons( _siteKey[0] ), template );
    if (!template)
        return NULL;
    if (strlen( template ) > MPSiteKeySize) {
        err( "Template too long for password seed: %lu\n", strlen( template ) );
        return NULL;
    }

    // Encode the password from the seed using the template.
    char *const sitePassword = calloc( strlen( template ) + 1, sizeof( char ) );
    for (size_t c = 0; c < strlen( template ); ++c) {
        sitePassword[c] = mpw_characterFromClass_v0( template[c], htons( _siteKey[c + 1] ) );
        trc( "  - class: %c, index: %5u (0x%02hX) => character: %c\n",
                template[c], htons( _siteKey[c + 1] ), htons( _siteKey[c + 1] ), sitePassword[c] );
    }
    trc( "  => password: %s\n", sitePassword );

    return sitePassword;
}

const char *mpw_encrypt_v0(
        MPMasterKey masterKey, const char *plainText) {

    // Encrypt
    size_t bufSize = strlen( plainText );
    const uint8_t *cipherBuf = mpw_aes_encrypt( masterKey, MPMasterKeySize, (const uint8_t *)plainText, bufSize );
    if (!cipherBuf) {
        err( "AES encryption error: %s\n", strerror( errno ) );
        return NULL;
    }
    trc( "cipherBuf: %lu bytes = %s\n", bufSize, mpw_hex( cipherBuf, bufSize ) );

    // Base64-encode
    size_t b64Max = mpw_base64_encode_max( bufSize );
    char *cipherText = calloc( 1, b64Max + 1 );
    if (mpw_base64_encode( cipherText, b64Max, cipherBuf, bufSize ) < 0) {
        err( "Base64 encoding error." );
        mpw_free_string( cipherText );
        cipherText = NULL;
    }
    trc( "b64 encoded -> cipherText: %s = %s\n", cipherText, mpw_hex( cipherText, sizeof( cipherText ) ) );
    mpw_free( cipherBuf, bufSize );

    return cipherText;
}

const char *mpw_decrypt_v0(
        MPMasterKey masterKey, const char *cipherText) {

    // Base64-decode
    size_t bufSize = mpw_base64_decode_max( cipherText );
    uint8_t *cipherBuf = calloc( 1, bufSize );
    if ((bufSize = (size_t)mpw_base64_decode( cipherBuf, bufSize, cipherText )) < 0) {
        err( "Base64 decoding error." );
        mpw_free( cipherBuf, mpw_base64_decode_max( cipherText ) );
        return NULL;
    }
    trc( "b64 decoded: %lu bytes = %s\n", bufSize, mpw_hex( cipherBuf, bufSize ) );

    // Decrypt
    const uint8_t *plainBytes = mpw_aes_decrypt( masterKey, MPMasterKeySize, cipherBuf, bufSize );
    const char *plainText = strndup( (char *)plainBytes, bufSize );
    mpw_free( plainBytes, bufSize );
    if (!plainText)
        err( "AES decryption error: %s\n", strerror( errno ) );
    trc( "decrypted -> plainText: %s = %s\n", plainText, mpw_hex( plainText, sizeof( plainText ) ) );
    mpw_free( cipherBuf, bufSize );

    return plainText;
}
