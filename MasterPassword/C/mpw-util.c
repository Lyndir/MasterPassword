//
//  mpw-util.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-20.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef COLOR
#include <unistd.h>
#include <curses.h>
#include <term.h>
#endif

#include <scrypt/sha256.h>
#include <scrypt/crypto_scrypt.h>

#include "mpw-util.h"

void mpw_pushBuf(uint8_t **const buffer, size_t *const bufferSize, const void *pushBuffer, const size_t pushSize) {

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

void mpw_pushString(uint8_t **buffer, size_t *const bufferSize, const char *pushString) {

    mpw_pushBuf( buffer, bufferSize, pushString, strlen( pushString ) );
}

void mpw_pushInt(uint8_t **const buffer, size_t *const bufferSize, const uint32_t pushInt) {

    mpw_pushBuf( buffer, bufferSize, &pushInt, sizeof( pushInt ) );
}

void mpw_free(const void *buffer, const size_t bufferSize) {

    if (buffer) {
        memset( (void *)buffer, 0, bufferSize );
        free( (void *)buffer );
    }
}

void mpw_freeString(const char *string) {

    mpw_free( string, strlen( string ) );
}

uint8_t const *mpw_scrypt(const size_t keySize, const char *secret, const uint8_t *salt, const size_t saltSize,
        uint64_t N, uint32_t r, uint32_t p) {

    if (!secret || !salt)
        return NULL;

    uint8_t *key = malloc( keySize );
    if (!key)
        return NULL;

    if (crypto_scrypt( (const uint8_t *)secret, strlen( secret ), salt, saltSize, N, r, p, key, keySize ) < 0) {
        mpw_free( key, keySize );
        return NULL;
    }

    return key;
}

uint8_t const *mpw_hmac_sha256(const uint8_t *key, const size_t keySize, const uint8_t *salt, const size_t saltSize) {

    uint8_t *const buffer = malloc( 32 );
    if (!buffer)
        return NULL;

    HMAC_SHA256_Buf( key, keySize, salt, saltSize, buffer );
    return buffer;
}

const char *mpw_idForBuf(const void *buf, size_t length) {

    uint8_t hash[32];
    SHA256_Buf( buf, length, hash );

    return mpw_hex( hash, 32 );
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
static int istermsetup = 0;
static void initputvar() {
    if (putvarc)
        free(putvarc);
    putvarc=(char *)calloc(256, sizeof(char));
    putvari=0;

    if (!istermsetup)
        istermsetup = (OK == setupterm(NULL, STDERR_FILENO, NULL));
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

    uint8_t identiconSeed[32];
    HMAC_SHA256_Buf( masterPassword, strlen( masterPassword ), fullName, strlen( fullName ), identiconSeed );

    char *colorString, *resetString;
#ifdef COLOR
    if (isatty( STDERR_FILENO )) {
        uint8_t colorIdentifier = (uint8_t)(identiconSeed[4] % 7 + 1);
        initputvar();
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

    free( colorString );
    free( resetString );
    return identicon;
}

/**
* @return the amount of bytes used by UTF-8 to encode a single character that starts with the given byte.
*/
static int mpw_charByteSize(unsigned char utf8Byte) {

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

const size_t mpw_charlen(const char *utf8String) {

    size_t charlen = 0;
    char *remainingString = (char *)utf8String;
    for (int charByteSize; (charByteSize = mpw_charByteSize( (unsigned char)*remainingString )); remainingString += charByteSize)
        ++charlen;

    return charlen;
}
