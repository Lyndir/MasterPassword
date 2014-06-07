#include <stdio.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#if defined(__linux__)
#include <linux/fs.h>
#elif defined(__CYGWIN__)
#include <cygwin/fs.h>
#else
#include <sys/disk.h>
#endif
#include <fcntl.h>
#include <unistd.h>
#include <math.h>
#include <pwd.h>
#include <uuid/uuid.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <alg/sha256.h>
#include <crypto/crypto_scrypt.h>
#include "types.h"

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_dkLen            64
#define MP_hash             PearlHashSHA256

#define MP_env_username     "MP_USERNAME"
#define MP_env_sitetype     "MP_SITETYPE"
#define MP_env_sitecounter  "MP_SITECOUNTER"

char *homedir(const char *filename) {
    char *homedir = NULL;
#if defined(__CYGWIN__)
    homedir = getenv("USERPROFILE");
    if (!homedir) {
        const char *homeDrive = getenv("HOMEDRIVE");
        const char *homePath = getenv("HOMEPATH");
        homedir = char[strlen(homeDrive) + strlen(homePath) + 1];
        sprintf(homedir, "%s/%s", homeDrive, homePath);
    }
#else
    struct passwd* passwd = getpwuid(getuid());
    if (passwd)
        homedir = passwd->pw_dir;
    if (!homedir)
        homedir = getenv("HOME");
#endif
    if (!homedir)
        homedir = getcwd(NULL, 0);

    char *homefile = NULL;
    asprintf(&homefile, "%s/%s", homedir, filename);
    return homefile;
}

int main(int argc, char *const argv[]) {

    // Read the environment.
    const char *userName = getenv( MP_env_username );
    const char *masterPassword = NULL;
    const char *siteName = NULL;
    MPElementType siteType = MPElementTypeGeneratedLong;
    const char *siteTypeString = getenv( MP_env_sitetype );
    uint32_t siteCounter = 1;
    const char *siteCounterString = getenv( MP_env_sitecounter );

    // Read the options.
    char opt;
    while ((opt = getopt(argc, argv, "u:t:c:")) != -1)
      switch (opt) {
        case 'u':
          userName = optarg;
          break;
        case 't':
          siteTypeString = optarg;
          break;
        case 'c':
          siteCounterString = optarg;
          break;
        case '?':
          switch (optopt) {
            case 'u':
              fprintf(stderr, "Missing user name to option: -%c\n", optopt);
              break;
            case 't':
              fprintf(stderr, "Missing type name to option: -%c\n", optopt);
              break;
            case 'c':
              fprintf(stderr, "Missing counter value to option: -%c\n", optopt);
              break;
            default:
              fprintf(stderr, "Unknown option: -%c\n", optopt);
          }
          return 1;
        default:
          abort();
      }
    if (optind < argc)
        siteName = argv[optind];

    // Convert and validate input.
    if (!userName) {
        fprintf(stderr, "Missing user name.\n");
        return 1;
    }
    trc("userName: %s\n", userName);
    if (!siteName) {
        fprintf(stderr, "Missing site name.\n");
        return 1;
    }
    trc("siteName: %s\n", siteName);
    if (siteCounterString)
        siteCounter = atoi( siteCounterString );
    if (siteCounter < 1) {
        fprintf(stderr, "Invalid site counter: %d\n", siteCounter);
        return 1;
    }
    trc("siteCounter: %d\n", siteCounter);
    if (siteTypeString)
        siteType = TypeWithName( siteTypeString );
    trc("siteType: %d (%s)\n", siteType, siteTypeString);

    // Read the master password.
    char *mpwConfigPath = homedir(".mpw");
    if (!mpwConfigPath) {
        fprintf(stderr, "Couldn't resolve path for configuration file: %d\n", errno);
        return 1;
    }
    trc("mpwConfigPath: %s\n", mpwConfigPath);
    FILE *mpwConfig = fopen(mpwConfigPath, "r");
    if (!mpwConfig) {
        fprintf(stderr, "Couldn't open configuration file: %s: %d\n", mpwConfigPath, errno);
        return 1;
    }
    free(mpwConfigPath);
    char *line = NULL;
    size_t linecap = 0;
    ssize_t linelen;
    while ((linelen = getline(&line, &linecap, mpwConfig)) > 0)
        if (strcmp(strsep(&line, ":"), userName) == 0) {
            masterPassword = line;
            break;
        }
    if (!masterPassword) {
        fprintf(stderr, "Missing master password for user: %s\n", userName);
        return 1;
    }
    trc("masterPassword: %s\n", masterPassword);

    // Calculate the master key.
    uint8_t *masterKey = malloc( MP_dkLen );
    if (!masterKey) {
        fprintf(stderr, "Could not allocate master key: %d\n", errno);
        return 1;
    }
    const uint32_t n_userNameLength = htonl(strlen(userName));
    char *masterKeySalt = NULL;
    size_t masterKeySaltLength = asprintf(&masterKeySalt, "com.lyndir.masterpassword%s%s", (const char *) &n_userNameLength, userName);
    if (!masterKeySalt) {
        fprintf(stderr, "Could not allocate master key salt: %d\n", errno);
        return 1;
    }
    if (crypto_scrypt( (const uint8_t *)masterPassword, strlen(masterPassword), (const uint8_t *)masterKeySalt, masterKeySaltLength, MP_N, MP_r, MP_p, masterKey, MP_dkLen ) < 0) {
        fprintf(stderr, "Could not generate master key: %d\n", errno);
        return 1;
    }
    memset(masterKeySalt, 0, masterKeySaltLength);
    free(masterKeySalt);

    // Calculate the site seed.
    const uint32_t n_siteCounter = htonl(siteCounter), n_siteNameLength = htonl(strlen(siteName));
    char *sitePasswordInfo = NULL;
    size_t sitePasswordInfoLength = asprintf(&sitePasswordInfo, "com.lyndir.masterpassword%s%s%s", (const char *) &n_siteNameLength, siteName, (const char *) &n_siteCounter);
    if (!sitePasswordInfo) {
        fprintf(stderr, "Could not allocate site seed: %d\n", errno);
        return 1;
    }
    uint8_t sitePasswordSeed[32];
    HMAC_SHA256_Buf(masterKey, MP_dkLen, sitePasswordInfo, sitePasswordInfoLength, sitePasswordSeed);
    memset(masterKey, 0, MP_dkLen);
    memset(sitePasswordInfo, 0, sitePasswordInfoLength);
    free(masterKey);
    free(sitePasswordInfo);

    // Determine the cipher.
    const char *cipher = CipherForType(siteType, sitePasswordSeed[0]);
    trc("type %s, cipher: %s\n", siteTypeString, cipher);

    // Encode the password from the seed using the cipher.
    //NSAssert([seed length] >= [cipher length] + 1, @"Insufficient seed bytes to encode cipher.");
    char *sitePassword = calloc(strlen(cipher) + 1, sizeof(char));
    for (int c = 0; c < strlen(cipher); ++c) {
        sitePassword[c] = CharacterFromClass(cipher[c], sitePasswordSeed[c + 1]);
        trc("class %c, character: %c\n", cipher[c], sitePassword[c]);
    }
    memset(sitePasswordSeed, 0, sizeof(sitePasswordSeed));

    // Output the password.
    fprintf( stdout, "%s\n", sitePassword );
    return 0;
}
