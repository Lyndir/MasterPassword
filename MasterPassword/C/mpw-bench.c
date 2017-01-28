//
//  mpw-bench.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-20.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <errno.h>
#include <sys/time.h>

#include <scrypt/sha256.h>
#include <bcrypt/ow-crypt.h>

#include "mpw-algorithm.h"
#include "mpw-util.h"

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_dkLen            64
#define MP_hash             PearlHashSHA256

static void mpw_getTime(struct timeval *time) {

    if (gettimeofday( time, NULL ) != 0)
        ftl( "Could not get time: %d\n", errno );
}

static const double mpw_showSpeed(struct timeval startTime, const unsigned int iterations, const char *operation) {

    struct timeval endTime;
    mpw_getTime( &endTime );

    const time_t dsec = (endTime.tv_sec - startTime.tv_sec);
    const suseconds_t dusec = (endTime.tv_usec - startTime.tv_usec);
    const double elapsed = dsec + dusec / 1000000.;
    const double speed = iterations / elapsed;

    fprintf( stderr, " done.  " );
    fprintf( stdout, "%d %s iterations in %llds %lldµs -> %.2f/s\n", iterations, operation, (long long)dsec, (long long)dusec, speed );

    return speed;
}

int main(int argc, char *const argv[]) {

    const char *fullName = "Robert Lee Mitchel";
    const char *masterPassword = "banana colored duckling";
    const char *siteName = "masterpasswordapp.com";
    const uint32_t siteCounter = 1;
    const MPSiteType siteType = MPSiteTypeGeneratedLong;
    const MPSiteVariant siteVariant = MPSiteVariantPassword;
    const char *siteContext = NULL;
    struct timeval startTime;
    unsigned int iterations;
    float percent;
    const uint8_t *masterKey;

    // Start HMAC-SHA-256
    // Similar to phase-two of mpw
    uint8_t *sitePasswordInfo = malloc( 128 );
    iterations = 3000000;
    masterKey = mpw_masterKeyForUser( fullName, masterPassword, MPAlgorithmVersionCurrent );
    if (!masterKey) {
        ftl( "Could not allocate master key: %d\n", errno );
        abort();
    }
    mpw_getTime( &startTime );
    for (int i = 1; i <= iterations; ++i) {
        free( (void *)mpw_hmac_sha256( masterKey, MP_dkLen, sitePasswordInfo, 128 ) );

        if (modff(100.f * i / iterations, &percent) == 0)
            fprintf( stderr, "\rhmac-sha-256: iteration %d / %d (%.0f%%)..", i, iterations, percent );
    }
    const double hmacSha256Speed = mpw_showSpeed( startTime, iterations, "hmac-sha-256" );
    free( (void *)masterKey );

    // Start BCrypt
    // Similar to phase-one of mpw
    int bcrypt_cost = 9;
    iterations = 1000;
    mpw_getTime( &startTime );
    for (int i = 1; i <= iterations; ++i) {
        crypt( masterPassword, crypt_gensalt( "$2b$", bcrypt_cost, fullName, strlen( fullName ) ) );

        if (modff(100.f * i / iterations, &percent) == 0)
            fprintf( stderr, "\rbcrypt (cost %d): iteration %d / %d (%.0f%%)..", bcrypt_cost, i, iterations, percent );
    }
    const double bcrypt9Speed = mpw_showSpeed( startTime, iterations, "bcrypt9" );

    // Start SCrypt
    // Phase one of mpw
    iterations = 50;
    mpw_getTime( &startTime );
    for (int i = 1; i <= iterations; ++i) {
        free( (void *)mpw_masterKeyForUser( fullName, masterPassword, MPAlgorithmVersionCurrent ) );

        if (modff(100.f * i / iterations, &percent) == 0)
            fprintf( stderr, "\rscrypt_mpw: iteration %d / %d (%.0f%%)..", i, iterations, percent );
    }
    const double scryptSpeed = mpw_showSpeed( startTime, iterations, "scrypt_mpw" );

    // Start MPW
    // Both phases of mpw
    iterations = 50;
    mpw_getTime( &startTime );
    for (int i = 1; i <= iterations; ++i) {
        masterKey = mpw_masterKeyForUser( fullName, masterPassword, MPAlgorithmVersionCurrent );
        if (!masterKey) {
            ftl( "Could not allocate master key: %d\n", errno );
            abort();
        }

        free( (void *)mpw_passwordForSite(
                masterKey, siteName, siteType, siteCounter, siteVariant, siteContext, MPAlgorithmVersionCurrent ) );
        free( (void *)masterKey );

        if (modff(100.f * i / iterations, &percent) == 0)
            fprintf( stderr, "\rmpw: iteration %d / %d (%.0f%%)..", i, iterations, percent );
    }
    const double mpwSpeed = mpw_showSpeed( startTime, iterations, "mpw" );

    // Summarize.
    fprintf( stdout, "\n== SUMMARY ==\nOn this machine,\n" );
    fprintf( stdout, " - mpw is %f times slower than hmac-sha-256 (reference: 320000 on an MBP Late 2013).\n", hmacSha256Speed / mpwSpeed );
    fprintf( stdout, " - mpw is %f times slower than bcrypt (cost 9) (reference: 22 on an MBP Late 2013).\n", bcrypt9Speed / mpwSpeed );
    fprintf( stdout, " - scrypt is %f times slower than bcrypt (cost 9) (reference: 22 on an MBP Late 2013).\n", bcrypt9Speed / scryptSpeed );

    return 0;
}
