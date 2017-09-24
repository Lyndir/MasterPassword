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

#if MPW_CPERCIVA
#include <scrypt/crypto_scrypt.h>
#include <scrypt/sha256.h>
#elif MPW_SODIUM
#include "sodium.h"
#endif
#define AES_ECB 0
#define AES_CBC 1
#include "aes.h"

#include "mpw-util.h"

#ifdef inf_level
int mpw_verbosity = inf_level;
#endif

void mpw_uint16(const uint16_t number, uint8_t buf[2]) {

    buf[0] = (uint8_t)((number >> 8L) & UINT8_MAX);
    buf[1] = (uint8_t)((number >> 0L) & UINT8_MAX);
}

void mpw_uint32(const uint32_t number, uint8_t buf[4]) {

    buf[0] = (uint8_t)((number >> 24) & UINT8_MAX);
    buf[1] = (uint8_t)((number >> 16) & UINT8_MAX);
    buf[2] = (uint8_t)((number >> 8L) & UINT8_MAX);
    buf[3] = (uint8_t)((number >> 0L) & UINT8_MAX);
}

void mpw_uint64(const uint64_t number, uint8_t buf[8]) {

    buf[0] = (uint8_t)((number >> 56) & UINT8_MAX);
    buf[1] = (uint8_t)((number >> 48) & UINT8_MAX);
    buf[2] = (uint8_t)((number >> 40) & UINT8_MAX);
    buf[3] = (uint8_t)((number >> 32) & UINT8_MAX);
    buf[4] = (uint8_t)((number >> 24) & UINT8_MAX);
    buf[5] = (uint8_t)((number >> 16) & UINT8_MAX);
    buf[6] = (uint8_t)((number >> 8L) & UINT8_MAX);
    buf[7] = (uint8_t)((number >> 0L) & UINT8_MAX);
}

bool mpw_push_buf(uint8_t **buffer, size_t *bufferSize, const void *pushBuffer, const size_t pushSize) {

    if (!buffer || !bufferSize || !pushBuffer || !pushSize)
        return false;
    if (*bufferSize == (size_t)ERR)
        // The buffer was marked as broken, it is missing a previous push.  Abort to avoid corrupt content.
        return false;

    if (!mpw_realloc( buffer, bufferSize, pushSize )) {
        // realloc failed, we can't push.  Mark the buffer as broken.
        mpw_free( buffer, *bufferSize );
        *bufferSize = (size_t)ERR;
        return false;
    }

    uint8_t *bufferOffset = *buffer + *bufferSize - pushSize;
    memcpy( bufferOffset, pushBuffer, pushSize );
    return true;
}

bool mpw_push_string(uint8_t **buffer, size_t *bufferSize, const char *pushString) {

    return pushString && mpw_push_buf( buffer, bufferSize, pushString, strlen( pushString ) );
}

bool mpw_string_push(char **string, const char *pushString) {

    if (!string || !pushString)
        return false;
    if (!*string)
        *string = calloc( 1, sizeof( char ) );

    size_t stringLength = strlen( *string );
    return pushString && mpw_push_buf( (uint8_t **const)string, &stringLength, pushString, strlen( pushString ) + 1 );
}

bool mpw_string_pushf(char **string, const char *pushFormat, ...) {

    va_list args;
    va_start( args, pushFormat );
    bool success = mpw_string_push( string, mpw_vstr( pushFormat, args ) );
    va_end( args );

    return success;
}

bool mpw_push_int(uint8_t **buffer, size_t *bufferSize, const uint32_t pushInt) {

    uint8_t pushBuf[4 /* 32 / 8 */];
    mpw_uint32( pushInt, pushBuf );
    return mpw_push_buf( buffer, bufferSize, &pushBuf, sizeof( pushBuf ) );
}

bool __mpw_realloc(const void **buffer, size_t *bufferSize, const size_t deltaSize) {

    if (!buffer)
        return false;

    void *newBuffer = realloc( (void *)*buffer, (bufferSize? *bufferSize: 0) + deltaSize );
    if (!newBuffer)
        return false;

    *buffer = newBuffer;
    if (bufferSize)
        *bufferSize += deltaSize;

    return true;
}

bool __mpw_free(const void **buffer, const size_t bufferSize) {

    if (!buffer || !*buffer)
        return false;

    memset( (void *)*buffer, 0, bufferSize );
    free( (void *)*buffer );
    *buffer = NULL;

    return true;
}

bool __mpw_free_string(const char **string) {

    return *string && __mpw_free( (const void **)string, strlen( *string ) );
}

bool __mpw_free_strings(const char **strings, ...) {

    bool success = true;

    va_list args;
    va_start( args, strings );
    success &= mpw_free_string( strings );
    for (const char **string; (string = va_arg( args, const char ** ));)
        success &= mpw_free_string( string );
    va_end( args );

    return success;
}

uint8_t const *mpw_kdf_scrypt(const size_t keySize, const char *secret, const uint8_t *salt, const size_t saltSize,
        uint64_t N, uint32_t r, uint32_t p) {

    if (!secret || !salt)
        return NULL;

    uint8_t *key = malloc( keySize );
    if (!key)
        return NULL;

#if MPW_CPERCIVA
    if (crypto_scrypt( (const uint8_t *)secret, strlen( secret ), salt, saltSize, N, r, p, key, keySize ) < 0) {
        mpw_free( &key, keySize );
        return NULL;
    }
#elif MPW_SODIUM
    if (crypto_pwhash_scryptsalsa208sha256_ll( (const uint8_t *)secret, strlen( secret ), salt, saltSize, N, r, p, key, keySize ) != 0) {
        mpw_free( &key, keySize );
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

#if MPW_SODIUM
    if (keySize < crypto_generichash_blake2b_KEYBYTES_MIN || keySize > crypto_generichash_blake2b_KEYBYTES_MAX ||
        subkeySize < crypto_generichash_blake2b_KEYBYTES_MIN || subkeySize > crypto_generichash_blake2b_KEYBYTES_MAX ||
        (personal && strlen( personal ) > crypto_generichash_blake2b_PERSONALBYTES)) {
        errno = EINVAL;
        free( subkey );
        return NULL;
    }

    uint8_t saltBuf[crypto_generichash_blake2b_SALTBYTES];
    bzero( saltBuf, sizeof saltBuf );
    if (id)
        mpw_uint64( id, saltBuf );

    uint8_t personalBuf[crypto_generichash_blake2b_PERSONALBYTES];
    bzero( personalBuf, sizeof saltBuf );
    if (personal && strlen( personal ))
        memcpy( personalBuf, personal, strlen( personal ) );

    if (crypto_generichash_blake2b_salt_personal( subkey, subkeySize, context, contextSize, key, keySize, saltBuf, personalBuf ) != 0) {
        mpw_free( &subkey, subkeySize );
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

#if MPW_CPERCIVA
    uint8_t *const mac = malloc( 32 );
    if (!mac)
        return NULL;

    HMAC_SHA256_Buf( key, keySize, message, messageSize, mac );
#elif MPW_SODIUM
    uint8_t *const mac = malloc( crypto_auth_hmacsha256_BYTES );
    if (!mac)
        return NULL;

    crypto_auth_hmacsha256_state state;
    if (crypto_auth_hmacsha256_init( &state, key, keySize ) != 0 ||
        crypto_auth_hmacsha256_update( &state, message, messageSize ) != 0 ||
        crypto_auth_hmacsha256_final( &state, mac ) != 0) {
        mpw_free( &mac, crypto_auth_hmacsha256_BYTES );
        return NULL;
    }
#else
#error No crypto support for mpw_hmac_sha256.
#endif

    return mac;
}

static uint8_t const *mpw_aes(bool encrypt, const uint8_t *key, const size_t keySize, const uint8_t *buf, size_t *bufSize) {

    if (!key || keySize < 16)
        return NULL;

    // IV = zero
    uint8_t iv[16];
    bzero( (void *)iv, sizeof( iv ) );

    // Add PKCS#7 padding
    uint32_t aesSize = (uint32_t)*bufSize;
    if (encrypt)
        aesSize = (aesSize / 16) * 16 + 16;
    uint8_t aesBuf[aesSize];
    memcpy( aesBuf, buf, *bufSize );
    memset( aesBuf + *bufSize, aesSize - *bufSize, aesSize - *bufSize );
    uint8_t *resultBuf = malloc( aesSize );

    if (encrypt)
        AES_CBC_encrypt_buffer( resultBuf, aesBuf, aesSize, key, iv );
    else
        AES_CBC_decrypt_buffer( resultBuf, aesBuf, aesSize, key, iv );
    bzero( aesBuf, aesSize );
    bzero( iv, 16 );

    // Truncate PKCS#7 padding
    if (encrypt)
        *bufSize = aesSize;
    else
        *bufSize -= resultBuf[aesSize - 1];

    return resultBuf;
}

uint8_t const *mpw_aes_encrypt(const uint8_t *key, const size_t keySize, const uint8_t *plainBuf, size_t *bufSize) {

    return mpw_aes( true, key, keySize, plainBuf, bufSize );
}

uint8_t const *mpw_aes_decrypt(const uint8_t *key, const size_t keySize, const uint8_t *cipherBuf, size_t *bufSize) {

    return mpw_aes( false, key, keySize, cipherBuf, bufSize );
}

#if UNUSED
const char *mpw_hotp(const uint8_t *key, size_t keySize, uint64_t movingFactor, uint8_t digits, uint8_t truncationOffset) {

    // Hash the moving factor with the key.
    uint8_t counter[8];
    mpw_uint64( movingFactor, counter );
    uint8_t hash[20];
    hmac_sha1( key, keySize, counter, sizeof( counter ), hash );

    // Determine the offset to select OTP bytes from.
    int offset;
    if ((truncationOffset >= 0) && (truncationOffset < (sizeof( hash ) - 4)))
        offset = truncationOffset;
    else
        offset = hash[sizeof( hash ) - 1] & 0xf;

    // Select four bytes from the truncation offset.
    uint32_t otp = 0U
            | ((hash[offset + 0] & 0x7f) << 24)
            | ((hash[offset + 1] & 0xff) << 16)
            | ((hash[offset + 2] & 0xff) << 8)
            | ((hash[offset + 3] & 0xff) << 0);

    // Render the OTP as `digits` decimal digits.
    otp %= (int)pow(10, digits);
    return strdup( mpw_str( "%0*d", digits, otp ) );
}
#endif

MPKeyID mpw_id_buf(const void *buf, size_t length) {

    if (!buf)
        return "<unset>";

#if MPW_CPERCIVA
    uint8_t hash[32];
    SHA256_Buf( buf, length, hash );
#elif MPW_SODIUM
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

const char *mpw_str(const char *format, ...) {

    va_list args;
    va_start( args, format );
    const char *str_str = mpw_vstr( format, args );
    va_end( args );

    return str_str;
}

const char *mpw_vstr(const char *format, va_list args) {

    // TODO: We should find a way to get rid of this shared storage medium.
    // TODO: Not thread-safe
    static char *str_str;
    static size_t str_str_max;
    if (!str_str && !(str_str = calloc( str_str_max = 1, sizeof( char ) )))
        return NULL;

    do {
        va_list args_attempt;
        va_copy( args_attempt, args );
        size_t len = (size_t)vsnprintf( str_str, str_str_max, format, args_attempt );
        va_end( args_attempt );

        if ((int)len < 0)
            return NULL;
        if (len < str_str_max)
            break;

        if (!mpw_realloc( &str_str, &str_str_max, len - str_str_max + 1 ))
            return NULL;
    } while (true);

    return str_str;
}

const char *mpw_hex(const void *buf, size_t length) {

    // TODO: We should find a way to get rid of this shared storage medium.
    // TODO: Not thread-safe
    static char **mpw_hex_buf;
    static unsigned int mpw_hex_buf_i;

    if (!mpw_hex_buf)
        mpw_hex_buf = calloc( 10, sizeof( char * ) );
    mpw_hex_buf_i = (mpw_hex_buf_i + 1) % 10;

    if (mpw_realloc( &mpw_hex_buf[mpw_hex_buf_i], NULL, length * 2 + 1 ))
        for (size_t kH = 0; kH < length; kH++)
            sprintf( &(mpw_hex_buf[mpw_hex_buf_i][kH * 2]), "%02X", ((const uint8_t *)buf)[kH] );

    return mpw_hex_buf[mpw_hex_buf_i];
}

const char *mpw_hex_l(uint32_t number) {

    uint8_t buf[4 /* 32 / 8 */];
    buf[0] = (uint8_t)((number >> 24) & UINT8_MAX);
    buf[1] = (uint8_t)((number >> 16) & UINT8_MAX);
    buf[2] = (uint8_t)((number >> 8L) & UINT8_MAX);
    buf[3] = (uint8_t)((number >> 0L) & UINT8_MAX);
    return mpw_hex( &buf, sizeof( buf ) );
}

#if MPW_COLOR
static char *str_tputs;
static int str_tputs_cursor;
static const int str_tputs_max = 256;

static bool mpw_setupterm() {

    if (!isatty( STDERR_FILENO ))
        return false;

    static bool termsetup;
    if (!termsetup) {
        int errret;
        if (!(termsetup = (setupterm( NULL, STDERR_FILENO, &errret ) == OK))) {
            wrn( "Terminal doesn't support color (setupterm errret %d).\n", errret );
            return false;
        }
    }

    return true;
}

static int mpw_tputc(int c) {

    if (++str_tputs_cursor < str_tputs_max) {
        str_tputs[str_tputs_cursor] = (char)c;
        return OK;
    }

    return ERR;
}

static char *mpw_tputs(const char *str, int affcnt) {

    if (str_tputs)
        mpw_free( &str_tputs, str_tputs_max );
    str_tputs = calloc( str_tputs_max, sizeof( char ) );
    str_tputs_cursor = -1;

    char *result = tputs( str, affcnt, mpw_tputc ) == ERR? NULL: strndup( str_tputs, str_tputs_max );
    if (str_tputs)
        mpw_free( &str_tputs, str_tputs_max );

    return result;
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

    const uint8_t *identiconSeed = mpw_hash_hmac_sha256(
            (const uint8_t *)masterPassword, strlen( masterPassword ),
            (const uint8_t *)fullName, strlen( fullName ) );
    if (!identiconSeed)
        return NULL;

    char *colorString, *resetString;
#ifdef MPW_COLOR
    if (mpw_setupterm()) {
        uint8_t colorIdentifier = (uint8_t)(identiconSeed[4] % 7 + 1);
        colorString = mpw_tputs( tparm( tgetstr( "AF", NULL ), colorIdentifier ), 1 );
        resetString = mpw_tputs( tgetstr( "me", NULL ), 1 );
    }
    else
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

    mpw_free( &identiconSeed, 32 );
    mpw_free_strings( &colorString, &resetString, NULL );
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
