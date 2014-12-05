#define _GNU_SOURCE

#include <stdio.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#if defined(__linux__)
#include <linux/fs.h>
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

#define MP_env_fullname     "MP_FULLNAME"
#define MP_env_sitetype     "MP_SITETYPE"
#define MP_env_sitecounter  "MP_SITECOUNTER"

void usage() {
      fprintf(stderr, "Usage: mpw [-u name] [-t type] [-c counter] site\n\n");
      fprintf(stderr, "    -u name      Specify the full name of the user.\n"
                      "                 Defaults to %s in env.\n\n", MP_env_fullname);
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
      fprintf(stderr, "    ENVIRONMENT\n\n"
                      "        MP_FULLNAME    | The full name of the user.\n"
                      "        MP_SITETYPE    | The default password template.\n"
                      "        MP_SITECOUNTER | The default counter value.\n\n");
      exit(0);
}

char *homedir(const char *filename) {
    char *homedir = NULL;
    struct passwd* passwd = getpwuid(getuid());
    if (passwd)
        homedir = passwd->pw_dir;
    if (!homedir)
        homedir = getenv("HOME");
    if (!homedir)
        homedir = getcwd(NULL, 0);

    char *homefile = NULL;
    asprintf(&homefile, "%s/%s", homedir, filename);
    return homefile;
}

char *getlinep(const char *prompt) {
    char *buf = NULL;
    size_t bufSize = 0;
    ssize_t lineSize;
    fprintf(stderr, "%s", prompt);
    fprintf(stderr, " ");
    if ((lineSize = getline(&buf, &bufSize, stdin)) < 0) {
        free(buf);
        return NULL;
    }
    buf[lineSize - 1]=0;
    return buf;
}

int main(int argc, char *const argv[]) {

    // Read the environment.
    char *fullName = getenv( MP_env_fullname );
    const char *masterPassword = NULL;
    const char *siteName = NULL;
    MPSiteType siteType = MPSiteTypeGeneratedLong;
    const char *siteTypeString = getenv( MP_env_sitetype );
    MPSiteVariant siteVariant = MPSiteVariantPassword;
    const char *siteVariantString = NULL;
    const char *siteContextString = NULL;
    uint32_t siteCounter = 1;
    const char *siteCounterString = getenv( MP_env_sitecounter );

    // Read the options.
    for (int opt; (opt = getopt(argc, argv, "u:t:c:v:C:h")) != -1;)
      switch (opt) {
          case 'u':
              fullName = optarg;
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
                  fprintf(stderr, "Missing full name to option: -%c\n", optopt);
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
    if (!fullName) {
        if (!(fullName = getlinep("Your full name:"))) {
            fprintf(stderr, "Missing full name.\n");
            return 1;
        }
    }
    trc("fullName: %s\n", fullName);
    if (!siteName) {
        if (!(siteName = getlinep("Site name:"))) {
            fprintf(stderr, "Missing site name.\n");
            return 1;
        }
    }
    if (siteCounterString)
        siteCounter = atoi( siteCounterString );
    if (siteCounter < 1) {
        fprintf(stderr, "Invalid site counter: %d\n", siteCounter);
        return 1;
    }
    if (siteVariantString)
        siteVariant = VariantWithName( siteVariantString );
    if (siteVariant == MPSiteVariantLogin)
        siteType = MPSiteTypeGeneratedName;
    if (siteVariant == MPSiteVariantAnswer)
        siteType = MPSiteTypeGeneratedPhrase;
    if (siteTypeString)
        siteType = TypeWithName( siteTypeString );

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
        while ((linelen = getline(&line, &linecap, mpwConfig)) > 0) {
            char *lineData = line;
            if (strcmp(strsep(&lineData, ":"), fullName) == 0) {
                masterPassword = strcpy(malloc(strlen(lineData)), strsep(&lineData, "\n"));
                break;
            }
        }
        free(line);
    }
    while (!masterPassword)
        masterPassword = getpass( "Your master password: " );
    trc("masterPassword: %s\n", masterPassword);

    // Summarize operation.
    fprintf(stderr, "%s's password for %s:\n[ %s ]: ", fullName, siteName, Identicon( fullName, masterPassword ));
    struct timeval startTime;
    if (gettimeofday(&startTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }

    // Calculate the master key salt.
    const char *mpKeyScope = ScopeForVariant(MPSiteVariantPassword);
    trc("key scope: %s\n", mpKeyScope);
    const uint32_t n_fullNameLength = htonl(strlen(fullName));
    const size_t masterKeySaltLength = strlen(mpKeyScope) + sizeof(n_fullNameLength) + strlen(fullName);
    char *masterKeySalt = (char *)malloc( masterKeySaltLength );
    if (!masterKeySalt) {
        fprintf(stderr, "Could not allocate master key salt: %d\n", errno);
        return 1;
    }

    char *mKS = masterKeySalt;
    memcpy(mKS, mpKeyScope, strlen(mpKeyScope)); mKS += strlen(mpKeyScope);
    memcpy(mKS, &n_fullNameLength, sizeof(n_fullNameLength)); mKS += sizeof(n_fullNameLength);
    memcpy(mKS, fullName, strlen(fullName)); mKS += strlen(fullName);
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
    struct timeval endTime;
    if (gettimeofday(&endTime, NULL) != 0) {
        fprintf(stderr, "Could not get time: %d\n", errno);
        return 1;
    }
    long long secs = (endTime.tv_sec - startTime.tv_sec);
    long long usecs = (endTime.tv_usec - startTime.tv_usec);
    double elapsed = secs + usecs / 1000000.0;
    trc("masterKey ID: %s (derived in %.2fs)\n", IDForBuf(masterKey, MP_dkLen), elapsed);

    // Calculate the site seed.
    trc("siteName: %s\n", siteName);
    trc("siteCounter: %d\n", siteCounter);
    trc("siteVariant: %d (%s)\n", siteVariant, siteVariantString);
    trc("siteType: %d (%s)\n", siteType, siteTypeString);
    const char *siteScope = ScopeForVariant(siteVariant);
    trc("site scope: %s, context: %s\n", siteScope, siteContextString == NULL? "<empty>": siteContextString);
    const uint32_t n_siteNameLength = htonl(strlen(siteName));
    const uint32_t n_siteCounter = htonl(siteCounter);
    const uint32_t n_siteContextLength = siteContextString == NULL? 0: htonl(strlen(siteContextString));
    size_t sitePasswordInfoLength = strlen(siteScope) + sizeof(n_siteNameLength) + strlen(siteName) + sizeof(n_siteCounter);
    if (siteContextString)
        sitePasswordInfoLength += sizeof(n_siteContextLength) + strlen(siteContextString);
    char *sitePasswordInfo = (char *)malloc( sitePasswordInfoLength );
    if (!sitePasswordInfo) {
        fprintf(stderr, "Could not allocate site seed: %d\n", errno);
        return 1;
    }

    char *sPI = sitePasswordInfo;
    memcpy(sPI, siteScope, strlen(siteScope)); sPI += strlen(siteScope);
    memcpy(sPI, &n_siteNameLength, sizeof(n_siteNameLength)); sPI += sizeof(n_siteNameLength);
    memcpy(sPI, siteName, strlen(siteName)); sPI += strlen(siteName);
    memcpy(sPI, &n_siteCounter, sizeof(n_siteCounter)); sPI += sizeof(n_siteCounter);
    if (siteContextString) {
        memcpy(sPI, &n_siteContextLength, sizeof(n_siteContextLength)); sPI += sizeof(n_siteContextLength);
        memcpy(sPI, siteContextString, strlen(siteContextString)); sPI += strlen(siteContextString);
    }
    if (sPI - sitePasswordInfo != sitePasswordInfoLength)
        abort();
    trc("seed from: hmac-sha256(masterKey, %s | %s | %s | %s | %s | %s)\n", siteScope, Hex(&n_siteNameLength, sizeof(n_siteNameLength)), siteName, Hex(&n_siteCounter, sizeof(n_siteCounter)), Hex(&n_siteContextLength, sizeof(n_siteContextLength)), siteContextString);
    trc("sitePasswordInfo ID: %s\n", IDForBuf(sitePasswordInfo, sitePasswordInfoLength));

    uint8_t sitePasswordSeed[32];
    HMAC_SHA256_Buf(masterKey, MP_dkLen, sitePasswordInfo, sitePasswordInfoLength, sitePasswordSeed);
    memset(masterKey, 0, MP_dkLen);
    memset(sitePasswordInfo, 0, sitePasswordInfoLength);
    free(masterKey);
    free(sitePasswordInfo);
    trc("sitePasswordSeed ID: %s\n", IDForBuf(sitePasswordSeed, 32));

    // Determine the template.
    const char *template = TemplateForType(siteType, sitePasswordSeed[0]);
    trc("type %s, template: %s\n", siteTypeString, template);
    if (strlen(template) > 32)
        abort();

    // Encode the password from the seed using the template.
    char *sitePassword = (char *)calloc(strlen(template) + 1, sizeof(char));
    for (int c = 0; c < strlen(template); ++c) {
        sitePassword[c] = CharacterFromClass(template[c], sitePasswordSeed[c + 1]);
        trc("class %c, index %u (0x%02X) -> character: %c\n", template[c], sitePasswordSeed[c + 1], sitePasswordSeed[c + 1], sitePassword[c]);
    }
    memset(sitePasswordSeed, 0, sizeof(sitePasswordSeed));

    // Output the password.
    fprintf( stdout, "%s\n", sitePassword );
    return 0;
}
