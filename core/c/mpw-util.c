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
#include <ctype.h>
#include <errno.h>

#if MPW_COLOR
#include <unistd.h>
#include <curses.h>
#include <term.h>
#endif

#if HAS_CPERCIVA
#include <scrypt/crypto_scrypt.h>
#include <scrypt/sha256.h>
#elif HAS_SODIUM
#include "sodium.h"
#ifdef SODIUM_LIBRARY_MINIMAL
#include "crypto_stream_aes128ctr.h"
#include "crypto_kdf_blake2b.h"
#endif
#endif

#include "mpw-util.h"

int mpw_verbosity = inf_level;

bool mpw_push_buf(uint8_t **const buffer, size_t *const bufferSize, const void *pushBuffer, const size_t pushSize) {

    if (!buffer || !bufferSize || !pushBuffer || !pushSize)
        return false;
    if (*bufferSize == ERR)
        // The buffer was marked as broken, it is missing a previous push.  Abort to avoid corrupt content.
        return false;

    if (!mpw_realloc( buffer, bufferSize, pushSize )) {
        // realloc failed, we can't push.  Mark the buffer as broken.
        mpw_free( *buffer, *bufferSize );
        *bufferSize = (size_t)ERR;
        *buffer = NULL;
        return false;
    }

    uint8_t *bufferOffset = *buffer + *bufferSize - pushSize;
    memcpy( bufferOffset, pushBuffer, pushSize );
    return true;
}

bool mpw_push_string(uint8_t **const buffer, size_t *const bufferSize, const char *pushString) {

    return pushString && mpw_push_buf( buffer, bufferSize, pushString, strlen( pushString ) );
}

bool mpw_string_push(char **const string, const char *pushString) {

    if (!*string)
        *string = calloc( 1, sizeof( char ) );

    size_t stringLength = strlen( *string );
    return pushString && mpw_push_buf( (uint8_t **const)string, &stringLength, pushString, strlen( pushString ) + 1 );
}

bool mpw_string_pushf(char **const string, const char *pushFormat, ...) {

    va_list args;
    va_start( args, pushFormat );
    char *pushString = NULL;
    bool success = vasprintf( &pushString, pushFormat, args ) >= 0 && mpw_string_push( string, pushString );
    va_end( args );
    mpw_free_string( pushString );

    return success;
}

bool mpw_push_int(uint8_t **const buffer, size_t *const bufferSize, const uint32_t pushInt) {

    return mpw_push_buf( buffer, bufferSize, &pushInt, sizeof( pushInt ) );
}

bool __mpw_realloc(void **buffer, size_t *bufferSize, const size_t deltaSize) {

    if (!buffer)
        return false;

    void *newBuffer = realloc( *buffer, (bufferSize? *bufferSize: 0) + deltaSize );
    if (!newBuffer)
        return false;

    *buffer = newBuffer;
    if (bufferSize)
        *bufferSize += deltaSize;

    return true;
}

bool mpw_free(const void *buffer, const size_t bufferSize) {

    if (!buffer)
        return false;

    memset( (void *)buffer, 0, bufferSize );
    free( (void *)buffer );
    return true;
}

bool mpw_free_string(const char *string) {

    return string && mpw_free( string, strlen( string ) );
}

uint8_t const *mpw_kdf_scrypt(const size_t keySize, const char *secret, const uint8_t *salt, const size_t saltSize,
        uint64_t N, uint32_t r, uint32_t p) {

    if (!secret || !salt)
        return NULL;

    uint8_t *key = malloc( keySize );
    if (!key)
        return NULL;

#if HAS_CPERCIVA
    if (crypto_scrypt( (const uint8_t *)secret, strlen( secret ), salt, saltSize, N, r, p, key, keySize ) < 0) {
        mpw_free( key, keySize );
        return NULL;
    }
#elif HAS_SODIUM
    if (crypto_pwhash_scryptsalsa208sha256_ll( (const uint8_t *)secret, strlen( secret ), salt, saltSize, N, r, p, key, keySize ) != 0) {
        mpw_free( key, keySize );
        return NULL;
    }
#else
#error No crypto support for mpw_scrypt.
#endif

    return key;
}

uint8_t const *mpw_kdf_blake2b(const size_t subkeySize, const uint8_t *key, const size_t keySize,
        const uint8_t *context, const size_t contextSize, const uint64_t id, const char *personal) {

    if (!key || !keySize || !subkeySize) {
        errno = EINVAL;
        return NULL;
    }

    uint8_t *subkey = malloc( subkeySize );
    if (!subkey)
        return NULL;

#if HAS_SODIUM
    if (keySize < crypto_generichash_blake2b_KEYBYTES_MIN || keySize > crypto_generichash_blake2b_KEYBYTES_MAX ||
        subkeySize < crypto_generichash_blake2b_KEYBYTES_MIN || subkeySize > crypto_generichash_blake2b_KEYBYTES_MAX ||
        contextSize < crypto_generichash_blake2b_BYTES_MIN || contextSize > crypto_generichash_blake2b_BYTES_MAX ||
        (personal && strlen( personal ) > crypto_generichash_blake2b_PERSONALBYTES)) {
        errno = EINVAL;
        free( subkey );
        return NULL;
    }

    uint8_t saltBuf[crypto_generichash_blake2b_SALTBYTES];
    bzero( saltBuf, sizeof saltBuf );
    if (id) {
        uint64_t id_n = htonll( id );
        memcpy( saltBuf, &id_n, sizeof id_n );
    }

    uint8_t personalBuf[crypto_generichash_blake2b_PERSONALBYTES];
    bzero( personalBuf, sizeof saltBuf );
    if (personal && strlen( personal ))
        memcpy( personalBuf, personal, strlen( personal ) );

    if (crypto_generichash_blake2b_salt_personal( subkey, subkeySize, context, contextSize, key, keySize, saltBuf, personalBuf ) != 0) {
        mpw_free( subkey, subkeySize );
        return NULL;
    }
#else
#error No crypto support for mpw_kdf_blake2b.
#endif

    return subkey;
}

uint8_t const *mpw_hash_hmac_sha256(const uint8_t *key, const size_t keySize, const uint8_t *message, const size_t messageSize) {

    if (!key || !keySize || !message || !messageSize)
        return NULL;

#if HAS_CPERCIVA
    uint8_t *const mac = malloc( 32 );
    if (!mac)
        return NULL;

    HMAC_SHA256_Buf( key, keySize, message, messageSize, mac );
#elif HAS_SODIUM
    uint8_t *const mac = malloc( crypto_auth_hmacsha256_BYTES );
    if (!mac)
        return NULL;

    crypto_auth_hmacsha256_state state;
    if (crypto_auth_hmacsha256_init( &state, key, keySize ) != 0 ||
        crypto_auth_hmacsha256_update( &state, message, messageSize ) != 0 ||
        crypto_auth_hmacsha256_final( &state, mac ) != 0) {
        mpw_free( mac, crypto_auth_hmacsha256_BYTES );
        return NULL;
    }
#else
#error No crypto support for mpw_hmac_sha256.
#endif

    return mac;
}

static uint8_t const *mpw_aes(bool encrypt, const uint8_t *key, const size_t keySize, const uint8_t *buf, const size_t bufSize) {

#if HAS_SODIUM
    if (!key || keySize < crypto_stream_KEYBYTES)
        return NULL;

    uint8_t nonce[crypto_stream_NONCEBYTES];
    bzero( (void *)nonce, sizeof( nonce ) );

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (encrypt) {
        uint8_t *const cipherBuf = malloc( bufSize );
        if (crypto_stream_aes128ctr_xor( cipherBuf, buf, bufSize, nonce, key ) != 0) {
            mpw_free( cipherBuf, bufSize );
            return NULL;
        }
        return cipherBuf;
    }
    else {
        uint8_t *const plainBuf = malloc( bufSize );
        if (crypto_stream_aes128ctr( plainBuf, bufSize, nonce, key ) != 0) {
            mpw_free( plainBuf, bufSize );
            return NULL;
        }
        for (size_t c = 0; c < bufSize; ++c)
            plainBuf[c] = buf[c] ^ plainBuf[c];
        return plainBuf;
    }
#pragma clang diagnostic pop
#pragma GCC diagnostic pop
#else
#error No crypto support for mpw_aes.
#endif
}

uint8_t const *mpw_aes_encrypt(const uint8_t *key, const size_t keySize, const uint8_t *plainBuf, const size_t bufSize) {

    return mpw_aes( true, key, keySize, plainBuf, bufSize );
}

uint8_t const *mpw_aes_decrypt(const uint8_t *key, const size_t keySize, const uint8_t *cipherBuf, const size_t bufSize) {

    return mpw_aes( false, key, keySize, cipherBuf, bufSize );
}

MPKeyID mpw_id_buf(const void *buf, size_t length) {

    if (!buf)
        return "<unset>";

#if HAS_CPERCIVA
    uint8_t hash[32];
    SHA256_Buf( buf, length, hash );
#elif HAS_SODIUM
    uint8_t hash[crypto_hash_sha256_BYTES];
    crypto_hash_sha256( hash, buf, length );
#else
#error No crypto support for mpw_id_buf.
#endif

    return mpw_hex( hash, sizeof( hash ) / sizeof( uint8_t ) );
}

bool mpw_id_buf_equals(const char *id1, const char *id2) {

    size_t size = strlen( id1 );
    if (size != strlen( id2 ))
        return false;

    for (size_t c = 0; c < size; ++c)
        if (tolower( id1[c] ) != tolower( id2[c] ))
            return false;

    return true;
}

static char *str_str;

const char *mpw_str(const char *format, ...) {

    va_list args;
    va_start( args, format );
    vasprintf( &str_str, format, args );
    va_end( args );

    return str_str;
}

static char **mpw_hex_buf;
static unsigned int mpw_hex_buf_i;

const char *mpw_hex(const void *buf, size_t length) {

    // FIXME: Not thread-safe
    if (!mpw_hex_buf)
        mpw_hex_buf = calloc( 10, sizeof( char * ) );
    mpw_hex_buf_i = (mpw_hex_buf_i + 1) % 10;

    if (mpw_realloc( &mpw_hex_buf[mpw_hex_buf_i], NULL, length * 2 + 1 ))
        for (size_t kH = 0; kH < length; kH++)
            sprintf( &(mpw_hex_buf[mpw_hex_buf_i][kH * 2]), "%02X", ((const uint8_t *)buf)[kH] );

    return mpw_hex_buf[mpw_hex_buf_i];
}

const char *mpw_hex_l(uint32_t number) {

    return mpw_hex( &number, sizeof( number ) );
}

#ifdef COLOR
static int putvari;
static char *putvarc = NULL;
static int termsetup;
static int initputvar() {
    if (!isatty(STDERR_FILENO))
        return 0;
    if (putvarc)
        free( putvarc );
    if (!termsetup) {
        int status;
        if (! (termsetup = (setupterm( NULL, STDERR_FILENO, &status ) == 0 && status == 1))) {
            wrn( "Terminal doesn't support color (setupterm errno %d).\n", status );
            return 0;
        }
    }

    putvarc=(char *)calloc(256, sizeof(char));
    putvari=0;
    return 1;
}
static int putvar(int c) {
    putvarc[putvari++]=c;
    return 0;
}
#endif

const char *mpw_identicon(const char *fullName, const char *masterPassword) {

    const char *leftArm[] = { "╔", "╚", "╰", "═" };
    const char *rightArm[] = { "╗", "╝", "╯", "═" };
    const char *body[] = { "█", "░", "▒", "▓", "☺", "☻" };
    const char *accessory[] = {
            "◈", "◎", "◐", "◑", "◒", "◓", "☀", "☁", "☂", "☃", "☄", "★", "☆", "☎", "☏", "⎈", "⌂", "☘", "☢", "☣",
            "☕", "⌚", "⌛", "⏰", "⚡", "⛄", "⛅", "☔", "♔", "♕", "♖", "♗", "♘", "♙", "♚", "♛", "♜", "♝", "♞", "♟",
            "♨", "♩", "♪", "♫", "⚐", "⚑", "⚔", "⚖", "⚙", "⚠", "⌘", "⏎", "✄", "✆", "✈", "✉", "✌"
    };

    const uint8_t *identiconSeed = mpw_hash_hmac_sha256( (const uint8_t *)masterPassword, strlen( masterPassword ),
            (const uint8_t *)fullName,
            strlen( fullName ) );
    if (!identiconSeed)
        return NULL;

    char *colorString, *resetString;
#ifdef COLOR
    if (initputvar()) {
        uint8_t colorIdentifier = (uint8_t)(identiconSeed[4] % 7 + 1);
        tputs(tparm(tgetstr("AF", NULL), colorIdentifier), 1, putvar);
        colorString = calloc(strlen(putvarc) + 1, sizeof(char));
        strcpy(colorString, putvarc);
        tputs(tgetstr("me", NULL), 1, putvar);
        resetString = calloc(strlen(putvarc) + 1, sizeof(char));
        strcpy(resetString, putvarc);
    } else
#endif
    {
        colorString = calloc( 1, sizeof( char ) );
        resetString = calloc( 1, sizeof( char ) );
    }

    char *identicon = (char *)calloc( 256, sizeof( char ) );
    snprintf( identicon, 256, "%s%s%s%s%s%s",
            colorString,
            leftArm[identiconSeed[0] % (sizeof( leftArm ) / sizeof( leftArm[0] ))],
            body[identiconSeed[1] % (sizeof( body ) / sizeof( body[0] ))],
            rightArm[identiconSeed[2] % (sizeof( rightArm ) / sizeof( rightArm[0] ))],
            accessory[identiconSeed[3] % (sizeof( accessory ) / sizeof( accessory[0] ))],
            resetString );

    mpw_free( identiconSeed, 32 );
    free( colorString );
    free( resetString );
    return identicon;
}

/**
* @return the amount of bytes used by UTF-8 to encode a single character that starts with the given byte.
*/
static int mpw_utf8_sizeof(unsigned char utf8Byte) {

    if (!utf8Byte)
        return 0;
    if ((utf8Byte & 0x80) == 0)
        return 1;
    if ((utf8Byte & 0xC0) != 0xC0)
        return 0;
    if ((utf8Byte & 0xE0) == 0xC0)
        return 2;
    if ((utf8Byte & 0xF0) == 0xE0)
        return 3;
    if ((utf8Byte & 0xF8) == 0xF0)
        return 4;

    return 0;
}

const size_t mpw_utf8_strlen(const char *utf8String) {

    size_t charlen = 0;
    char *remainingString = (char *)utf8String;
    for (int charByteSize; (charByteSize = mpw_utf8_sizeof( (unsigned char)*remainingString )); remainingString += charByteSize)
        ++charlen;

    return charlen;
}
