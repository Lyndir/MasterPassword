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
#include "base64.h"

#define MP_N                32768LU
#define MP_r                8U
#define MP_p                2U
#define MP_otp_window       5 * 60 /* s */

// Algorithm version helpers.
static const char *mpw_templateForType_v0(MPResultType type, uint16_t templateIndex) {

    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    char const *template = templates && count? templates[templateIndex % count]: NULL;
    free( templates );
    return template;
}

static const char mpw_characterFromClass_v0(char characterClass, uint16_t classIndex) {

    const char *classCharacters = mpw_charactersInClass( characterClass );
    if (!classCharacters)
        return '\0';

    return classCharacters[classIndex % strlen( classCharacters )];
}

// Algorithm version overrides.
static MPMasterKey mpw_masterKey_v0(
        const char *fullName, const char *masterPassword) {

    const char *keyScope = mpw_scopeForPurpose( MPKeyPurposeAuthentication );
    trc( "keyScope: %s", keyScope );

    // Calculate the master key salt.
    trc( "masterKeySalt: keyScope=%s | #fullName=%s | fullName=%s",
            keyScope, mpw_hex_l( (uint32_t)mpw_utf8_strlen( fullName ) ), fullName );
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_push_string( &masterKeySalt, &masterKeySaltSize, keyScope );
    mpw_push_int( &masterKeySalt, &masterKeySaltSize, (uint32_t)mpw_utf8_strlen( fullName ) );
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

static MPSiteKey mpw_siteKey_v0(
        MPMasterKey masterKey, const char *siteName, MPCounterValue siteCounter,
        MPKeyPurpose keyPurpose, const char *keyContext) {

    const char *keyScope = mpw_scopeForPurpose( keyPurpose );
    trc( "keyScope: %s", keyScope );

    // OTP counter value.
    if (siteCounter == MPCounterValueTOTP)
        siteCounter = ((uint32_t)time( NULL ) / MP_otp_window) * MP_otp_window;

    // Calculate the site seed.
    trc( "siteSalt: keyScope=%s | #siteName=%s | siteName=%s | siteCounter=%s | #keyContext=%s | keyContext=%s",
            keyScope, mpw_hex_l( (uint32_t)mpw_utf8_strlen( siteName ) ), siteName, mpw_hex_l( siteCounter ),
            keyContext? mpw_hex_l( (uint32_t)mpw_utf8_strlen( keyContext ) ): NULL, keyContext );
    size_t siteSaltSize = 0;
    uint8_t *siteSalt = NULL;
    mpw_push_string( &siteSalt, &siteSaltSize, keyScope );
    mpw_push_int( &siteSalt, &siteSaltSize, (uint32_t)mpw_utf8_strlen( siteName ) );
    mpw_push_string( &siteSalt, &siteSaltSize, siteName );
    mpw_push_int( &siteSalt, &siteSaltSize, siteCounter );
    if (keyContext) {
        mpw_push_int( &siteSalt, &siteSaltSize, (uint32_t)mpw_utf8_strlen( keyContext ) );
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

static const char *mpw_sitePasswordFromTemplate_v0(
        MPMasterKey __unused masterKey, MPSiteKey siteKey, MPResultType resultType, const char __unused *resultParam) {

    const char *_siteKey = (const char *)siteKey;

    // Determine the template.
    uint16_t seedByte;
    mpw_uint16( (uint16_t)_siteKey[0], (uint8_t *)&seedByte );
    const char *template = mpw_templateForType_v0( resultType, seedByte );
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
        mpw_uint16( (uint16_t)_siteKey[c + 1], (uint8_t *)&seedByte );
        sitePassword[c] = mpw_characterFromClass_v0( template[c], seedByte );
        trc( "  - class: %c, index: %5u (0x%02hX) => character: %c",
                template[c], seedByte, seedByte, sitePassword[c] );
    }
    trc( "  => password: %s", sitePassword );

    return sitePassword;
}

static const char *mpw_sitePasswordFromCrypt_v0(
        MPMasterKey masterKey, MPSiteKey __unused siteKey, MPResultType __unused resultType, const char *cipherText) {

    if (!cipherText) {
        err( "Missing encrypted state." );
        return NULL;
    }

    // Base64-decode
    uint8_t *cipherBuf = calloc( 1, mpw_base64_decode_max( cipherText ) );
    size_t bufSize = (size_t)mpw_base64_decode( cipherBuf, cipherText ), cipherBufSize = bufSize;
    if ((int)bufSize < 0) {
        err( "Base64 decoding error." );
        mpw_free( &cipherBuf, mpw_base64_decode_max( cipherText ) );
        return NULL;
    }
    trc( "b64 decoded: %zu bytes = %s", bufSize, mpw_hex( cipherBuf, bufSize ) );

    // Decrypt
    const uint8_t *plainBytes = mpw_aes_decrypt( masterKey, MPMasterKeySize, cipherBuf, &bufSize );
    mpw_free( &cipherBuf, cipherBufSize );
    const char *plainText = mpw_strndup( (char *)plainBytes, bufSize );
    mpw_free( &plainBytes, bufSize );
    if (!plainText)
        err( "AES decryption error: %s", strerror( errno ) );
    trc( "decrypted -> plainText: %zu bytes = %s = %s", strlen( plainText ), plainText, mpw_hex( plainText, strlen( plainText ) ) );

    return plainText;
}

static const char *mpw_sitePasswordFromDerive_v0(
        MPMasterKey __unused masterKey, MPSiteKey siteKey, MPResultType resultType, const char *resultParam) {

    switch (resultType) {
        case MPResultTypeDeriveKey: {
            if (!resultParam) {
                err( "Missing key size parameter." );
                return NULL;
            }
            int resultParamInt = atoi( resultParam );
            if (!resultParamInt)
                resultParamInt = 512;
            if (resultParamInt < 128 || resultParamInt > 512 || resultParamInt % 8 != 0) {
                err( "Parameter is not a valid key size (should be 128 - 512): %s", resultParam );
                return NULL;
            }
            uint16_t keySize = (uint16_t)(resultParamInt / 8);
            trc( "keySize: %u", keySize );

            // Derive key
            const uint8_t *resultKey = mpw_kdf_blake2b( keySize, siteKey, MPSiteKeySize, NULL, 0, 0, NULL );
            if (!resultKey) {
                err( "Could not derive result key: %s", strerror( errno ) );
                return NULL;
            }

            // Base64-encode
            size_t b64Max = mpw_base64_encode_max( keySize );
            char *b64Key = calloc( 1, b64Max + 1 );
            if (mpw_base64_encode( b64Key, resultKey, keySize ) < 0) {
                err( "Base64 encoding error." );
                mpw_free_string( &b64Key );
            }
            else
                trc( "b64 encoded -> key: %s", b64Key );
            mpw_free( &resultKey, keySize );

            return b64Key;
        }
        default:
            err( "Unsupported derived password type: %d", resultType );
            return NULL;
    }
}

static const char *mpw_siteState_v0(
        MPMasterKey masterKey, MPSiteKey __unused siteKey, MPResultType __unused resultType, const char *plainText) {

    // Encrypt
    size_t bufSize = strlen( plainText );
    const uint8_t *cipherBuf = mpw_aes_encrypt( masterKey, MPMasterKeySize, (const uint8_t *)plainText, &bufSize );
    if (!cipherBuf) {
        err( "AES encryption error: %s", strerror( errno ) );
        return NULL;
    }
    trc( "cipherBuf: %zu bytes = %s", bufSize, mpw_hex( cipherBuf, bufSize ) );

    // Base64-encode
    size_t b64Max = mpw_base64_encode_max( bufSize );
    char *cipherText = calloc( 1, b64Max + 1 );
    if (mpw_base64_encode( cipherText, cipherBuf, bufSize ) < 0) {
        err( "Base64 encoding error." );
        mpw_free_string( &cipherText );
    }
    else
        trc( "b64 encoded -> cipherText: %s", cipherText );
    mpw_free( &cipherBuf, bufSize );

    return cipherText;
}
