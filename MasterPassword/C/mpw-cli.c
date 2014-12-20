#define _GNU_SOURCE

#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <pwd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "types.h"
#include "mpw.h"

#if defined(READLINE)
#include <readline/readline.h>
#elif defined(EDITLINE)
#include <histedit.h>
#endif

#define MP_env_fullname     "MP_FULLNAME"
#define MP_env_sitetype     "MP_SITETYPE"
#define MP_env_sitecounter  "MP_SITECOUNTER"

static void usage() {

    fprintf( stderr, "Usage: mpw [-u name] [-t type] [-c counter] site\n\n" );
    fprintf( stderr, "    -u name      Specify the full name of the user.\n"
            "                 Defaults to %s in env.\n\n", MP_env_fullname );
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
            "                 Defaults to %s in env or '1'.\n\n", MP_env_sitecounter );
    fprintf( stderr, "    -v variant   The kind of content to generate.\n"
            "                 Defaults to 'password'.\n"
            "                     p, password | The password to log in with.\n"
            "                     l, login    | The username to log in as.\n"
            "                     a, answer   | The answer to a security question.\n\n" );
    fprintf( stderr, "    -C context   A variant-specific context.\n"
            "                 Defaults to empty.\n"
            "                  -v p, password | Doesn't currently use a context.\n"
            "                  -v l, login    | Doesn't currently use a context.\n"
            "                  -v a, answer   | Empty for a universal site answer or\n"
            "                                 | the most significant word(s) of the question.\n\n" );
    fprintf( stderr, "    ENVIRONMENT\n\n"
            "        MP_FULLNAME    | The full name of the user.\n"
            "        MP_SITETYPE    | The default password template.\n"
            "        MP_SITECOUNTER | The default counter value.\n\n" );
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

    // Read the options.
    for (int opt; (opt = getopt( argc, argv, "u:t:c:v:C:h" )) != -1;)
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
                        fprintf( stderr, "Missing full name to option: -%c\n", optopt );
                        break;
                    case 't':
                        fprintf( stderr, "Missing type name to option: -%c\n", optopt );
                        break;
                    case 'c':
                        fprintf( stderr, "Missing counter value to option: -%c\n", optopt );
                        break;
                    default:
                        fprintf( stderr, "Unknown option: -%c\n", optopt );
                }
                return 1;
            default:
                abort();
        }
    if (optind < argc)
        siteName = argv[optind];

    // Convert and validate input.
    if (!fullName) {
        if (!(fullName = getlinep( "Your full name:" ))) {
            fprintf( stderr, "Missing full name.\n" );
            return 1;
        }
    }
    if (!siteName) {
        if (!(siteName = getlinep( "Site name:" ))) {
            fprintf( stderr, "Missing site name.\n" );
            return 1;
        }
    }
    if (siteCounterString)
        siteCounter = atoi( siteCounterString );
    if (siteCounter < 1) {
        fprintf( stderr, "Invalid site counter: %d\n", siteCounter );
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
    char *mpwConfigPath = homedir( ".mpw" );
    if (!mpwConfigPath) {
        fprintf( stderr, "Couldn't resolve path for configuration file: %d\n", errno );
        return 1;
    }
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
        free( line );
    }
    while (!masterPassword)
        masterPassword = getpass( "Your master password: " );

    // Summarize operation.
    fprintf( stderr, "%s's password for %s:\n[ %s ]: ", fullName, siteName, Identicon( fullName, masterPassword ) );

    // Output the password.
    uint8_t *masterKey = mpw_masterKeyForUser( fullName, masterPassword );
    char *sitePassword = mpw_passwordForSite( masterKey, siteName, siteType, siteCounter, siteVariant, siteContextString );
    fprintf( stdout, "%s\n", sitePassword );

    return 0;
}
