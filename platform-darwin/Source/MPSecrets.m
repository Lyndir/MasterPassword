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

#import "MPSecrets.h"
#import "base64.h"

// printf <secret> | openssl enc -[ed] -aes-128-cbc -a -A -K <appSecret> -iv 0
NSString *appSecret    = @"";
NSString *appSalt      = @"";
NSString *sentryDSN    = @"";
NSString *countlyKey   = @"";
NSString *countlySalt  = @"";

NSString *decrypt(NSString *secret) {

    if (!secret)
        return nil;

    const char *secretString = [secret cStringUsingEncoding:NSUTF8StringEncoding];
    size_t length = mpw_base64_decode_max( secretString );
    if (!length)
        return nil;

    size_t keyLength;
    const uint8_t *key = mpw_unhex( [appSecret cStringUsingEncoding:NSUTF8StringEncoding], &keyLength );
    if (!key)
        return nil;

    uint8_t *base64 = calloc( length, sizeof( uint8_t ) );
    length = mpw_base64_decode( base64, secretString );

    const void *plain = mpw_aes_decrypt( key, keyLength, base64, &length );
    mpw_free( &key, keyLength );
    @try {
        return [[NSString alloc] initWithBytes:plain length:length encoding:NSUTF8StringEncoding];
    }
    @finally {
        mpw_free( &plain, length );
    }
}

NSString *digest(NSString *value) {

    if (!value)
        return nil;

    NSUInteger appSaltLength, valueLength;
    const void *appSaltString = [decrypt( appSalt ) cStringUsingEncoding:NSUTF8StringEncoding length:&appSaltLength];
    const void *valueString = [value cStringUsingEncoding:NSUTF8StringEncoding length:&valueLength];
    const uint8_t *digest = mpw_hash_hmac_sha256( appSaltString, appSaltLength, valueString, valueLength );
    if (!digest)
        return nil;

    @try {
        return [[NSString alloc] initWithBytes:mpw_hex( digest, 32 ) length:16 encoding:NSUTF8StringEncoding];
    }
    @finally {
        mpw_free( &digest, 32 );
    }
}
