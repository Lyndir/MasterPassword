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
#include "mpw-marshall.h"

#define MP_env_fullName     "MP_FULLNAME"
#define MP_env_algorithm    "MP_ALGORITHM"

static void usage() {

    inf( ""
            "Usage: mpw [-u name] [-t type] [-c counter] [-a algorithm] [-p purpose] [-C context] [-v|-q] [-h] site\n\n" );
    inf( ""
            "    -u name      Specify the full name of the user.\n"
            "                 Defaults to %s in env or prompts.\n\n", MP_env_fullName );
    inf( ""
            "    -t type      Specify the password's template.\n"
            "                 Defaults to 'long' for auth, 'name' for ident and 'phrase' for recovery.\n"
            "                     x, max, maximum | 20 characters, contains symbols.\n"
            "                     l, long         | Copy-friendly, 14 characters, contains symbols.\n"
            "                     m, med, medium  | Copy-friendly, 8 characters, contains symbols.\n"
            "                     b, basic        | 8 characters, no symbols.\n"
            "                     s, short        | Copy-friendly, 4 characters, no symbols.\n"
            "                     i, pin          | 4 numbers.\n"
            "                     n, name         | 9 letter name.\n"
            "                     p, phrase       | 20 character sentence.\n\n" );
    inf( ""
            "    -c counter   The value of the counter.\n"
            "                 Defaults to 1.\n\n" );
    inf( ""
            "    -a version   The algorithm version to use.\n"
            "                 Defaults to %s in env or %d.\n\n", MP_env_algorithm, MPAlgorithmVersionCurrent );
    inf( ""
            "    -p purpose   The purpose of the generated token.\n"
            "                 Defaults to 'password'.\n"
            "                     a, auth     | An authentication token such as a password.\n"
            "                     i, ident    | An identification token such as a username.\n"
            "                     r, rec      | A recovery token such as a security answer.\n\n" );
    inf( ""
            "    -C context   A purpose-specific context.\n"
            "                 Defaults to empty.\n"
            "                  -p a, auth     | -\n"
            "                  -p i, ident    | -\n"
            "                  -p r, rec      | Most significant word in security question.\n\n" );
    inf( ""
            "    -v           Increase output verbosity (can be repeated).\n\n" );
    inf( ""
            "    -q           Decrease output verbosity (can be repeated).\n\n" );
    inf( ""
            "    ENVIRONMENT\n\n"
            "        %-14s | The full name of the user (see -u).\n"
            "        %-14s | The default algorithm version (see -a).\n\n",
            MP_env_fullName, MP_env_algorithm );
    exit( 0 );
}

static char *mpwPath(const char *prefix, const char *extension) {

    char *homedir = NULL;
    struct passwd *passwd = getpwuid( getuid() );
    if (passwd)
        homedir = passwd->pw_dir;
    if (!homedir)
        homedir = getenv( "HOME" );
    if (!homedir)
        homedir = getcwd( NULL, 0 );

    char *mpwPath = NULL;
    asprintf( &mpwPath, "%s.%s", prefix, extension );

    char *slash = strstr( mpwPath, "/" );
    if (slash)
        *slash = '\0';

    asprintf( &mpwPath, "%s/.mpw.d/%s", homedir, mpwPath );
    return mpwPath;
}

static char *getline_prompt(const char *prompt) {

    char *buf = NULL;
    size_t bufSize = 0;
    ssize_t lineSize;
    fprintf( stderr, "%s", prompt );
    fprintf( stderr, " " );
    if ((lineSize = getline( &buf, &bufSize, stdin )) <= 1) {
        free( buf );
        return NULL;
    }
    buf[lineSize - 1] = 0;
    return buf;
}

int main(int argc, char *const argv[]) {

    // Master Password defaults.
    const char *fullName = NULL, *masterPassword = NULL, *siteName = NULL, *keyContext = NULL;
    MPPasswordType passwordType = MPPasswordTypeDefault;
    MPKeyPurpose keyPurpose = MPKeyPurposeAuthentication;
    MPAlgorithmVersion algorithmVersion = MPAlgorithmVersionCurrent;
    uint32_t siteCounter = 1;

    // Read the environment.
    const char *fullNameArg = getenv( MP_env_fullName ), *masterPasswordArg = NULL, *siteNameArg = NULL;
    const char *passwordTypeArg = NULL, *keyPurposeArg = NULL, *keyContextArg = NULL, *siteCounterArg = NULL;
    const char *algorithmVersionArg = getenv( MP_env_algorithm );

    // Read the command-line options.
    for (int opt; (opt = getopt( argc, argv, "u:P:t:c:V:a:C:vqh" )) != -1;)
        switch (opt) {
            case 'u':
                fullNameArg = optarg;
                break;
            case 'P':
                // Passing your master password via the command-line is insecure.  Testing purposes only.
                masterPasswordArg = optarg;
                break;
            case 't':
                passwordTypeArg = optarg;
                break;
            case 'c':
                siteCounterArg = optarg;
                break;
            case 'p':
                keyPurposeArg = optarg;
                break;
            case 'a':
                algorithmVersionArg = optarg;
                break;
            case 'C':
                keyContextArg = optarg;
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
                        abort();
                    case 't':
                        ftl( "Missing type name to option: -%c\n", optopt );
                        abort();
                    case 'c':
                        ftl( "Missing counter value to option: -%c\n", optopt );
                        abort();
                    default:
                        ftl( "Unknown option: -%c\n", optopt );
                        abort();
                }
            default:
                ftl( "Unexpected option: %c", opt );
                abort();
        }
    if (optind < argc)
        siteNameArg = argv[optind];

    // Empty strings unset the argument.
    fullNameArg = fullNameArg && strlen( fullNameArg )? fullNameArg: NULL;
    masterPasswordArg = masterPasswordArg && strlen( masterPasswordArg )? masterPasswordArg: NULL;
    siteNameArg = siteNameArg && strlen( siteNameArg )? siteNameArg: NULL;
    passwordTypeArg = passwordTypeArg && strlen( passwordTypeArg )? passwordTypeArg: NULL;
    keyPurposeArg = keyPurposeArg && strlen( keyPurposeArg )? keyPurposeArg: NULL;
    keyContextArg = keyContextArg && strlen( keyContextArg )? keyContextArg: NULL;
    siteCounterArg = siteCounterArg && strlen( siteCounterArg )? siteCounterArg: NULL;
    algorithmVersionArg = algorithmVersionArg && strlen( algorithmVersionArg )? algorithmVersionArg: NULL;

    // Determine fullName, siteName & masterPassword.
    if (!(fullNameArg && (fullName = strdup( fullNameArg ))) &&
        !(fullName = getline_prompt( "Your full name:" ))) {
        ftl( "Missing full name.\n" );
        abort();
    }
    if (!(siteNameArg && (siteName = strdup( siteNameArg ))) &&
        !(siteName = getline_prompt( "Site name:" ))) {
        ftl( "Missing site name.\n" );
        abort();
    }
    if (!(masterPasswordArg && (masterPassword = strdup( masterPasswordArg ))))
        while (!masterPassword || !strlen( masterPassword ))
            masterPassword = getpass( "Your master password: " );

    // Find the user's sites file.
    FILE *mpwSites = NULL;
    MPMarshallFormat mpwSitesFormat = MPMarshallFormatJSON;
    char *mpwSitesPath = mpwPath( fullName, "mpsites.json" );
    if (!mpwSitesPath || !(mpwSites = fopen( mpwSitesPath, "r" ))) {
        free( mpwSitesPath );
        mpwSitesFormat = MPMarshallFormatFlat;
        mpwSitesPath = mpwPath( fullName, "mpsites" );
        if (!mpwSitesPath || !(mpwSites = fopen( mpwSitesPath, "r" )))
            dbg( "Couldn't open configuration file:\n  %s: %s\n",
                    mpwSitesPath, strerror( errno ) );
    }

    // Read the user's sites file.
    if (mpwSites) {
        // Read file.
        size_t readAmount = 4096, bufSize = 0, bufPointer = 0, readSize = 0;
        char *buf = NULL;
        while ((buf = realloc( buf, bufSize += readAmount )) &&
               (bufPointer += (readSize = fread( buf + bufPointer, 1, readAmount, mpwSites ))) &&
               (readSize == readAmount));
        if (ferror( mpwSites ))
            wrn( "Error while reading configuration file:\n  %s: %d",
                    mpwSitesPath, ferror( mpwSites ) );
        fclose( mpwSites );

        // Parse file.
        MPMarshallError marshallError = MPMarshallSuccess;
        MPMarshalledUser *user = mpw_marshall_read( buf, mpwSitesFormat, masterPassword, &marshallError );
        mpw_free_string( buf );
        if (!user || marshallError != MPMarshallSuccess)
            wrn( "Couldn't parse configuration file:\n  %s: %s\n",
                    mpwSitesPath, mpw_explainMarshallError( marshallError ) );

        else {
            // Load defaults.
            mpw_free_string( fullName );
            mpw_free_string( masterPassword );
            fullName = strdup( user->name );
            masterPassword = strdup( user->masterPassword );
            algorithmVersion = user->algorithm;
            passwordType = user->defaultType;
            for (size_t s = 0; s < user->sites_count; ++s) {
                MPMarshalledSite site = user->sites[s];
                if (strcmp( siteName, site.name ) == 0) {
                    passwordType = site.type;
                    siteCounter = site.counter;
                    algorithmVersion = site.algorithm;
                    break;
                }
            }

            // Current format is not current, write out a new current format config file.
            if (mpwSitesFormat != MPMarshallFormatJSON) {
                mpwSitesPath = mpwPath( fullName, "mpsites.json" );
                if (!mpwSitesPath || !(mpwSites = fopen( mpwSitesPath, "w" )))
                    wrn( "Couldn't create updated configuration file:\n  %s: %s\n",
                            mpwSitesPath, strerror( errno ) );

                else {
                    buf = NULL;
                    if (!mpw_marshall_write( &buf, MPMarshallFormatJSON, user, &marshallError ) || marshallError != MPMarshallSuccess)
                        wrn( "Couldn't encode updated configuration file:\n  %s: %s",
                                mpwSitesPath, mpw_explainMarshallError( marshallError ) );

                    else if (fwrite( buf, sizeof( char ), strlen( buf ), mpwSites ) != strlen( buf ))
                        wrn( "Error while writing updated configuration file:\n  %s: %d\n",
                                mpwSitesPath, ferror( mpwSites ) );

                    mpw_free_string( buf );
                    fclose( mpwSites );
                }
            }
            mpw_marshal_free( user );
        }
    }
    free( mpwSitesPath );

    // Parse default/config-overriding command-line parameters.
    if (algorithmVersionArg) {
        int algorithmVersionInt = atoi( algorithmVersionArg );
        if (algorithmVersionInt < MPAlgorithmVersionFirst || algorithmVersionInt > MPAlgorithmVersionLast) {
            ftl( "Invalid algorithm version: %s\n", algorithmVersionArg );
            abort();
        }
        algorithmVersion = (MPAlgorithmVersion)algorithmVersionInt;
    }
    if (siteCounterArg) {
        long long int siteCounterInt = atoll( siteCounterArg );
        if (siteCounterInt < 0 || siteCounterInt > UINT32_MAX) {
            ftl( "Invalid site counter: %s\n", siteCounterArg );
            abort();
        }
        siteCounter = (uint32_t)siteCounterInt;
    }
    if (keyPurposeArg)
        keyPurpose = mpw_purposeWithName( keyPurposeArg );
    if (keyPurpose == MPKeyPurposeIdentification)
        passwordType = MPPasswordTypeGeneratedName;
    if (keyPurpose == MPKeyPurposeRecovery)
        passwordType = MPPasswordTypeGeneratedPhrase;
    if (passwordTypeArg)
        passwordType = mpw_typeWithName( passwordTypeArg );
    if (keyContextArg)
        keyContext = strdup( keyContextArg );

    // Summarize operation.
    const char *identicon = mpw_identicon( fullName, masterPassword );
    if (!identicon)
        wrn( "Couldn't determine identicon.\n" );
    dbg( "-----------------\n" );
    dbg( "fullName         : %s\n", fullName );
    trc( "masterPassword   : %s\n", masterPassword );
    dbg( "identicon        : %s\n", identicon );
    dbg( "siteName         : %s\n", siteName );
    dbg( "siteCounter      : %u\n", siteCounter );
    dbg( "keyPurpose       : %s (%u)\n", mpw_nameForPurpose( keyPurpose ), keyPurpose );
    dbg( "keyContext       : %s\n", keyContext );
    dbg( "passwordType     : %s (%u)\n", mpw_nameForType( passwordType ), passwordType );
    dbg( "algorithmVersion : %u\n", algorithmVersion );
    dbg( "-----------------\n\n" );
    inf( "%s's password for %s:\n[ %s ]: ", fullName, siteName, identicon );
    mpw_free_string( identicon );

    // Output the password.
    MPMasterKey masterKey = mpw_masterKey(
            fullName, masterPassword, algorithmVersion );
    mpw_free_string( masterPassword );
    mpw_free_string( fullName );
    if (!masterKey) {
        ftl( "Couldn't derive master key." );
        abort();
    }

    MPSiteKey siteKey = mpw_siteKey( masterKey, siteName, siteCounter, keyPurpose, keyContext, algorithmVersion );
    const char *sitePassword = mpw_sitePassword( siteKey, passwordType, algorithmVersion );
    mpw_free( masterKey, MPMasterKeySize );
    mpw_free( siteKey, MPSiteKeySize );
    mpw_free_string( siteName );
    mpw_free_string( keyContext );
    if (!sitePassword) {
        ftl( "Couldn't derive site password." );
        abort();
    }

    fprintf( stdout, "%s\n", sitePassword );
    mpw_free_string( sitePassword );

    return 0;
}
