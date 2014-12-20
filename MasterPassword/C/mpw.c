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

static void mpw_pushBuf(uint8_t **const buffer, size_t *const bufferSize, const void *pushBuffer, const size_t pushSize) {

    *bufferSize += pushSize;
    *buffer = realloc( *buffer, *bufferSize );
    uint8_t *pushDst = *buffer + *bufferSize - pushSize;
    memcpy( pushDst, pushBuffer, pushSize );
}

static void mpw_pushString(uint8_t **buffer, size_t *const bufferSize, const char *pushString) {

    mpw_pushBuf( buffer, bufferSize, pushString, strlen( pushString ) );
}

static void mpw_pushInt(uint8_t **const buffer, size_t *const bufferSize, const uint32_t pushInt) {

    mpw_pushBuf( buffer, bufferSize, &pushInt, sizeof( pushInt ) );
}

static void mpw_free(void *const buffer, const size_t bufferSize) {

    memset( buffer, 0, bufferSize );
    free( buffer );
}

const uint8_t *mpw_masterKeyForUser(const char *fullName, const char *masterPassword) {

    const char *mpKeyScope = ScopeForVariant( MPSiteVariantPassword );
    trc( "fullName: %s\n", fullName );
    trc( "masterPassword: %s\n", masterPassword );
    trc( "key scope: %s\n", mpKeyScope );

    // Calculate the master key salt.
    // masterKeySalt = mpKeyScope . #fullName . fullName
    size_t masterKeySaltSize = 0;
    uint8_t *masterKeySalt = NULL;
    mpw_pushString( &masterKeySalt, &masterKeySaltSize, mpKeyScope );
    mpw_pushInt( &masterKeySalt, &masterKeySaltSize, htonl( strlen( fullName ) ) );
    mpw_pushString( &masterKeySalt, &masterKeySaltSize, fullName );
    if (!masterKeySalt)
        ftl( "Could not allocate master key salt: %d\n", errno );
    trc( "masterKeySalt ID: %s\n", IDForBuf( masterKeySalt, masterKeySaltSize ) );

    // Calculate the master key.
    // masterKey = scrypt( masterPassword, masterKeySalt )
    uint8_t *masterKey = (uint8_t *)malloc( MP_dkLen );
    if (!masterKey)
        ftl( "Could not allocate master key: %d\n", errno );
    if (crypto_scrypt( (const uint8_t *)masterPassword, strlen( masterPassword ),
            masterKeySalt, masterKeySaltSize, MP_N, MP_r, MP_p, masterKey, MP_dkLen ) < 0)
        ftl( "Could not generate master key: %d\n", errno );
    mpw_free( masterKeySalt, masterKeySaltSize );
    trc( "masterKey ID: %s\n", IDForBuf( masterKey, MP_dkLen ) );

    return masterKey;
}

const char *mpw_passwordForSite(const uint8_t *masterKey, const char *siteName, const MPSiteType siteType, const uint32_t siteCounter,
        const MPSiteVariant siteVariant, const char *siteContext) {

    const char *siteScope = ScopeForVariant( siteVariant );
    trc( "siteName: %s\n", siteName );
    trc( "siteCounter: %d\n", siteCounter );
    trc( "siteVariant: %d\n", siteVariant );
    trc( "siteType: %d\n", siteType );
    trc( "site scope: %s, context: %s\n", siteScope, siteContext == NULL? "<empty>": siteContext );

    // Calculate the site seed.
    // sitePasswordSeed = hmac-sha256( masterKey, siteScope . #siteName . siteName . siteCounter . #siteContext . siteContext )
    size_t sitePasswordInfoSize = 0;
    uint8_t *sitePasswordInfo = NULL;
    mpw_pushString( &sitePasswordInfo, &sitePasswordInfoSize, siteScope );
    mpw_pushInt( &sitePasswordInfo, &sitePasswordInfoSize, htonl( strlen( siteName ) ) );
    mpw_pushString( &sitePasswordInfo, &sitePasswordInfoSize, siteName );
    mpw_pushInt( &sitePasswordInfo, &sitePasswordInfoSize, htonl( siteCounter ) );
    if (siteContext) {
        mpw_pushInt( &sitePasswordInfo, &sitePasswordInfoSize, htonl( strlen( siteContext ) ) );
        mpw_pushString( &sitePasswordInfo, &sitePasswordInfoSize, siteContext );
    }
    if (!sitePasswordInfo)
        ftl( "Could not allocate site seed: %d\n", errno );
    trc( "sitePasswordInfo ID: %s\n", IDForBuf( sitePasswordInfo, sitePasswordInfoSize ) );

    uint8_t sitePasswordSeed[32];
    HMAC_SHA256_Buf( masterKey, MP_dkLen, sitePasswordInfo, sitePasswordInfoSize, sitePasswordSeed );
    mpw_free( sitePasswordInfo, sitePasswordInfoSize );
    trc( "sitePasswordSeed ID: %s\n", IDForBuf( sitePasswordSeed, 32 ) );

    // Determine the template.
    const char *template = TemplateForType( siteType, sitePasswordSeed[0] );
    trc( "type %d, template: %s\n", siteType, template );
    if (strlen( template ) > 32)
        ftl( "Template too long for password seed: %d", strlen( template ) );

    // Encode the password from the seed using the template.
    char *const sitePassword = calloc( strlen( template ) + 1, sizeof( char ) );
    for (int c = 0; c < strlen( template ); ++c) {
        sitePassword[c] = CharacterFromClass( template[c], sitePasswordSeed[c + 1] );
        trc( "class %c, index %u (0x%02X) -> character: %c\n", template[c], sitePasswordSeed[c + 1], sitePasswordSeed[c + 1],
                sitePassword[c] );
    }
    memset( sitePasswordSeed, 0, sizeof( sitePasswordSeed ) );

    return sitePassword;
}
