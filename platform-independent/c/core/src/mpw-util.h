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

#include "mpw-types.h"

MP_LIBS_BEGIN
#include <stdio.h>
#include <stdarg.h>
#include <time.h>
MP_LIBS_END

//// Logging.
typedef mpw_enum( int, LogLevel ) {
    /** Logging internal state. */
            LogLevelTrace = 3,
    /** Logging state and events interesting when investigating issues. */
            LogLevelDebug = 2,
    /** User messages. */
            LogLevelInfo = 1,
    /** Recoverable issues and user suggestions. */
            LogLevelWarning = 0,
    /** Unrecoverable issues. */
            LogLevelError = -1,
    /** Issues that lead to abortion. */
            LogLevelFatal = -2,
};
extern LogLevel mpw_verbosity;

typedef struct {
    time_t occurrence;
    LogLevel level;
    const char *file;
    int line;
    const char *function;
    const char *message;
} MPLogEvent;

/** A log sink describes a function that can receive log events. */
typedef bool (MPLogSink)(const MPLogEvent *event);

/** To receive events, sinks need to be registered.  If no sinks are registered, log events are sent to the mpw_log_sink_file sink. */
bool mpw_log_sink_register(MPLogSink *sink);
bool mpw_log_sink_unregister(MPLogSink *sink);

/** mpw_log_sink_file is a sink that writes log messages to the mpw_log_sink_file, which defaults to stderr. */
extern MPLogSink mpw_log_sink_file;
extern FILE *mpw_log_sink_file_target;

/** These functions dispatch log events to the registered sinks. */
void mpw_log_sink(LogLevel level, const char *file, int line, const char *function, const char *format, ...);
void mpw_log_vsink(LogLevel level, const char *file, int line, const char *function, const char *format, va_list args);
void mpw_log_ssink(LogLevel level, const char *file, int line, const char *function, const char *message);

/** The log dispatcher you want to channel log messages into; defaults to mpw_log_sink, enabling the log sink mechanism. */
#ifndef MPW_LOG
#define MPW_LOG mpw_log_sink
#endif

#ifndef trc
#define trc(format, ...) MPW_LOG( LogLevelTrace, __FILE__, __LINE__, __func__, format, ##__VA_ARGS__ )
#define dbg(format, ...) MPW_LOG( LogLevelDebug, __FILE__, __LINE__, __func__, format, ##__VA_ARGS__ )
#define inf(format, ...) MPW_LOG( LogLevelInfo, __FILE__, __LINE__, __func__, format, ##__VA_ARGS__ )
#define wrn(format, ...) MPW_LOG( LogLevelWarning, __FILE__, __LINE__, __func__, format, ##__VA_ARGS__ )
#define err(format, ...) MPW_LOG( LogLevelError, __FILE__, __LINE__, __func__, format, ##__VA_ARGS__ )
#define ftl(format, ...) MPW_LOG( LogLevelFatal, __FILE__, __LINE__, __func__, format, ##__VA_ARGS__ )
#endif


//// Utilities

#ifndef OK
#define OK 0
#endif
#ifndef ERR
#define ERR -1
#endif

#ifndef stringify
#define stringify(s) #s
#endif
#ifndef stringify_def
#define stringify_def(s) stringify(s)
#endif

#if !__STRICT_ANSI__ && __GNUC__ >= 3
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
#define mpw_default(__default, __value) ({ __typeof__ (__value) _v = (__value); _v? _v: (__default); })
#define mpw_default_n(__default, __num) ({ __typeof__ (__num) _n = (__num); !isnan( _n )? (__typeof__ (__default))_n: (__default); })
#else
#ifndef min
#define min(a, b) ( (a) < (b) ? (a) : (b) )
#endif
#ifndef max
#define max(a, b) ( (a) > (b) ? (a) : (b) )
#endif
#define mpw_default(__default, __value) ( (__value)? (__value): (__default) )
#define mpw_default_n(__default, __num) ( !isnan( (__num) )? (__num): (__default) )
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

// These defines merely exist to do type-checking, force the void** cast & drop any const qualifier.
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
        void *buffer, const size_t bufferSize);

//// Cryptographic functions.

/** Derive a key from the given secret and salt using the scrypt KDF.
 * @return A buffer (allocated, keySize) containing the key or NULL if secret or salt is missing, key could not be allocated or the KDF failed. */
uint8_t const *mpw_kdf_scrypt(
        const size_t keySize, const uint8_t *secret, const size_t secretSize, const uint8_t *salt, const size_t saltSize,
        const uint64_t N, const uint32_t r, const uint32_t p);
/** Derive a subkey from the given key using the blake2b KDF.
 * @return A buffer (allocated, keySize) containing the key or NULL if the key or subkeySize is missing, the key sizes are out of bounds, the subkey could not be allocated or derived. */
uint8_t const *mpw_kdf_blake2b(
        const size_t subkeySize, const uint8_t *key, const size_t keySize,
        const uint8_t *context, const size_t contextSize, const uint64_t id, const char *personal);
/** Calculate the MAC for the given message with the given key using SHA256-HMAC.
 * @return A buffer (allocated, 32-byte) containing the MAC or NULL if the key or message is missing, the MAC could not be allocated or generated. */
uint8_t const *mpw_hash_hmac_sha256(
        const uint8_t *key, const size_t keySize, const uint8_t *message, const size_t messageSize);
/** Encrypt a plainBuffer with the given key using AES-128-CBC.
 * @param bufferSize A pointer to the size of the plain buffer on input, and the size of the returned cipher buffer on output.
 * @return A buffer (allocated, bufferSize) containing the cipherBuffer or NULL if the key or buffer is missing, the key size is out of bounds or the result could not be allocated. */
uint8_t const *mpw_aes_encrypt(
        const uint8_t *key, const size_t keySize, const uint8_t *plainBuffer, size_t *bufferSize);
/** Decrypt a cipherBuffer with the given key using AES-128-CBC.
 * @param bufferSize A pointer to the size of the cipher buffer on input, and the size of the returned plain buffer on output.
 * @return A buffer (allocated, bufferSize) containing the plainBuffer or NULL if the key or buffer is missing, the key size is out of bounds or the result could not be allocated. */
uint8_t const *mpw_aes_decrypt(
        const uint8_t *key, const size_t keySize, const uint8_t *cipherBuffer, size_t *bufferSize);
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
/** Encode length-bytes from a buffer as a string of hexadecimal characters.
 * @return A string (shared); or NULL if the buffer is missing or the result could not be allocated. */
const char *mpw_hex(const void *buf, const size_t length);
const char *mpw_hex_l(const uint32_t number);
/** Decode a string of hexadecimal characters into a buffer of length-bytes.
 * @return A buffer (allocated, *length); or NULL if hex is NULL, empty, or not an even-length hexadecimal string. */
const uint8_t *mpw_unhex(const char *hex, size_t *length);
/** Encode a fingerprint for a buffer.
 * @return A string (shared); or NULL if the buffer is missing or the result could not be allocated. */
const MPKeyID mpw_id_buf(const void *buf, const size_t length);
/** Compare two fingerprints for equality.
 * @return true if the buffers represent identical fingerprints or are both NULL. */
bool mpw_id_buf_equals(MPKeyID id1, MPKeyID id2);

//// String utilities.

/** @return The byte length of the UTF-8 character at the start of the given string or 0 if it is NULL, empty or not a legal UTF-8 character. */
size_t mpw_utf8_charlen(const char *utf8String);
/** @return The amount of UTF-8 characters in the given string or 0 if it is NULL, empty, or contains bytes that are not legal in UTF-8. */
size_t mpw_utf8_strchars(const char *utf8String);
/** Drop-in for memdup(3).
 * @return A buffer (allocated, len) with len bytes copied from src or NULL if src is missing or the buffer could not be allocated. */
void *mpw_memdup(const void *src, const size_t len);
/** Drop-in for POSIX strdup(3).
 * @return A string (allocated) copied from src or NULL if src is missing or the buffer could not be allocated. */
char *mpw_strdup(const char *src);
/** Drop-in for POSIX strndup(3).
 * @return A string (allocated) with no more than max bytes copied from src or NULL if src is missing or the buffer could not be allocated. */
char *mpw_strndup(const char *src, const size_t max);
/** Drop-in for POSIX strcasecmp(3). */
int mpw_strcasecmp(const char *s1, const char *s2);
/** Drop-in for POSIX strncasecmp(3). */
int mpw_strncasecmp(const char *s1, const char *s2, const size_t max);

#endif // _MPW_UTIL_H
