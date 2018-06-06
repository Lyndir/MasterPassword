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

#ifndef _MPW_UTIL_H
#define _MPW_UTIL_H

#include <stdio.h>
#include <stdarg.h>

#include "mpw-types.h"

//// Logging.
extern int mpw_verbosity;

#ifndef mpw_log_do
#define mpw_log_do(level, format, ...) \
    fprintf( stderr, format "\n", ##__VA_ARGS__ )
#endif

#ifndef mpw_log
#define mpw_log(level, ...) ({ \
    if (mpw_verbosity >= level) { \
        mpw_log_do( level, ##__VA_ARGS__ ); \
    }; })
#endif

#ifndef trc
/** Logging internal state. */
#define trc_level 3
#define trc(...) mpw_log( trc_level, ##__VA_ARGS__ )

/** Logging state and events interesting when investigating issues. */
#define dbg_level 2
#define dbg(...) mpw_log( dbg_level, ##__VA_ARGS__ )

/** User messages. */
#define inf_level 1
#define inf(...) mpw_log( inf_level, ##__VA_ARGS__ )

/** Recoverable issues and user suggestions. */
#define wrn_level 0
#define wrn(...) mpw_log( wrn_level, ##__VA_ARGS__ )

/** Unrecoverable issues. */
#define err_level -1
#define err(...) mpw_log( err_level, ##__VA_ARGS__ )

/** Issues that lead to abortion. */
#define ftl_level -2
#define ftl(...) mpw_log( ftl_level, ##__VA_ARGS__ )
#endif

#ifndef min
#define min(a, b) ({ \
    __typeof__ (a) _a = (a); \
    __typeof__ (b) _b = (b); \
    _a < _b ? _a : _b; })
#endif
#ifndef max
#define max(a, b) ({ \
    __typeof__ (a) _a = (a); \
    __typeof__ (b) _b = (b); \
    _a > _b ? _a : _b; })
#endif
#ifndef ERR
#define ERR -1
#endif
#ifndef OK
#define OK 0
#endif
#ifndef stringify
#define stringify(s) #s
#endif
#ifndef stringify_def
#define stringify_def(s) stringify(s)
#endif

//// Buffers and memory.

/** Write a number to a byte buffer using mpw's endianness (big/network endian). */
void mpw_uint16(const uint16_t number, uint8_t buf[2]);
void mpw_uint32(const uint32_t number, uint8_t buf[4]);
void mpw_uint64(const uint64_t number, uint8_t buf[8]);

/** Allocate a new array of _type, assign its element count to _count if not NULL and populate it with the varargs. */
#define mpw_alloc_array(_count, _type, ...) ({ \
    _type stackElements[] = { __VA_ARGS__ }; \
    if (_count) \
        *_count = sizeof( stackElements ) / sizeof( _type ); \
    _type *allocElements = malloc( sizeof( stackElements ) ); \
    memcpy( allocElements, stackElements, sizeof( stackElements ) ); \
    allocElements; \
 })

/** Push a buffer onto a buffer.  reallocs the given buffer and appends the given buffer. */
bool mpw_push_buf(
        uint8_t **buffer, size_t *bufferSize, const void *pushBuffer, const size_t pushSize);
/** Push a string onto a buffer.  reallocs the given buffer and appends the given string. */
bool mpw_push_string(
        uint8_t **buffer, size_t *bufferSize, const char *pushString);
/** Push a string onto another string.  reallocs the target string and appends the source string. */
bool mpw_string_push(
        char **string, const char *pushString);
bool mpw_string_pushf(
        char **string, const char *pushFormat, ...);
/** Push an integer onto a buffer.  reallocs the given buffer and appends the given integer. */
bool mpw_push_int(
        uint8_t **buffer, size_t *bufferSize, const uint32_t pushInt);
/** Reallocate the given buffer from the given size by adding the delta size.
  * On success, the buffer size pointer will be updated to the buffer's new size
  * and the buffer pointer may be updated to a new memory address.
  * On failure, the buffer and pointers will remain unaffected.
  * @param buffer A pointer to the buffer to reallocate.
  * @param bufferSize A pointer to the buffer's actual size.
  * @param deltaSize The amount to increase the buffer's size by.
  * @return true if successful, false if reallocation failed.
  */
#define mpw_realloc(buffer, bufferSize, deltaSize) \
        ({ __typeof__(buffer) _b = buffer; const void *__b = *_b; (void)__b; __mpw_realloc( (const void **)_b, bufferSize, deltaSize ); })
bool __mpw_realloc(const void **buffer, size_t *bufferSize, const size_t deltaSize);
void mpw_zero(
        void *buffer, size_t bufferSize);
/** Free a buffer after zero'ing its contents, then set the reference to NULL. */
#define mpw_free(buffer, bufferSize) \
        ({ __typeof__(buffer) _b = buffer; const void *__b = *_b; (void)__b; __mpw_free( (void **)_b, bufferSize ); })
bool __mpw_free(
        void **buffer, size_t bufferSize);
/** Free a string after zero'ing its contents, then set the reference to NULL. */
#define mpw_free_string(string) \
        ({ __typeof__(string) _s = string; const char *__s = *_s; (void)__s; __mpw_free_string( (char **)_s ); })
bool __mpw_free_string(
        char **string);
/** Free strings after zero'ing their contents, then set the references to NULL.  Terminate the va_list with NULL. */
#define mpw_free_strings(strings, ...) \
        ({ __typeof__(strings) _s = strings; const char *__s = *_s; (void)__s; __mpw_free_strings( (char **)_s, __VA_ARGS__ ); })
bool __mpw_free_strings(
        char **strings, ...);

//// Cryptographic functions.

/** Derive a key from the given secret and salt using the scrypt KDF.
  * @return A new keySize allocated buffer containing the key. */
uint8_t const *mpw_kdf_scrypt(
        const size_t keySize, const uint8_t *secret, const size_t secretSize, const uint8_t *salt, const size_t saltSize,
        uint64_t N, uint32_t r, uint32_t p);
/** Derive a subkey from the given key using the blake2b KDF.
  * @return A new keySize allocated buffer containing the key. */
uint8_t const *mpw_kdf_blake2b(
        const size_t subkeySize, const uint8_t *key, const size_t keySize,
        const uint8_t *context, const size_t contextSize, const uint64_t id, const char *personal);
/** Calculate the MAC for the given message with the given key using SHA256-HMAC.
  * @return A new 32-byte allocated buffer containing the MAC. */
uint8_t const *mpw_hash_hmac_sha256(
        const uint8_t *key, const size_t keySize, const uint8_t *salt, const size_t saltSize);
/** Encrypt a plainBuf with the given key using AES-128-CBC.
  * @return A new bufSize allocated buffer containing the cipherBuf. */
uint8_t const *mpw_aes_encrypt(
        const uint8_t *key, const size_t keySize, const uint8_t *plainBuf, size_t *bufSize);
/** Decrypt a cipherBuf with the given key using AES-128-CBC.
  * @return A new bufSize allocated buffer containing the plainBuf. */
uint8_t const *mpw_aes_decrypt(
        const uint8_t *key, const size_t keySize, const uint8_t *cipherBuf, size_t *bufSize);
/** Calculate an OTP using RFC-4226.
  * @return A newly allocated string containing exactly `digits` decimal OTP digits. */
#if UNUSED
const char *mpw_hotp(
        const uint8_t *key, size_t keySize, uint64_t movingFactor, uint8_t digits, uint8_t truncationOffset);
#endif

//// Visualizers.

/** Compose a formatted string.
  * @return A C-string in a reused buffer, do not free or store it. */
const char *mpw_str(const char *format, ...);
const char *mpw_vstr(const char *format, va_list args);
/** Encode a buffer as a string of hexadecimal characters.
  * @return A C-string in a reused buffer, do not free or store it. */
const char *mpw_hex(const void *buf, size_t length);
const char *mpw_hex_l(uint32_t number);
/** Encode a fingerprint for a buffer.
  * @return A C-string in a reused buffer, do not free or store it. */
MPKeyID mpw_id_buf(const void *buf, size_t length);
/** Compare two fingerprints for equality.
  * @return true if the buffers represent identical fingerprints. */
bool mpw_id_buf_equals(const char *id1, const char *id2);

//// String utilities.

/** @return The amount of display characters in the given UTF-8 string. */
const size_t mpw_utf8_strlen(const char *utf8String);
/** Drop-in for POSIX strdup(3). */
char *mpw_strdup(const char *src);
/** Drop-in for POSIX strndup(3). */
char *mpw_strndup(const char *src, size_t max);

#endif // _MPW_UTIL_H
