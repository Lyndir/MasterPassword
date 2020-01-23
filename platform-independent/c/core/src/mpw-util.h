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
#ifndef trc
extern int mpw_verbosity;

#ifndef mpw_log_do
#define mpw_log_do(level, format, ...) \
    fprintf( stderr, format "\n", ##__VA_ARGS__ )
#endif

#ifndef mpw_log
#define mpw_log(level, format, ...) do { \
    if (mpw_verbosity >= level) { \
        mpw_log_do( level, format, ##__VA_ARGS__ ); \
    }; } while (0)
#endif

/** Logging internal state. */
#define trc_level 3
#define trc(format, ...) mpw_log( trc_level, format, ##__VA_ARGS__ )

/** Logging state and events interesting when investigating issues. */
#define dbg_level 2
#define dbg(format, ...) mpw_log( dbg_level, format, ##__VA_ARGS__ )

/** User messages. */
#define inf_level 1
#define inf(format, ...) mpw_log( inf_level, format, ##__VA_ARGS__ )

/** Recoverable issues and user suggestions. */
#define wrn_level 0
#define wrn(format, ...) mpw_log( wrn_level, format, ##__VA_ARGS__ )

/** Unrecoverable issues. */
#define err_level -1
#define err(format, ...) mpw_log( err_level, format, ##__VA_ARGS__ )

/** Issues that lead to abortion. */
#define ftl_level -2
#define ftl(format, ...) mpw_log( ftl_level, format, ##__VA_ARGS__ )
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

/** @return An array of strings (allocated, count) or NULL if no strings were given or we could not allocate space for the new array. */
const char **mpw_strings(
        size_t *count, const char *strings, ...);

/** Push a buffer onto a buffer.  reallocs the given buffer and appends the given buffer.
 * @param buffer A pointer to the buffer (allocated, bufferSize) to append to, may be NULL. */
bool mpw_push_buf(
        uint8_t **buffer, size_t *bufferSize, const void *pushBuffer, const size_t pushSize);
/** Push an integer onto a buffer.  reallocs the given buffer and appends the given integer.
 * @param buffer A pointer to the buffer (allocated, bufferSize) to append to, may be NULL. */
bool mpw_push_int(
        uint8_t **buffer, size_t *bufferSize, const uint32_t pushInt);
/** Push a string onto a buffer.  reallocs the given buffer and appends the given string.
 * @param buffer A pointer to the buffer (allocated, bufferSize) to append to, may be NULL. */
bool mpw_push_string(
        uint8_t **buffer, size_t *bufferSize, const char *pushString);
/** Push a string onto another string.  reallocs the target string and appends the source string.
 * @param string A pointer to the string (allocated) to append to, may be NULL. */
bool mpw_string_push(
        char **string, const char *pushString);
bool mpw_string_pushf(
        char **string, const char *pushFormat, ...);

// These defines merely exist to force the void** cast (& do type-checking), since void** casts are not automatic.
/** Reallocate the given buffer from the given size by adding the delta size.
 * On success, the buffer size pointer will be updated to the buffer's new size
 * and the buffer pointer may be updated to a new memory address.
 * On failure, the pointers will remain unaffected.
 * @param buffer A pointer to the buffer (allocated, bufferSize) to reallocate.
 * @param bufferSize A pointer to the buffer's current size.
 * @param deltaSize The amount to increase the buffer's size by.
 * @return true if successful, false if reallocation failed.
 */
#define mpw_realloc(\
        /* const void** */buffer, /* size_t* */bufferSize, /* const size_t */deltaSize) \
        ({ __typeof__(buffer) _b = buffer; const void *__b = *_b; (void)__b; __mpw_realloc( (const void **)_b, bufferSize, deltaSize ); })
/** Free a buffer after zero'ing its contents, then set the reference to NULL.
 * @param bufferSize The byte-size of the buffer, these bytes will be zeroed prior to deallocation. */
#define mpw_free(\
        /* void** */buffer, /* size_t */ bufferSize) \
        ({ __typeof__(buffer) _b = buffer; const void *__b = *_b; (void)__b; __mpw_free( (void **)_b, bufferSize ); })
/** Free a string after zero'ing its contents, then set the reference to NULL. */
#define mpw_free_string(\
        /* char** */string) \
        ({ __typeof__(string) _s = string; const char *__s = *_s; (void)__s; __mpw_free_string( (char **)_s ); })
/** Free strings after zero'ing their contents, then set the references to NULL.  Terminate the va_list with NULL. */
#define mpw_free_strings(\
        /* char** */strings, ...) \
        ({ __typeof__(strings) _s = strings; const char *__s = *_s; (void)__s; __mpw_free_strings( (char **)_s, __VA_ARGS__ ); })
/** Free a string after zero'ing its contents, then set the reference to the replacement string.
 * The replacement string is generated before the original is freed; so it can be a derivative of the original. */
#define mpw_replace_string(\
        /* char* */string, /* char* */replacement) \
        do { const char *replacement_ = replacement; mpw_free_string( &string ); string = replacement_; } while (0)
#ifdef _MSC_VER
#undef mpw_realloc
#define mpw_realloc(buffer, bufferSize, deltaSize) \
        __mpw_realloc( (const void **)buffer, bufferSize, deltaSize )
#undef mpw_free
#define mpw_free(buffer, bufferSize) \
        __mpw_free( (void **)buffer, bufferSize )
#undef mpw_free_string
#define mpw_free_string(string) \
        __mpw_free_string( (char **)string )
#undef mpw_free_strings
#define mpw_free_strings(strings, ...) \
        __mpw_free_strings( (char **)strings, __VA_ARGS__ )
#endif
bool __mpw_realloc(
        const void **buffer, size_t *bufferSize, const size_t deltaSize);
bool __mpw_free(
        void **buffer, size_t bufferSize);
bool __mpw_free_string(
        char **string);
bool __mpw_free_strings(
        char **strings, ...);
void mpw_zero(
        void *buffer, size_t bufferSize);

//// Cryptographic functions.

/** Derive a key from the given secret and salt using the scrypt KDF.
 * @return A buffer (allocated, keySize) containing the key or NULL if secret or salt is missing, key could not be allocated or the KDF failed. */
uint8_t const *mpw_kdf_scrypt(
        const size_t keySize, const uint8_t *secret, const size_t secretSize, const uint8_t *salt, const size_t saltSize,
        uint64_t N, uint32_t r, uint32_t p);
/** Derive a subkey from the given key using the blake2b KDF.
 * @return A buffer (allocated, keySize) containing the key or NULL if the key or subkeySize is missing, the key sizes are out of bounds, the subkey could not be allocated or derived. */
uint8_t const *mpw_kdf_blake2b(
        const size_t subkeySize, const uint8_t *key, const size_t keySize,
        const uint8_t *context, const size_t contextSize, const uint64_t id, const char *personal);
/** Calculate the MAC for the given message with the given key using SHA256-HMAC.
 * @return A buffer (allocated, 32-byte) containing the MAC or NULL if the key or message is missing, the MAC could not be allocated or generated. */
uint8_t const *mpw_hash_hmac_sha256(
        const uint8_t *key, const size_t keySize, const uint8_t *message, const size_t messageSize);
/** Encrypt a plainBuf with the given key using AES-128-CBC.
 * @return A buffer (allocated, bufSize) containing the cipherBuf or NULL if the key or buffer is missing, the key size is out of bounds or the result could not be allocated. */
uint8_t const *mpw_aes_encrypt(
        const uint8_t *key, const size_t keySize, const uint8_t *plainBuf, size_t *bufSize);
/** Decrypt a cipherBuf with the given key using AES-128-CBC.
 * @return A buffer (allocated, bufSize) containing the plainBuf or NULL if the key or buffer is missing, the key size is out of bounds or the result could not be allocated. */
uint8_t const *mpw_aes_decrypt(
        const uint8_t *key, const size_t keySize, const uint8_t *cipherBuf, size_t *bufSize);
#if UNUSED
/** Calculate an OTP using RFC-4226.
 * @return A string (allocated) containing exactly `digits` decimal OTP digits. */
const char *mpw_hotp(
        const uint8_t *key, size_t keySize, uint64_t movingFactor, uint8_t digits, uint8_t truncationOffset);
#endif

//// Visualizers.

/** Compose a formatted string.
 * @return A string (shared); or NULL if the format is missing or the result could not be allocated or formatted. */
const char *mpw_str(const char *format, ...);
const char *mpw_vstr(const char *format, va_list args);
/** Encode a buffer as a string of hexadecimal characters.
 * @return A string (shared); or NULL if the buffer is missing or the result could not be allocated. */
const char *mpw_hex(const void *buf, size_t length);
const char *mpw_hex_l(uint32_t number);
/** Encode a fingerprint for a buffer.
 * @return A string (shared); or NULL if the buffer is missing or the result could not be allocated. */
MPKeyID mpw_id_buf(const void *buf, size_t length);
/** Compare two fingerprints for equality.
 * @return true if the buffers represent identical fingerprints or are both NULL. */
bool mpw_id_buf_equals(const char *id1, const char *id2);

//// String utilities.

/** @return The byte length of the UTF-8 character at the start of the given string. */
size_t mpw_utf8_charlen(const char *utf8String);
/** @return The amount of UTF-8 characters in the given string. */
size_t mpw_utf8_strchars(const char *utf8String);
/** Drop-in for memdup(3).
 * @return A buffer (allocated, len) with len bytes copied from src or NULL if src is missing or the buffer could not be allocated. */
void *mpw_memdup(const void *src, size_t len);
/** Drop-in for POSIX strdup(3).
 * @return A string (allocated) copied from src or NULL if src is missing or the buffer could not be allocated. */
char *mpw_strdup(const char *src);
/** Drop-in for POSIX strndup(3).
 * @return A string (allocated) with no more than max bytes copied from src or NULL if src is missing or the buffer could not be allocated. */
char *mpw_strndup(const char *src, size_t max);
/** Drop-in for POSIX strncasecmp(3). */
int mpw_strncasecmp(const char *s1, const char *s2, size_t max);

#endif // _MPW_UTIL_H
