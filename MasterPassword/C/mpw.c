#define _GNU_SOURCE

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
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <alg/sha256.h>
#include <crypto/crypto_scrypt.h>
#include "types.h"

#if defined(READLINE)
#include <readline/readline.h>
#elif defined(EDITLINE)
#include <histedit.h>
#endif

#define MP_N                32768
#define MP_r                8
#define MP_p                2
#define MP_dkLen            64
#define MP_hash             PearlHashSHA256

#define MP_env_username     "MP_USERNAME"
#define MP_env_sitetype     "MP_SITETYPE"
#define MP_env_sitecounter  "MP_SITECOUNTER"

void usage() {
      fprintf(stderr, "Usage: mpw [-u name] [-t type] [-c counter] site\n\n");
      fprintf(stderr, "    -u name      Specify the full name of the user.\n"
                      "                 Defaults to %s in env.\n\n", MP_env_username);
      fprintf(stderr, "    -t type      Specify the password's template.\n"
                      "                 Defaults to %s in env or 'long' for password, 'name' for login.\n"
                      "                     x, max, maximum | 20 characters, contains symbols.\n"
                      "                     l, long         | Copy-friendly, 14 characters, contains symbols.\n"
                      "                     m, med, medium  | Copy-friendly, 8 characters, contains symbols.\n"
                      "                     b, basic        | 8 characters, no symbols.\n"
                      "                     s, short        | Copy-friendly, 4 characters, no symbols.\n"
                      "                     i, pin          | 4 numbers.\n"
                      "                     n, name         | 9 letter name.\n"
                      "                     p, phrase       | 20 character sentence.\n\n", MP_env_sitetype);
      fprintf(stderr, "    -c counter   The value of the counter.\n"
                      "                 Defaults to %s in env or '1'.\n\n", MP_env_sitecounter);
      fprintf(stderr, "    -v variant   The kind of content to generate.\n"
                      "                 Defaults to 'password'.\n"
                      "                     p, password | The password to log in with.\n"
                      "                     l, login    | The username to log in as.\n"
                      "                     a, answer   | The answer to a security question.\n\n");
      fprintf(stderr, "    -C context   A variant-specific context.\n"
                      "                 Defaults to empty.\n"
                      "                  -v p, password | Doesn't currently use a context.\n"
                      "                  -v l, login    | Doesn't currently use a context.\n"
                      "                  -v a, answer   | Empty for a universal site answer or\n"
                      "                                 | the most significant word(s) of the question.\n\n");
      exit(0);
}

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

    if (argc < 2)
        usage();

    // Read the environment.
    const char *userName = getenv( MP_env_username );
    const char *masterPassword = NULL;
    const char *siteName = NULL;
    MPElementType siteType = MPElementTypeGeneratedLong;
    const char *siteTypeString = getenv( MP_env_sitetype );
    MPElementVariant siteVariant = MPElementVariantPassword;
    const char *siteVariantString = NULL;
    const char *siteContextString = NULL;
    uint32_t siteCounter = 1;
    const char *siteCounterString = getenv( MP_env_sitecounter );

    // Read the options.
    for (int opt; (opt = getopt(argc, argv, "u:t:c:v:C:h")) != -1;)
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
          case 'v':
              siteVariantString = optarg;
              break;
          case 'C':
              siteContextString = optarg;
              break;
          case 'h':
              usage();
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
    if (siteVariantString)
        siteVariant = VariantWithName( siteVariantString );
    trc("siteVariant: %d (%s)\n", siteVariant, siteVariantString);
    if (siteVariant == MPElementVariantLogin)
        siteType = MPElementTypeGeneratedName;
    if (siteVariant == MPElementVariantAnswer)
        siteType = MPElementTypeGeneratedPhrase;
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
    free(mpwConfigPath);
    if (mpwConfig) {
        char *line = NULL;
        size_t linecap = 0;
        ssize_t linelen;
        while ((linelen = getline(&line, &linecap, mpwConfig)) > 0)
            if (strcmp(strsep(&line, ":"), userName) == 0) {
                masterPassword = strsep(&line, "\n");
                break;
            }
    }
    while (!masterPassword)
        masterPassword = getpass( "Your master password: " );
    trc("masterPassword: %s\n", masterPassword);

    // Calculate the master key salt.
    const char *mpKeyScope = ScopeForVariant(MPElementVariantPassword);
    trc("key scope: %s\n", mpKeyScope);
    const uint32_t n_userNameLength = htonl(strlen(userName));
    const size_t masterKeySaltLength = strlen(mpKeyScope) + sizeof(n_userNameLength) + strlen(userName);
    char *masterKeySalt = (char *)malloc( masterKeySaltLength );
    if (!masterKeySalt) {
        fprintf(stderr, "Could not allocate master key salt: %d\n", errno);
        return 1;
    }

    char *mKS = masterKeySalt;
    memcpy(mKS, mpKeyScope, strlen(mpKeyScope)); mKS += strlen(mpKeyScope);
    memcpy(mKS, &n_userNameLength, sizeof(n_userNameLength)); mKS += sizeof(n_userNameLength);
    memcpy(mKS, userName, strlen(userName)); mKS += strlen(userName);
    if (mKS - masterKeySalt != masterKeySaltLength)
        abort();
    trc("masterKeySalt ID: %s\n", IDForBuf(masterKeySalt, masterKeySaltLength));

    // Calculate the master key.
    uint8_t *masterKey = (uint8_t *)malloc( MP_dkLen );
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
    trc("masterPassword Hex: %s\n", Hex(masterPassword, strlen(masterPassword)));
    trc("masterPassword ID: %s\n", IDForBuf(masterPassword, strlen(masterPassword)));
    trc("masterKey ID: %s\n", IDForBuf(masterKey, MP_dkLen));

    // Calculate the site seed.
    const char *mpSiteScope = ScopeForVariant(siteVariant);
    trc("site scope: %s, context: %s\n", mpSiteScope, siteContextString == NULL? "<empty>": siteContextString);
    const uint32_t n_siteNameLength = htonl(strlen(siteName));
    const uint32_t n_siteCounter = htonl(siteCounter);
    const uint32_t n_siteContextLength = siteContextString == NULL? 0: htonl(strlen(siteContextString));
    size_t sitePasswordInfoLength = strlen(mpSiteScope) + sizeof(n_siteNameLength) + strlen(siteName) + sizeof(n_siteCounter);
    if (siteContextString)
        sitePasswordInfoLength += sizeof(n_siteContextLength) + strlen(siteContextString);
    char *sitePasswordInfo = (char *)malloc( sitePasswordInfoLength );
    if (!sitePasswordInfo) {
        fprintf(stderr, "Could not allocate site seed: %d\n", errno);
        return 1;
    }

    char *sPI = sitePasswordInfo;
    memcpy(sPI, mpSiteScope, strlen(mpSiteScope)); sPI += strlen(mpSiteScope);
    memcpy(sPI, &n_siteNameLength, sizeof(n_siteNameLength)); sPI += sizeof(n_siteNameLength);
    memcpy(sPI, siteName, strlen(siteName)); sPI += strlen(siteName);
    memcpy(sPI, &n_siteCounter, sizeof(n_siteCounter)); sPI += sizeof(n_siteCounter);
    if (siteContextString) {
        memcpy(sPI, &n_siteContextLength, sizeof(n_siteContextLength)); sPI += sizeof(n_siteContextLength);
        memcpy(sPI, siteContextString, strlen(siteContextString)); sPI += strlen(siteContextString);
    }
    if (sPI - sitePasswordInfo != sitePasswordInfoLength)
        abort();
    trc("seed from: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)\n", mpSiteScope, Hex(&n_siteNameLength, sizeof(n_siteNameLength)), siteName, Hex(&n_siteCounter, sizeof(n_siteCounter)), Hex(&n_siteContextLength, sizeof(n_siteContextLength)), siteContextString);
    trc("sitePasswordInfo ID: %s\n", IDForBuf(sitePasswordInfo, sitePasswordInfoLength));

    uint8_t sitePasswordSeed[32];
    HMAC_SHA256_Buf(masterKey, MP_dkLen, sitePasswordInfo, sitePasswordInfoLength, sitePasswordSeed);
    memset(masterKey, 0, MP_dkLen);
    memset(sitePasswordInfo, 0, sitePasswordInfoLength);
    free(masterKey);
    free(sitePasswordInfo);
    trc("sitePasswordSeed ID: %s\n", IDForBuf(sitePasswordSeed, 32));

    // Determine the cipher.
    const char *cipher = CipherForType(siteType, sitePasswordSeed[0]);
    trc("type %s, cipher: %s\n", siteTypeString, cipher);
    if (strlen(cipher) > 32)
        abort();

    // Encode the password from the seed using the cipher.
    char *sitePassword = (char *)calloc(strlen(cipher) + 1, sizeof(char));
    for (int c = 0; c < strlen(cipher); ++c) {
        sitePassword[c] = CharacterFromClass(cipher[c], sitePasswordSeed[c + 1]);
        trc("class %c, character: %c\n", cipher[c], sitePassword[c]);
    }
    memset(sitePasswordSeed, 0, sizeof(sitePasswordSeed));

    // Output the password.
    fprintf( stdout, "%s\n", sitePassword );
    return 0;
}
