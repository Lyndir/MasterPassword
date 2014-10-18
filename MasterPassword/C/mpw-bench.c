#include <sys/time.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <math.h>
#include <pwd.h>
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <alg/sha256.h>
#include <crypto/crypto_scrypt.h>
#include <ow-crypt.h>
#include "types.h"

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_dkLen            64
#define MP_hash             PearlHashSHA256


int main(int argc, char *const argv[]) {

    char *userName = "Robert Lee Mitchel";
    char *masterPassword = "banana colored duckling";
    char *siteName = "masterpasswordapp.com";
    uint32_t siteCounter = 1;
    MPElementType siteType = MPElementTypeGeneratedLong;

    // Start MP
    struct timeval startTime;
    if (gettimeofday(&startTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }

    int iterations = 100;
    for (int i = 0; i < iterations; ++i) {
        // Calculate the master key salt.
        char *mpNameSpace = "com.lyndir.masterpassword";
        const uint32_t n_userNameLength = htonl(strlen(userName));
        const size_t masterKeySaltLength = strlen(mpNameSpace) + sizeof(n_userNameLength) + strlen(userName);
        char *masterKeySalt = malloc( masterKeySaltLength );
        if (!masterKeySalt) {
            fprintf(stderr, "Could not allocate master key salt: %d\n", errno);
            return 1;
        }

        char *mKS = masterKeySalt;
        memcpy(mKS, mpNameSpace, strlen(mpNameSpace)); mKS += strlen(mpNameSpace);
        memcpy(mKS, &n_userNameLength, sizeof(n_userNameLength)); mKS += sizeof(n_userNameLength);
        memcpy(mKS, userName, strlen(userName)); mKS += strlen(userName);
        if (mKS - masterKeySalt != masterKeySaltLength)
            abort();
        trc("masterKeySalt ID: %s\n", IDForBuf(masterKeySalt, masterKeySaltLength));

        // Calculate the master key.
        uint8_t *masterKey = malloc( MP_dkLen );
        if (!masterKey) {
            fprintf(stderr, "Could not allocate master key: %d\n", errno);
            return 1;
        }
        if (crypto_scrypt( (const uint8_t *)masterPassword, strlen(masterPassword), (const uint8_t *)masterKeySalt, masterKeySaltLength, MP_N, MP_r, MP_p, masterKey, MP_dkLen ) < 0) {
            fprintf(stderr, "Could not generate master key: %d\n", errno);
            return 1;
        }
        memset(masterKeySalt, 0, masterKeySaltLength);
        free(masterKeySalt);

        // Calculate the site seed.
        const uint32_t n_siteNameLength = htonl(strlen(siteName));
        const uint32_t n_siteCounter = htonl(siteCounter);
        const size_t sitePasswordInfoLength = strlen(mpNameSpace) + sizeof(n_siteNameLength) + strlen(siteName) + sizeof(n_siteCounter);
        char *sitePasswordInfo = malloc( sitePasswordInfoLength );
        if (!sitePasswordInfo) {
            fprintf(stderr, "Could not allocate site seed: %d\n", errno);
            return 1;
        }

        char *sPI = sitePasswordInfo;
        memcpy(sPI, mpNameSpace, strlen(mpNameSpace)); sPI += strlen(mpNameSpace);
        memcpy(sPI, &n_siteNameLength, sizeof(n_siteNameLength)); sPI += sizeof(n_siteNameLength);
        memcpy(sPI, siteName, strlen(siteName)); sPI += strlen(siteName);
        memcpy(sPI, &n_siteCounter, sizeof(n_siteCounter)); sPI += sizeof(n_siteCounter);
        if (sPI - sitePasswordInfo != sitePasswordInfoLength)
            abort();

        uint8_t sitePasswordSeed[32];
        HMAC_SHA256_Buf(masterKey, MP_dkLen, sitePasswordInfo, sitePasswordInfoLength, sitePasswordSeed);
        memset(masterKey, 0, MP_dkLen);
        memset(sitePasswordInfo, 0, sitePasswordInfoLength);
        free(masterKey);
        free(sitePasswordInfo);

        // Determine the cipher.
        const char *cipher = CipherForType(siteType, sitePasswordSeed[0]);
        trc("type %d, cipher: %s\n", siteType, cipher);
        if (strlen(cipher) > 32)
            abort();

        // Encode the password from the seed using the cipher.
        char *sitePassword = calloc(strlen(cipher) + 1, sizeof(char));
        for (int c = 0; c < strlen(cipher); ++c) {
            sitePassword[c] = CharacterFromClass(cipher[c], sitePasswordSeed[c + 1]);
            trc("class %c, character: %c\n", cipher[c], sitePassword[c]);
        }
        memset(sitePasswordSeed, 0, sizeof(sitePasswordSeed));

        if (i % 1 == 0)
            fprintf( stderr, "\rmpw: iteration %d / %d..", i, iterations );
    }

    // Output timing results.
    struct timeval endTime;
    if (gettimeofday(&endTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }
    long long secs = (endTime.tv_sec - startTime.tv_sec);
    long long usecs = (endTime.tv_usec - startTime.tv_usec);
    double elapsed = secs + usecs / 1000000.0;
    double mpwSpeed = iterations / elapsed;
    fprintf( stdout, " done.  %d iterations in %llds %lldµs -> %.2f/s\n", iterations, secs, usecs, mpwSpeed );

    // Start SHA-256
    if (gettimeofday(&startTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }

    iterations = 50000000;
    uint8_t hash[32];
    for (int i = 0; i < iterations; ++i) {
        SHA256_Buf(masterPassword, strlen(masterPassword), hash);

        if (i % 1000 == 0)
            fprintf( stderr, "\rsha256: iteration %d / %d..", i, iterations );
    }

    // Output timing results.
    if (gettimeofday(&endTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }
    secs = (endTime.tv_sec - startTime.tv_sec);
    usecs = (endTime.tv_usec - startTime.tv_usec);
    elapsed = secs + usecs / 1000000.0;
    double sha256Speed = iterations / elapsed;
    fprintf( stdout, " done.  %d iterations in %llds %lldµs -> %.2f/s\n", iterations, secs, usecs, sha256Speed );

    // Start BCrypt
    if (gettimeofday(&startTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }

    int bcrypt_cost = 9;
    iterations = 600;
    for (int i = 0; i < iterations; ++i) {
        crypt(masterPassword, crypt_gensalt("$2b$", bcrypt_cost, userName, strlen(userName)));

        if (i % 10 == 0)
            fprintf( stderr, "\rbcrypt (cost %d): iteration %d / %d..", bcrypt_cost, i, iterations );
    }

    // Output timing results.
    if (gettimeofday(&endTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }
    secs = (endTime.tv_sec - startTime.tv_sec);
    usecs = (endTime.tv_usec - startTime.tv_usec);
    elapsed = secs + usecs / 1000000.0;
    double bcrypt9Speed = iterations / elapsed;
    fprintf( stdout, " done.  %d iterations in %llds %lldµs -> %.2f/s\n", iterations, secs, usecs, bcrypt9Speed );

    // Summarize.
    fprintf( stdout, "\n== SUMMARY ==\nOn this machine,\n" );
    fprintf( stdout, "mpw is %f times slower than sha256\n", sha256Speed / mpwSpeed );
    fprintf( stdout, "mpw is %f times slower than bcrypt (cost 9)\n", bcrypt9Speed / mpwSpeed );

    return 0;
}
