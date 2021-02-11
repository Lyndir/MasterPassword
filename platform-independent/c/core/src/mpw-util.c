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

#include "mpw-util.h"

MP_LIBS_BEGIN
#include <string.h>
#include <ctype.h>
#include <errno.h>

#if MPW_CPERCIVA
#include <scrypt/crypto_scrypt.h>
#include <scrypt/sha256.h>
#elif MPW_SODIUM
#include "sodium.h"
#endif
#define AES_ECB 0
#define AES_CBC 1
#include "aes.h"
MP_LIBS_END

LogLevel mpw_verbosity = LogLevelInfo;
FILE *mpw_log_sink_file_target = NULL;

static MPLogSink **sinks;
static size_t sinks_count;

bool mpw_log_sink_register(MPLogSink *sink) {

    if (!mpw_realloc( &sinks, NULL, sizeof( MPLogSink * ) * ++sinks_count )) {
        --sinks_count;
        return false;
    }

    sinks[sinks_count - 1] = sink;
    return true;
}

bool mpw_log_sink_unregister(MPLogSink *sink) {

    for (unsigned int r = 0; r < sinks_count; ++r) {
        if (sinks[r] == sink) {
            sinks[r] = NULL;
            return true;
        }
    }

    return false;
}

void mpw_log_sink(LogLevel level, const char *file, int line, const char *function, const char *format, ...) {

    if (mpw_verbosity < level)
        return;

    va_list args;
    va_start( args, format );
    mpw_log_vsink( level, file, line, function, format, args );
    va_end( args );
}

void mpw_log_vsink(LogLevel level, const char *file, int line, const char *function, const char *format, va_list args) {

    if (mpw_verbosity < level)
        return;

    return mpw_log_ssink( level, file, line, function, mpw_vstr( format, args ) );
}

void mpw_log_ssink(LogLevel level, const char *file, int line, const char *function, const char *message) {

    if (mpw_verbosity < level)
        return;

    MPLogEvent record = (MPLogEvent){
            .occurrence = time( NULL ),
            .level = level,
            .file = file,
            .line = line,
            .function = function,
            .message = message,
    };

    bool sunk = false;
    for (unsigned int s = 0; s < sinks_count; ++s) {
        MPLogSink *sink = sinks[s];

        if (sink)
            sunk |= sink( &record );
    }
    if (!sunk)
        sunk = mpw_log_sink_file( &record );

    if (record.level <= LogLevelError) {
        /* error breakpoint */;
    }
    if (record.level <= LogLevelFatal)
        abort();
}

bool mpw_log_sink_file(const MPLogEvent *record) {

    if (!mpw_log_sink_file_target)
        mpw_log_sink_file_target = stderr;

    if (mpw_verbosity >= LogLevelDebug) {
        switch (record->level) {
            case LogLevelTrace:
                fprintf( mpw_log_sink_file_target, "[TRC] " );
                break;
            case LogLevelDebug:
                fprintf( mpw_log_sink_file_target, "[DBG] " );
                break;
            case LogLevelInfo:
                fprintf( mpw_log_sink_file_target, "[INF] " );
                break;
            case LogLevelWarning:
                fprintf( mpw_log_sink_file_target, "[WRN] " );
                break;
            case LogLevelError:
                fprintf( mpw_log_sink_file_target, "[ERR] " );
                break;
            case LogLevelFatal:
                fprintf( mpw_log_sink_file_target, "[FTL] " );
                break;
            default:
                fprintf( mpw_log_sink_file_target, "[???] " );
                break;
        }
    }

    fprintf( mpw_log_sink_file_target, "%s\n", record->message );
    return true;
}

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

const char **mpw_strings(size_t *count, const char *strings, ...) {

    va_list args;
    va_start( args, strings );
    const char **array = NULL;
    size_t size = 0;
    for (const char *string = strings; string; (string = va_arg( args, const char * ))) {
        size_t cursor = size / sizeof( *array );
        if (!mpw_realloc( &array, &size, sizeof( string ) )) {
            mpw_free( &array, size );
            *count = 0;
            return NULL;
        }
        array[cursor] = string;
    }
    va_end( args );

    *count = size / sizeof( *array );
    return array;
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

void mpw_zero(void *buffer, size_t bufferSize) {

    uint8_t *b = buffer;
    for (; bufferSize > 0; --bufferSize)
        *b++ = 0;
}

bool __mpw_free(void **buffer, const size_t bufferSize) {

    if (!buffer || !*buffer)
        return false;

    mpw_zero( *buffer, bufferSize );
    free( *buffer );
    *buffer = NULL;

    return true;
}

bool __mpw_free_string(char **string) {

    return string && *string && __mpw_free( (void **)string, strlen( *string ) );
}

bool __mpw_free_strings(char **strings, ...) {

    bool success = true;

    va_list args;
    va_start( args, strings );
    success &= mpw_free_string( strings );
    for (char **string; (string = va_arg( args, char ** ));)
        success &= mpw_free_string( string );
    va_end( args );

    return success;
}

uint8_t const *mpw_kdf_scrypt(const size_t keySize, const uint8_t *secret, const size_t secretSize, const uint8_t *salt, const size_t saltSize,
        const uint64_t N, const uint32_t r, const uint32_t p) {

    if (!secret || !salt || !secretSize || !saltSize)
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
    if (crypto_pwhash_scryptsalsa208sha256_ll( secret, secretSize, salt, saltSize, N, r, p, key, keySize ) != 0) {
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
    mpw_zero( saltBuf, sizeof saltBuf );
    if (id)
        mpw_uint64( id, saltBuf );

    uint8_t personalBuf[crypto_generichash_blake2b_PERSONALBYTES];
    mpw_zero( personalBuf, sizeof personalBuf );
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

    if (!key || keySize < AES_BLOCKLEN || !bufSize || !*bufSize)
        return NULL;

    // IV = zero
    static uint8_t *iv = NULL;
    if (!iv)
        iv = calloc( AES_BLOCKLEN, sizeof( uint8_t ) );

    // Add PKCS#7 padding
    uint32_t aesSize = ((uint32_t)*bufSize + AES_BLOCKLEN - 1) & -AES_BLOCKLEN; // round up to block size.
    if (encrypt && !(*bufSize % AES_BLOCKLEN)) // add pad block if plain text fits block size.
        aesSize += AES_BLOCKLEN;
    uint8_t *resultBuf = calloc( aesSize, sizeof( uint8_t ) );
    if (!resultBuf)
        return NULL;
    uint8_t *aesBuf = malloc( aesSize );
    if (!aesBuf) {
        mpw_free( &resultBuf, aesSize );
        return NULL;
    }

    memcpy( aesBuf, buf, *bufSize );
    memset( aesBuf + *bufSize, (int)(aesSize - *bufSize), aesSize - *bufSize );

    if (encrypt)
        AES_CBC_encrypt_buffer( resultBuf, aesBuf, aesSize, key, iv );
    else
        AES_CBC_decrypt_buffer( resultBuf, aesBuf, aesSize, key, iv );
    mpw_free( &aesBuf, aesSize );

    // Truncate PKCS#7 padding
    if (encrypt)
        *bufSize = aesSize;
    else if (resultBuf[aesSize - 1] <= AES_BLOCKLEN)
        *bufSize -= resultBuf[aesSize - 1];

    return resultBuf;
}

uint8_t const *mpw_aes_encrypt(const uint8_t *key, const size_t keySize, const uint8_t *plainBuffer, size_t *bufferSize) {

    return mpw_aes( true, key, keySize, plainBuffer, bufferSize );
}

uint8_t const *mpw_aes_decrypt(const uint8_t *key, const size_t keySize, const uint8_t *cipherBuffer, size_t *bufferSize) {

    return mpw_aes( false, key, keySize, cipherBuffer, bufferSize );
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
    return mpw_strdup( mpw_str( "%0*d", digits, otp ) );
}
#endif

const MPKeyID mpw_id_buf(const void *buf, const size_t length) {

    if (!buf)
        return NULL;

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

bool mpw_id_buf_equals(MPKeyID id1, MPKeyID id2) {

    if (!id1 || !id2)
        return !id1 && !id2;

    size_t size = strlen( id1 );
    if (size != strlen( id2 ))
        return false;

    return mpw_strncasecmp( id1, id2, size ) == OK;
}

const char *mpw_str(const char *format, ...) {

    va_list args;
    va_start( args, format );
    const char *str_str = mpw_vstr( format, args );
    va_end( args );

    return str_str;
}

const char *mpw_vstr(const char *format, va_list args) {

    if (!format)
        return NULL;

    // TODO: shared storage leaks information, has an implicit recursion cap and isn't thread-safe.
    static char *str_str[10];
    static size_t str_str_i;
    str_str_i = (str_str_i + 1) % (sizeof( str_str ) / sizeof( *str_str ));

    do {
        va_list args_copy;
        va_copy( args_copy, args );
        // FIXME: size is determined by string length, potentially unsafe if string can be modified.
        size_t str_size = str_str[str_str_i]? strlen( str_str[str_str_i] ) + 1: 0;
        size_t str_chars = (size_t)vsnprintf( str_str[str_str_i], str_size, format, args_copy );
        va_end( args_copy );

        if (str_chars < 0)
            return NULL;
        if (str_chars < str_size)
            break;

        if (!mpw_realloc( &str_str[str_str_i], NULL, str_chars + 1 ))
            return NULL;
        memset( str_str[str_str_i], '.', str_chars );
        str_str[str_str_i][str_chars] = '\0';
    } while (true);

    return str_str[str_str_i];
}

const char *mpw_hex(const void *buf, const size_t length) {

    if (!buf || !length)
        return NULL;

    // TODO: shared storage leaks information, has an implicit recursion cap and isn't thread-safe.
    static char *mpw_hex_buf[10];
    static size_t mpw_hex_buf_i;
    mpw_hex_buf_i = (mpw_hex_buf_i + 1) % (sizeof( mpw_hex_buf ) / sizeof( *mpw_hex_buf ));
    if (!mpw_realloc( &mpw_hex_buf[mpw_hex_buf_i], NULL, length * 2 + 1 ))
        return NULL;

    for (size_t kH = 0; kH < length; kH++)
        sprintf( &(mpw_hex_buf[mpw_hex_buf_i][kH * 2]), "%02hhX", ((const uint8_t *)buf)[kH] );

    return mpw_hex_buf[mpw_hex_buf_i];
}

const char *mpw_hex_l(const uint32_t number) {

    uint8_t buf[4 /* 32 / 8 */];
    buf[0] = (uint8_t)((number >> 24) & UINT8_MAX);
    buf[1] = (uint8_t)((number >> 16) & UINT8_MAX);
    buf[2] = (uint8_t)((number >> 8L) & UINT8_MAX);
    buf[3] = (uint8_t)((number >> 0L) & UINT8_MAX);
    return mpw_hex( &buf, sizeof( buf ) );
}

const uint8_t *mpw_unhex(const char *hex, size_t *length) {

    if (!hex)
        return NULL;

    size_t hexLength = strlen( hex );
    if (hexLength == 0 || hexLength % 2 != 0)
        return NULL;

    size_t bufLength = hexLength / 2;
    if (length)
        *length = bufLength;

    uint8_t *buf = malloc( bufLength );
    for (size_t b = 0; b < bufLength; ++b)
        if (sscanf( hex + b * 2, "%02hhX", &buf[b] ) != 1) {
            mpw_free( &buf, bufLength );
            return NULL;
        }

    return buf;
}

size_t mpw_utf8_charlen(const char *utf8String) {

    if (!utf8String)
        return 0;

    // Legal UTF-8 byte sequences: <http://www.unicode.org/unicode/uni2errata/UTF-8_Corrigendum.html>
    unsigned char utf8Char = (unsigned char)*utf8String;
    if (utf8Char >= 0x00 && utf8Char <= 0x7F)
        return min( 1, strlen( utf8String ) );
    if (utf8Char >= 0xC2 && utf8Char <= 0xDF)
        return min( 2, strlen( utf8String ) );
    if (utf8Char >= 0xE0 && utf8Char <= 0xEF)
        return min( 3, strlen( utf8String ) );
    if (utf8Char >= 0xF0 && utf8Char <= 0xF4)
        return min( 4, strlen( utf8String ) );

    return 0;
}

size_t mpw_utf8_strchars(const char *utf8String) {

    size_t strchars = 0, charlen;
    for (char *remaining = (char *)utf8String; remaining && *remaining; remaining += charlen, ++strchars)
        if (!(charlen = mpw_utf8_charlen( remaining )))
            return 0;

    return strchars;
}

void *mpw_memdup(const void *src, const size_t len) {

    if (!src)
        return NULL;

    char *dst = malloc( len );
    if (dst)
        memcpy( dst, src, len );

    return dst;
}

char *mpw_strdup(const char *src) {

    if (!src)
        return NULL;

    size_t len = strlen( src );
    return mpw_memdup( src, len + 1 );
}

char *mpw_strndup(const char *src, const size_t max) {

    if (!src)
        return NULL;

    size_t len = 0;
    for (; len < max && src[len] != '\0'; ++len);

    char *dst = calloc( len + 1, sizeof( char ) );
    if (dst)
        memcpy( dst, src, len );

    return dst;
}

int mpw_strcasecmp(const char *s1, const char *s2) {

    return mpw_strncasecmp( s1, s2, s1 && s2? min( strlen( s1 ), strlen( s2 ) ): 0 );
}

int mpw_strncasecmp(const char *s1, const char *s2, size_t max) {

    int cmp = s1 && s2 && max > 0? 0: s1? 1: -1;
    for (; !cmp && max && max-- > 0 && s1 && s2; ++s1, ++s2)
        cmp = tolower( (unsigned char)*s1 ) - tolower( (unsigned char)*s2 );

    return cmp;
}
