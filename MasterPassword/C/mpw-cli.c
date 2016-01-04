#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <pwd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#if defined(READLINE)
#include <readline/readline.h>
#elif defined(EDITLINE)
#include <histedit.h>
#endif

#include "mpw-algorithm.h"
#include "mpw-util.h"

#define MP_env_fullname     "MP_FULLNAME"
#define MP_env_sitetype     "MP_SITETYPE"
#define MP_env_sitecounter  "MP_SITECOUNTER"
#define MP_env_algorithm    "MP_ALGORITHM"

static void usage() {

    fprintf( stderr, "Usage: mpw [-u name] [-t type] [-c counter] [-a algorithm] [-V variant] [-C context] [-v|-q] [-h] site\n\n" );
    fprintf( stderr, "    -u name      Specify the full name of the user.\n"
            "                 Defaults to %s in env or prompts.\n\n", MP_env_fullname );
    fprintf( stderr, "    -t type      Specify the password's template.\n"
            "                 Defaults to %s in env or 'long' for password, 'name' for login.\n"
            "                     x, max, maximum | 20 characters, contains symbols.\n"
            "                     l, long         | Copy-friendly, 14 characters, contains symbols.\n"
            "                     m, med, medium  | Copy-friendly, 8 characters, contains symbols.\n"
            "                     b, basic        | 8 characters, no symbols.\n"
            "                     s, short        | Copy-friendly, 4 characters, no symbols.\n"
            "                     i, pin          | 4 numbers.\n"
            "                     n, name         | 9 letter name.\n"
            "                     p, phrase       | 20 character sentence.\n\n", MP_env_sitetype );
    fprintf( stderr, "    -c counter   The value of the counter.\n"
            "                 Defaults to %s in env or 1.\n\n", MP_env_sitecounter );
    fprintf( stderr, "    -a version   The algorithm version to use.\n"
            "                 Defaults to %s in env or %d.\n\n", MP_env_algorithm, MPAlgorithmVersionCurrent );
    fprintf( stderr, "    -V variant   The kind of content to generate.\n"
            "                 Defaults to 'password'.\n"
            "                     p, password | The password to log in with.\n"
            "                     l, login    | The username to log in as.\n"
            "                     a, answer   | The answer to a security question.\n\n" );
    fprintf( stderr, "    -C context   A variant-specific context.\n"
            "                 Defaults to empty.\n"
            "                  -V p, password | Doesn't currently use a context.\n"
            "                  -V l, login    | Doesn't currently use a context.\n"
            "                  -V a, answer   | Empty for a universal site answer or\n"
            "                                 | the most significant word(s) of the question.\n\n" );
    fprintf( stderr, "    -v           Increase output verbosity (can be repeated).\n\n" );
    fprintf( stderr, "    -q           Decrease output verbosity (can be repeated).\n\n" );
    fprintf( stderr, "    ENVIRONMENT\n\n"
            "        %-14s | The full name of the user (see -u).\n"
            "        %-14s | The default password template (see -t).\n"
            "        %-14s | The default counter value (see -c).\n"
            "        %-14s | The default algorithm version (see -a).\n\n",
            MP_env_fullname, MP_env_sitetype, MP_env_sitecounter, MP_env_algorithm );
    exit( 0 );
}

static char *homedir(const char *filename) {

    char *homedir = NULL;
    struct passwd *passwd = getpwuid( getuid() );
    if (passwd)
        homedir = passwd->pw_dir;
    if (!homedir)
        homedir = getenv( "HOME" );
    if (!homedir)
        homedir = getcwd( NULL, 0 );

    char *homefile = NULL;
    asprintf( &homefile, "%s/%s", homedir, filename );
    return homefile;
}

static char *getlinep(const char *prompt) {

    char *buf = NULL;
    size_t bufSize = 0;
    ssize_t lineSize;
    fprintf( stderr, "%s", prompt );
    fprintf( stderr, " " );
    if ((lineSize = getline( &buf, &bufSize, stdin )) < 0) {
        free( buf );
        return NULL;
    }
    buf[lineSize - 1] = 0;
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
    MPAlgorithmVersion algorithmVersion = MPAlgorithmVersionCurrent;
    const char *algorithmVersionString = getenv( MP_env_algorithm );
    if (algorithmVersionString && strlen( algorithmVersionString ))
        if (sscanf( algorithmVersionString, "%u", &algorithmVersion ) != 1)
            ftl( "Invalid %s: %s\n", MP_env_algorithm, algorithmVersionString );

    // Read the options.
    for (int opt; (opt = getopt( argc, argv, "u:P:t:c:V:a:C:vqh" )) != -1;)
        switch (opt) {
            case 'u':
                fullName = optarg;
                break;
            case 'P':
                // Do not use this.  Passing your master password via the command-line
                // is insecure.  This is here for non-interactive testing purposes only.
                masterPassword = strcpy( malloc( strlen( optarg ) + 1 ), optarg );
                break;
            case 't':
                siteTypeString = optarg;
                break;
            case 'c':
                siteCounterString = optarg;
                break;
            case 'V':
                siteVariantString = optarg;
                break;
            case 'a':
                if (sscanf( optarg, "%u", &algorithmVersion ) != 1)
                    ftl( "Not a version: %s\n", optarg );
                break;
            case 'C':
                siteContextString = optarg;
                break;
            case 'v':
                ++mpw_verbosity;
                break;
            case 'q':
                --mpw_verbosity;
                break;
            case 'h':
                usage();
                break;
            case '?':
                switch (optopt) {
                    case 'u':
                        ftl( "Missing full name to option: -%c\n", optopt );
                        break;
                    case 't':
                        ftl( "Missing type name to option: -%c\n", optopt );
                        break;
                    case 'c':
                        ftl( "Missing counter value to option: -%c\n", optopt );
                        break;
                    default:
                        ftl( "Unknown option: -%c\n", optopt );
                }
            default:
                ftl("Unexpected option: %c", opt);
        }
    if (optind < argc)
        siteName = argv[optind];

    // Convert and validate input.
    if (!fullName && !(fullName = getlinep( "Your full name:" )))
        ftl( "Missing full name.\n" );
    if (!siteName && !(siteName = getlinep( "Site name:" )))
        ftl( "Missing site name.\n" );
    if (siteCounterString)
        siteCounter = (uint32_t)atol( siteCounterString );
    if (siteCounter < 1)
        ftl( "Invalid site counter: %d\n", siteCounter );
    if (siteVariantString)
        siteVariant = mpw_variantWithName( siteVariantString );
    if (siteVariant == MPSiteVariantLogin)
        siteType = MPSiteTypeGeneratedName;
    if (siteVariant == MPSiteVariantAnswer)
        siteType = MPSiteTypeGeneratedPhrase;
    if (siteTypeString)
        siteType = mpw_typeWithName( siteTypeString );
    trc( "algorithmVersion: %u\n", algorithmVersion );

    // Read the master password.
    char *mpwConfigPath = homedir( ".mpw" );
    if (!mpwConfigPath)
        ftl( "Couldn't resolve path for configuration file: %d\n", errno );
    trc( "mpwConfigPath: %s\n", mpwConfigPath );
    FILE *mpwConfig = fopen( mpwConfigPath, "r" );
    free( mpwConfigPath );
    if (mpwConfig) {
        char *line = NULL;
        size_t linecap = 0;
        while (getline( &line, &linecap, mpwConfig ) > 0) {
            char *lineData = line;
            if (strcmp( strsep( &lineData, ":" ), fullName ) == 0) {
                masterPassword = strcpy( malloc( strlen( lineData ) ), strsep( &lineData, "\n" ) );
                break;
            }
        }
        mpw_free( line, linecap );
    }
    while (!masterPassword || !strlen(masterPassword))
        masterPassword = getpass( "Your master password: " );

    // Summarize operation.
    fprintf( stderr, "%s's password for %s:\n[ %s ]: ", fullName, siteName, mpw_identicon( fullName, masterPassword ) );

    // Output the password.
    const uint8_t *masterKey = mpw_masterKeyForUser(
            fullName, masterPassword, algorithmVersion );
    mpw_freeString( masterPassword );
    if (!masterKey)
        ftl( "Couldn't derive master key." );

    const char *sitePassword = mpw_passwordForSite(
            masterKey, siteName, siteType, siteCounter, siteVariant, siteContextString, algorithmVersion );
    mpw_free( masterKey, MP_dkLen );
    if (!sitePassword)
        ftl( "Couldn't derive site password." );

    fprintf( stdout, "%s\n", sitePassword );
    return 0;
}
