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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if COLOR
#include <unistd.h>
#include <curses.h>
#include <term.h>
#endif

#if HAS_CPERCIVA
#include <scrypt/crypto_scrypt.h>
#include <scrypt/sha256.h>
#elif HAS_SODIUM
#include "sodium.h"
#endif

#ifndef trc
int mpw_verbosity;
#endif

#include "mpw-util.h"

void mpw_push_buf(uint8_t **const buffer, size_t *const bufferSize, const void *pushBuffer, const size_t pushSize) {

    if (*bufferSize == (size_t)-1)
        // The buffer was marked as broken, it is missing a previous push.  Abort to avoid corrupt content.
        return;

    *bufferSize += pushSize;
    uint8_t *resizedBuffer = realloc( *buffer, *bufferSize );
    if (!resizedBuffer) {
        // realloc failed, we can't push.  Mark the buffer as broken.
        mpw_free( *buffer, *bufferSize - pushSize );
        *bufferSize = (size_t)-1;
        *buffer = NULL;
        return;
    }

    *buffer = resizedBuffer;
    uint8_t *pushDst = *buffer + *bufferSize - pushSize;
    memcpy( pushDst, pushBuffer, pushSize );
}

void mpw_push_string(uint8_t **buffer, size_t *const bufferSize, const char *pushString) {

    mpw_push_buf( buffer, bufferSize, pushString, strlen( pushString ) );
}

void mpw_push_int(uint8_t **const buffer, size_t *const bufferSize, const uint32_t pushInt) {

    mpw_push_buf( buffer, bufferSize, &pushInt, sizeof( pushInt ) );
}

void mpw_free(const void *buffer, const size_t bufferSize) {

    if (buffer) {
        memset( (void *)buffer, 0, bufferSize );
        free( (void *)buffer );
    }
}

void mpw_free_string(const char *string) {

    mpw_free( string, strlen( string ) );
}

uint8_t const *mpw_scrypt(const size_t keySize, const char *secret, const uint8_t *salt, const size_t saltSize,
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
    if (crypto_pwhash_scryptsalsa208sha256_ll( (const uint8_t *)secret, strlen( secret ), salt, saltSize, N, r, p, key, keySize) != 0 ) {
        mpw_free( key, keySize );
        return NULL;
    }
#endif

    return key;
}

uint8_t const *mpw_hmac_sha256(const uint8_t *key, const size_t keySize, const uint8_t *salt, const size_t saltSize) {

#if HAS_CPERCIVA
    uint8_t *const buffer = malloc( 32 );
    if (!buffer)
        return NULL;

    HMAC_SHA256_Buf( key, keySize, salt, saltSize, buffer );
    return buffer;
#elif HAS_SODIUM
    uint8_t *const buffer = malloc( crypto_auth_hmacsha256_BYTES );
    if (!buffer)
        return NULL;

    crypto_auth_hmacsha256_state state;
    if (crypto_auth_hmacsha256_init( &state, key, keySize ) != 0 ||
        crypto_auth_hmacsha256_update( &state, salt, saltSize ) != 0 ||
        crypto_auth_hmacsha256_final( &state, buffer ) != 0) {
        mpw_free( buffer, crypto_auth_hmacsha256_BYTES );
        return NULL;
    }

    return buffer;
#endif

    return NULL;
}

const char *mpw_id_buf(const void *buf, size_t length) {

#if HAS_CPERCIVA
    uint8_t hash[32];
    SHA256_Buf( buf, length, hash );

    return mpw_hex( hash, 32 );
#elif HAS_SODIUM
    uint8_t hash[crypto_hash_sha256_BYTES];
    crypto_hash_sha256( hash, buf, length );

    return mpw_hex( hash, crypto_hash_sha256_BYTES );
#endif
}

static char **mpw_hex_buf = NULL;
static unsigned int mpw_hex_buf_i = 0;

const char *mpw_hex(const void *buf, size_t length) {

    // FIXME
    if (!mpw_hex_buf) {
        mpw_hex_buf = malloc( 10 * sizeof( char * ) );
        for (uint8_t i = 0; i < 10; ++i)
            mpw_hex_buf[i] = NULL;
    }
    mpw_hex_buf_i = (mpw_hex_buf_i + 1) % 10;

    mpw_hex_buf[mpw_hex_buf_i] = realloc( mpw_hex_buf[mpw_hex_buf_i], length * 2 + 1 );
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

    const uint8_t *identiconSeed = mpw_hmac_sha256( (const uint8_t *)masterPassword, strlen( masterPassword ), (const uint8_t *)fullName, strlen( fullName ) );
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
