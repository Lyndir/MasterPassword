/*	$OpenBSD: bcrypt.c,v 1.57 2016/08/26 08:25:02 guenther Exp $	*/

/*
 * Copyright (c) 2014 Ted Unangst <tedu@openbsd.org>
 * Copyright (c) 1997 Niels Provos <provos@umich.edu>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
/* This password hashing algorithm was designed by David Mazieres
 * <dm@lcs.mit.edu> and works as follows:
 *
 * 1. state := InitState ()
 * 2. state := ExpandKey (state, salt, password)
 * 3. REPEAT rounds:
 *      state := ExpandKey (state, 0, password)
 *	state := ExpandKey (state, 0, salt)
 * 4. ctext := "OrpheanBeholderScryDoubt"
 * 5. REPEAT 64:
 * 	ctext := Encrypt_ECB (state, ctext);
 * 6. RETURN Concatenate (salt, ctext);
 *
 */

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "blf.h"
#include "blowfish.h"
#include "mpw-util.h"

/* This implementation is adaptable to current computing power.
 * You can have up to 2^31 rounds which should be enough for some
 * time to come.
 */

#define BCRYPT_VERSION '2'
#define BCRYPT_MAXSALT 16    /* Precomputation is just so nice */
#define BCRYPT_WORDS 6        /* Ciphertext words */
#define BCRYPT_MINLOGROUNDS 4    /* we have log2(rounds) in salt */

#define    BCRYPT_SALTSPACE    (7 + (BCRYPT_MAXSALT * 4 + 2) / 3 + 1)
#define    BCRYPT_HASHSPACE    61

static int encode_base64(char *, const uint8_t *, size_t);
static int decode_base64(uint8_t *, size_t, const char *);

/*
 * Generates a salt for this version of crypt.
 */
static int
bcrypt_initsalt(int log_rounds, uint8_t *salt, size_t saltbuflen) {

    uint8_t csalt[BCRYPT_MAXSALT];

    if (saltbuflen < BCRYPT_SALTSPACE) {
        errno = EINVAL;
        return -1;
    }

    arc4random_buf( csalt, sizeof( csalt ) );

    if (log_rounds < 4)
        log_rounds = 4;
    else if (log_rounds > 31)
        log_rounds = 31;

    snprintf( (char *)salt, saltbuflen, "$2b$%2.2u$", log_rounds );
    encode_base64( (char *)salt + 7, csalt, sizeof( csalt ) );

    return 0;
}

/*
 * the core bcrypt function
 */
static int
bcrypt_hashpass(const char *key, const uint8_t *salt, char *encrypted,
        size_t encryptedlen) {

    blf_ctx state;
    uint32_t rounds, i, k;
    uint16_t j;
    size_t key_len;
    uint8_t salt_len, logr, minor;
    uint8_t ciphertext[4 * BCRYPT_WORDS] = "OrpheanBeholderScryDoubt";
    uint8_t csalt[BCRYPT_MAXSALT];
    uint32_t cdata[BCRYPT_WORDS];

    if (encryptedlen < BCRYPT_HASHSPACE)
        goto inval;

    /* Check and discard "$" identifier */
    if (salt[0] != '$')
        goto inval;
    salt += 1;

    if (salt[0] != BCRYPT_VERSION)
        goto inval;

    /* Check for minor versions */
    switch ((minor = salt[1])) {
        case 'a':
            key_len = (uint8_t)(strlen( key ) + 1);
            break;
        case 'b':
            /* strlen() returns a size_t, but the function calls
             * below result in implicit casts to a narrower integer
             * type, so cap key_len at the actual maximum supported
             * length here to avoid integer wraparound */
            key_len = strlen( key );
            if (key_len > 72)
                key_len = 72;
            key_len++; /* include the NUL */
            break;
        default:
            goto inval;
    }
    if (salt[2] != '$')
        goto inval;
    /* Discard version + "$" identifier */
    salt += 3;

    /* Check and parse num rounds */
    if (!isdigit( (unsigned char)salt[0] ) ||
        !isdigit( (unsigned char)salt[1] ) || salt[2] != '$')
        goto inval;
    logr = (uint8_t)((salt[1] - '0') + ((salt[0] - '0') * 10));
    if (logr < BCRYPT_MINLOGROUNDS || logr > 31)
        goto inval;
    /* Computer power doesn't increase linearly, 2^x should be fine */
    rounds = 1U << logr;

    /* Discard num rounds + "$" identifier */
    salt += 3;

    if (strlen( (char *)salt ) * 3 / 4 < BCRYPT_MAXSALT)
        goto inval;

    /* We dont want the base64 salt but the raw data */
    if (decode_base64( csalt, BCRYPT_MAXSALT, (char *)salt ))
        goto inval;
    salt_len = BCRYPT_MAXSALT;

    /* Setting up S-Boxes and Subkeys */
    Blowfish_initstate( &state );
    Blowfish_expandstate( &state, csalt, salt_len,
            (uint8_t *)key, (uint16_t)key_len );
    for (k = 0; k < rounds; k++) {
        Blowfish_expand0state( &state, (uint8_t *)key, (uint16_t)key_len );
        Blowfish_expand0state( &state, csalt, salt_len );
    }

    /* This can be precomputed later */
    j = 0;
    for (i = 0; i < BCRYPT_WORDS; i++)
        cdata[i] = Blowfish_stream2word( ciphertext, 4 * BCRYPT_WORDS, &j );

    /* Now do the encryption */
    for (k = 0; k < 64; k++)
        blf_enc( &state, cdata, BCRYPT_WORDS / 2 );

    for (i = 0; i < BCRYPT_WORDS; i++) {
        ciphertext[4 * i + 3] = (uint8_t)(cdata[i] & 0xff);
        cdata[i] = cdata[i] >> 8;
        ciphertext[4 * i + 2] = (uint8_t)(cdata[i] & 0xff);
        cdata[i] = cdata[i] >> 8;
        ciphertext[4 * i + 1] = (uint8_t)(cdata[i] & 0xff);
        cdata[i] = cdata[i] >> 8;
        ciphertext[4 * i + 0] = (uint8_t)(cdata[i] & 0xff);
    }

    snprintf( encrypted, 8, "$2%c$%2.2u$", minor, logr );
    encode_base64( encrypted + 7, csalt, BCRYPT_MAXSALT );
    encode_base64( encrypted + 7 + 22, ciphertext, 4 * BCRYPT_WORDS - 1 );
    mpw_zero( &state, sizeof state );
    mpw_zero( ciphertext, sizeof ciphertext );
    mpw_zero( csalt, sizeof csalt );
    mpw_zero( cdata, sizeof cdata );
    return 0;

    inval:
    errno = EINVAL;
    return -1;
}

/*
 * internal utilities
 */
static const uint8_t Base64Code[] =
        "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

static const uint8_t index_64[128] = {
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
        255, 255, 255, 255, 255, 255, 0, 1, 54, 55,
        56, 57, 58, 59, 60, 61, 62, 63, 255, 255,
        255, 255, 255, 255, 255, 2, 3, 4, 5, 6,
        7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27,
        255, 255, 255, 255, 255, 255, 28, 29, 30,
        31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
        51, 52, 53, 255, 255, 255, 255, 255
};
#define CHAR64(c)  ( (c) > 127 ? (uint8_t)255 : index_64[(c)])

/*
 * read buflen (after decoding) bytes of data from b64data
 */
static int
decode_base64(uint8_t *buffer, size_t len, const char *b64data) {

    uint8_t *bp = buffer;
    const uint8_t *p = (uint8_t *)b64data;
    uint8_t c1, c2, c3, c4;

    while (bp < buffer + len) {
        c1 = CHAR64( *p );
        /* Invalid data */
        if (c1 == 255)
            return -1;

        c2 = CHAR64( *(p + 1) );
        if (c2 == 255)
            return -1;

        *bp++ = (uint8_t)((c1 << 2) | ((c2 & 0x30) >> 4));
        if (bp >= buffer + len)
            break;

        c3 = CHAR64( *(p + 2) );
        if (c3 == 255)
            return -1;

        *bp++ = (uint8_t)(((c2 & 0x0f) << 4) | ((c3 & 0x3c) >> 2));
        if (bp >= buffer + len)
            break;

        c4 = CHAR64( *(p + 3) );
        if (c4 == 255)
            return -1;
        *bp++ = (uint8_t)(((c3 & 0x03) << 6) | c4);

        p += 4;
    }
    return 0;
}

/*
 * Turn len bytes of data into base64 encoded data.
 * This works without = padding.
 */
static int
encode_base64(char *b64buffer, const uint8_t *data, size_t len) {

    uint8_t *bp = (uint8_t *)b64buffer;
    const uint8_t *p = data;
    uint8_t c1, c2;

    while (p < data + len) {
        c1 = *p++;
        *bp++ = Base64Code[(c1 >> 2)];
        c1 = (uint8_t)((c1 & 0x03) << 4);
        if (p >= data + len) {
            *bp++ = Base64Code[c1];
            break;
        }
        c2 = *p++;
        c1 |= (c2 >> 4) & 0x0f;
        *bp++ = Base64Code[c1];
        c1 = (uint8_t)((c2 & 0x0f) << 2);
        if (p >= data + len) {
            *bp++ = Base64Code[c1];
            break;
        }
        c2 = *p++;
        c1 |= (c2 >> 6) & 0x03;
        *bp++ = Base64Code[c1];
        *bp++ = Base64Code[c2 & 0x3f];
    }
    *bp = '\0';
    return 0;
}

/*
 * classic interface
 */
static uint8_t *
bcrypt_gensalt(uint8_t log_rounds) {

    static uint8_t gsalt[BCRYPT_SALTSPACE];

    bcrypt_initsalt( log_rounds, gsalt, sizeof( gsalt ) );

    return gsalt;
}

static char *
bcrypt(const char *pass, const uint8_t *salt) {

    static char gencrypted[BCRYPT_HASHSPACE];

    if (bcrypt_hashpass( pass, salt, gencrypted, sizeof( gencrypted ) ) != 0)
        return NULL;

    return gencrypted;
}
