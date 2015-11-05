//
//  mpw-bench.c
//  MasterPassword
//
//  Created by Maarten Billemont on 2014-12-20.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
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

    // Start MPW
    unsigned int iterations = 100;
    mpw_getTime( &startTime );
    for (int i = 0; i < iterations; ++i) {
        const uint8_t *masterKey = mpw_masterKeyForUser(
                fullName, masterPassword, MPAlgorithmVersionCurrent );
        if (!masterKey)
            ftl( "Could not allocate master key: %d\n", errno );
        free( (void *)mpw_passwordForSite(
                masterKey, siteName, siteType, siteCounter, siteVariant, siteContext, MPAlgorithmVersionCurrent ) );
        free( (void *)masterKey );

        if (i % ( iterations / 100 ) == 0)
            fprintf( stderr, "\rmpw: iteration %d / %d (%d%%)..", i, iterations, i * 100 / iterations );
    }
    const double mpwSpeed = mpw_showSpeed( startTime, iterations, "mpw" );

    // Start SHA-256
    iterations = 45000000;
    uint8_t hash[32];
    mpw_getTime( &startTime );
    for (int i = 0; i < iterations; ++i) {
        SHA256_Buf( masterPassword, strlen( masterPassword ), hash );

        if (i % ( iterations / 100 ) == 0)
            fprintf( stderr, "\rsha256: iteration %d / %d (%d%%)..", i, iterations, i * 100 / iterations );
    }
    const double sha256Speed = mpw_showSpeed( startTime, iterations, "sha256" );

    // Start BCrypt
    int bcrypt_cost = 9;
    iterations = 1000;
    mpw_getTime( &startTime );
    for (int i = 0; i < iterations; ++i) {
        crypt( masterPassword, crypt_gensalt( "$2b$", bcrypt_cost, fullName, strlen( fullName ) ) );

        if (i % ( iterations / 100 ) == 0)
            fprintf( stderr, "\rbcrypt (cost %d): iteration %d / %d (%d%%)..", bcrypt_cost, i, iterations, i * 100 / iterations );
    }
    const double bcrypt9Speed = mpw_showSpeed( startTime, iterations, "bcrypt9" );

    // Summarize.
    fprintf( stdout, "\n== SUMMARY ==\nOn this machine,\n" );
    fprintf( stdout, " - mpw is %f times slower than sha256 (reference: 320000 on an MBP Late 2013).\n", sha256Speed / mpwSpeed );
    fprintf( stdout, " - mpw is %f times slower than bcrypt (cost 9) (reference: 22 on an MBP Late 2013).\n", bcrypt9Speed / mpwSpeed );

    return 0;
}
