#define _GNU_SOURCE

#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <scrypt/sha256.h>
#include <scrypt/crypto_scrypt.h>
#include "types.h"

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_dkLen            64
#define MP_hash             PearlHashSHA256

void mpw_bufPush(void *buffer, size_t *bufferSize, void *pushBuffer, size_t pushSize) {

    void *pushDst = buffer + *bufferSize;
    *bufferSize += pushSize;
    realloc( buffer, *bufferSize );
    memcpy( pushDst, pushBuffer, pushSize );
}

uint8_t *mpw_masterKeyForUser(const char *fullName, const char *masterPassword) {

    // Calculate the master key salt.
    const char *mpKeyScope = ScopeForVariant( MPSiteVariantPassword );
    const uint32_t n_fullNameLength = htonl( strlen( fullName ) );
    const size_t masterKeySaltLength = strlen( mpKeyScope ) + sizeof( n_fullNameLength ) + strlen( fullName );
    char *masterKeySalt = (char *)malloc( masterKeySaltLength );
    if (!masterKeySalt)
        ftl( "Could not allocate master key salt: %d\n", errno );

    char *mKS = masterKeySalt;
    memcpy( mKS, mpKeyScope, strlen( mpKeyScope ) );
    mKS += strlen( mpKeyScope );
    memcpy( mKS, &n_fullNameLength, sizeof( n_fullNameLength ) );
    mKS += sizeof( n_fullNameLength );
    memcpy( mKS, fullName, strlen( fullName ) );
    mKS += strlen( fullName );

    trc( "fullName: %s\n", fullName );
    trc( "masterPassword: %s\n", masterPassword );
    trc( "key scope: %s\n", mpKeyScope );
    trc( "masterKeySalt ID: %s\n", IDForBuf( masterKeySalt, masterKeySaltLength ) );
    if (mKS - masterKeySalt != masterKeySaltLength)
        ftl( "Unexpected master key salt length." );

    // Calculate the master key.
    uint8_t *masterKey = (uint8_t *)malloc( MP_dkLen );
    if (!masterKey) {
        fprintf( stderr, "Could not allocate master key: %d\n", errno );
        abort();
    }
    if (crypto_scrypt( (const uint8_t *)masterPassword, strlen( masterPassword ), (const uint8_t *)masterKeySalt, masterKeySaltLength, MP_N,
            MP_r, MP_p, masterKey, MP_dkLen ) < 0) {
        fprintf( stderr, "Could not generate master key: %d\n", errno );
        abort();
    }
    memset( masterKeySalt, 0, masterKeySaltLength );
    free( masterKeySalt );
    trc( "masterKey ID: %s\n", IDForBuf( masterKey, MP_dkLen ) );

    return masterKey;
}

char *mpw_passwordForSite(const uint8_t *masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext) {

    // Calculate the site seed.
    trc( "siteName: %s\n", siteName );
    trc( "siteCounter: %d\n", siteCounter );
    trc( "siteVariant: %d\n", siteVariant );
    trc( "siteType: %d\n", siteType );
    const char *siteScope = ScopeForVariant( siteVariant );
    trc( "site scope: %s, context: %s\n", siteScope, siteContext == NULL? "<empty>": siteContext );
    const uint32_t n_siteNameLength = htonl( strlen( siteName ) );
    const uint32_t n_siteCounter = htonl( siteCounter );
    const uint32_t n_siteContextLength = siteContext == NULL? 0: htonl( strlen( siteContext ) );
    size_t sitePasswordInfoLength = strlen( siteScope ) + sizeof( n_siteNameLength ) + strlen( siteName ) + sizeof( n_siteCounter );
    if (siteContext)
        sitePasswordInfoLength += sizeof( n_siteContextLength ) + strlen( siteContext );
    char *sitePasswordInfo = (char *)malloc( sitePasswordInfoLength );
    if (!sitePasswordInfo) {
        fprintf( stderr, "Could not allocate site seed: %d\n", errno );
        abort();
    }

    char *sPI = sitePasswordInfo;
    memcpy( sPI, siteScope, strlen( siteScope ) );
    sPI += strlen( siteScope );
    memcpy( sPI, &n_siteNameLength, sizeof( n_siteNameLength ) );
    sPI += sizeof( n_siteNameLength );
    memcpy( sPI, siteName, strlen( siteName ) );
    sPI += strlen( siteName );
    memcpy( sPI, &n_siteCounter, sizeof( n_siteCounter ) );
    sPI += sizeof( n_siteCounter );
    if (siteContext) {
        memcpy( sPI, &n_siteContextLength, sizeof( n_siteContextLength ) );
        sPI += sizeof( n_siteContextLength );
        memcpy( sPI, siteContext, strlen( siteContext ) );
        sPI += strlen( siteContext );
    }
    if (sPI - sitePasswordInfo != sitePasswordInfoLength)
        abort();
    trc( "seed from: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)\n", siteScope,
            Hex( &n_siteNameLength, sizeof( n_siteNameLength ) ), siteName, Hex( &n_siteCounter, sizeof( n_siteCounter ) ),
            Hex( &n_siteContextLength, sizeof( n_siteContextLength ) ), siteContext );
    trc( "sitePasswordInfo ID: %s\n", IDForBuf( sitePasswordInfo, sitePasswordInfoLength ) );

    uint8_t sitePasswordSeed[32];
    HMAC_SHA256_Buf( masterKey, MP_dkLen, sitePasswordInfo, sitePasswordInfoLength, sitePasswordSeed );
    memset( sitePasswordInfo, 0, sitePasswordInfoLength );
    free( sitePasswordInfo );
    trc( "sitePasswordSeed ID: %s\n", IDForBuf( sitePasswordSeed, 32 ) );

    // Determine the template.
    const char *template = TemplateForType( siteType, sitePasswordSeed[0] );
    trc( "type %d, template: %s\n", siteType, template );
    if (strlen( template ) > 32)
        abort();

    // Encode the password from the seed using the template.
    char *sitePassword = (char *)calloc( strlen( template ) + 1, sizeof( char ) );
    for (int c = 0; c < strlen( template ); ++c) {
        sitePassword[c] = CharacterFromClass( template[c], sitePasswordSeed[c + 1] );
        trc( "class %c, index %u (0x%02X) -> character: %c\n", template[c], sitePasswordSeed[c + 1], sitePasswordSeed[c + 1],
                sitePassword[c] );
    }
    memset( sitePasswordSeed, 0, sizeof( sitePasswordSeed ) );

    return sitePassword;
}
