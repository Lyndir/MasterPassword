#include <stdio.h>
#include <unistd.h>
#include <pwd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sysexits.h>

#if defined(READLINE)
#include <readline/readline.h>
#elif defined(EDITLINE)
#include <histedit.h>
#endif

#include "mpw-algorithm.h"
#include "mpw-util.h"
#include "mpw-marshall.h"

#ifndef MP_VERSION
#define MP_VERSION ?
#endif
#define MP_ENV_fullName     "MP_FULLNAME"
#define MP_ENV_algorithm    "MP_ALGORITHM"
#define MP_ENV_format       "MP_FORMAT"

static void usage() {

    inf( ""
            "  Master Password v%s\n"
            "    https://masterpasswordapp.com\n\n", stringify_def( MP_VERSION ) );
    inf( ""
            "Usage:\n"
            "  mpw [-u|-U full-name] [-t pw-type] [-c counter] [-a algorithm] [-s value]\n"
            "      [-p purpose] [-C context] [-f|-F format] [-R 0|1] [-v|-q] [-h] site-name\n\n" );
    inf( ""
            "  -u full-name Specify the full name of the user.\n"
            "               -u checks the master password against the config,\n"
            "               -U allows updating to a new master password.\n"
            "               Defaults to %s in env or prompts.\n\n", MP_ENV_fullName );
    trc( ""
            "  -M master-pw Specify the master password of the user.\n"
            "               This is not a safe method of passing the master password,\n"
            "               only use it for non-secret passwords, such as for tests.\n\n" );
    inf( ""
            "  -t pw-type   Specify the password's template.\n"
            "               Defaults to 'long' (-p a), 'name' (-p i) or 'phrase' (-p r).\n"
            "                   x, maximum  | 20 characters, contains symbols.\n"
            "                   l, long     | Copy-friendly, 14 characters, symbols.\n"
            "                   m, medium   | Copy-friendly, 8 characters, symbols.\n"
            "                   b, basic    | 8 characters, no symbols.\n"
            "                   s, short    | Copy-friendly, 4 characters, no symbols.\n"
            "                   i, pin      | 4 numbers.\n"
            "                   n, name     | 9 letter name.\n"
            "                   p, phrase   | 20 character sentence.\n"
            "                   K, key      | encryption key (set key size -s bits).\n"
            "                   P, personal | saved personal password (save with -s pw).\n\n" );
    inf( ""
            "  -P value     The parameter value.\n"
            "                   -p i        | The login name for the site.\n"
            "                   -t K        | The size of they key to generate, in bits (eg. 256).\n"
            "                   -t P        | The personal password to encrypt.\n\n" );
    inf( ""
            "  -c counter   The value of the counter.\n"
            "               Defaults to 1.\n\n" );
    inf( ""
            "  -a version   The algorithm version to use, %d - %d.\n"
            "               Defaults to %s in env or %d.\n\n",
            MPAlgorithmVersionFirst, MPAlgorithmVersionLast, MP_ENV_algorithm, MPAlgorithmVersionCurrent );
    inf( ""
            "  -p purpose   The purpose of the generated token.\n"
            "               Defaults to 'auth'.\n"
            "                   a, auth     | An authentication token such as a password.\n"
            "                   i, ident    | An identification token such as a username.\n"
            "                   r, rec      | A recovery token such as a security answer.\n\n" );
    inf( ""
            "  -C context   A purpose-specific context.\n"
            "               Defaults to empty.\n"
            "                   -p a        | -\n"
            "                   -p i        | -\n"
            "                   -p r        | Most significant word in security question.\n\n" );
    inf( ""
            "  -f|F format  The mpsites format to use for reading/writing site parameters.\n"
            "               -F forces the use of the given format,\n"
            "               -f allows fallback/migration.\n"
            "               Defaults to %s in env or json, falls back to plain.\n"
            "                   n, none     | No file\n"
            "                   f, flat     | ~/.mpw.d/Full Name.%s\n"
            "                   j, json     | ~/.mpw.d/Full Name.%s\n\n",
            MP_ENV_format, mpw_marshall_format_extension( MPMarshallFormatFlat ), mpw_marshall_format_extension( MPMarshallFormatJSON ) );
    inf( ""
            "  -R redacted  Whether to save the mpsites in redacted format or not.\n"
            "               Defaults to 1, redacted.\n\n" );
    inf( ""
            "  -v           Increase output verbosity (can be repeated).\n"
            "  -q           Decrease output verbosity (can be repeated).\n\n" );
    inf( ""
            "  ENVIRONMENT\n\n"
            "      %-14s | The full name of the user (see -u).\n"
            "      %-14s | The default algorithm version (see -a).\n\n",
            MP_ENV_fullName, MP_ENV_algorithm );
    exit( 0 );
}

static const char *mpw_getenv(const char *variableName) {

    char *envBuf = getenv( variableName );
    return envBuf? strdup( envBuf ): NULL;
}

static const char *mpw_getline(const char *prompt) {

    fprintf( stderr, "%s ", prompt );

    char *buf = NULL;
    size_t bufSize = 0;
    ssize_t lineSize = getline( &buf, &bufSize, stdin );
    if (lineSize <= 1) {
        free( buf );
        return NULL;
    }

    // Remove the newline.
    buf[lineSize - 1] = '\0';
    return buf;
}

static const char *mpw_getpass(const char *prompt) {

    char *passBuf = getpass( prompt );
    if (!passBuf)
        return NULL;

    char *buf = strdup( passBuf );
    bzero( passBuf, strlen( passBuf ) );
    return buf;
}

static char *mpw_path(const char *prefix, const char *extension) {

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

int main(int argc, char *const argv[]) {

    // CLI defaults.
    MPMarshallFormat sitesFormat = MPMarshallFormatDefault;
    const char *fullName = NULL, *masterPassword = NULL, *siteName = NULL;
    bool allowPasswordUpdate = false, sitesFormatFixed = false;

    // Read the environment.
    const char *fullNameArg = NULL, *masterPasswordArg = NULL, *siteNameArg = NULL;
    const char *resultTypeArg = NULL, *resultParamArg = NULL, *siteCounterArg = NULL, *algorithmVersionArg = NULL;
    const char *keyPurposeArg = NULL, *keyContextArg = NULL, *sitesFormatArg = NULL, *sitesRedactedArg = NULL;
    fullNameArg = mpw_getenv( MP_ENV_fullName );
    algorithmVersionArg = mpw_getenv( MP_ENV_algorithm );
    sitesFormatArg = mpw_getenv( MP_ENV_format );

    // Read the command-line options.
    for (int opt; (opt = getopt( argc, argv, "u:U:M:t:P:c:a:p:C:f:F:R:vqh" )) != EOF;)
        switch (opt) {
            case 'u':
                fullNameArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                allowPasswordUpdate = false;
                break;
            case 'U':
                fullNameArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                allowPasswordUpdate = true;
                break;
            case 'M':
                // Passing your master password via the command-line is insecure.  Testing purposes only.
                masterPasswordArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 't':
                resultTypeArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'P':
                resultParamArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'c':
                siteCounterArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'a':
                algorithmVersionArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'p':
                keyPurposeArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'C':
                keyContextArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'f':
                sitesFormatArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                sitesFormatFixed = false;
                break;
            case 'F':
                sitesFormatArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                sitesFormatFixed = true;
                break;
            case 'R':
                sitesRedactedArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
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
                        return EX_USAGE;
                    case 't':
                        ftl( "Missing type name to option: -%c\n", optopt );
                        return EX_USAGE;
                    case 'c':
                        ftl( "Missing counter value to option: -%c\n", optopt );
                        return EX_USAGE;
                    default:
                        ftl( "Unknown option: -%c\n", optopt );
                        return EX_USAGE;
                }
            default:
                ftl( "Unexpected option: %c\n", opt );
                return EX_USAGE;
        }
    if (optind < argc)
        siteNameArg = strdup( argv[optind] );

    // Determine fullName, siteName & masterPassword.
    if (!(fullNameArg && (fullName = strdup( fullNameArg ))) &&
        !(fullName = mpw_getline( "Your full name:" ))) {
        ftl( "Missing full name.\n" );
        return EX_DATAERR;
    }
    if (!(masterPasswordArg && (masterPassword = strdup( masterPasswordArg ))))
        while (!masterPassword || !strlen( masterPassword ))
            masterPassword = mpw_getpass( "Your master password: " );
    if (!(siteNameArg && (siteName = strdup( siteNameArg ))) &&
        !(siteName = mpw_getline( "Site name:" ))) {
        ftl( "Missing site name.\n" );
        return EX_DATAERR;
    }
    if (sitesFormatArg) {
        sitesFormat = mpw_formatWithName( sitesFormatArg );
        if (ERR == (int)sitesFormat) {
            ftl( "Invalid sites format: %s\n", sitesFormatArg );
            return EX_USAGE;
        }
    }

    // Find the user's sites file.
    FILE *sitesFile = NULL;
    char *sitesPath = mpw_path( fullName, mpw_marshall_format_extension( sitesFormat ) );
    if (!sitesPath || !(sitesFile = fopen( sitesPath, "r" ))) {
        dbg( "Couldn't open configuration file:\n  %s: %s\n", sitesPath, strerror( errno ) );

        // Try to fall back to the flat format.
        if (!sitesFormatFixed) {
            mpw_free_string( sitesPath );
            sitesPath = mpw_path( fullName, mpw_marshall_format_extension( MPMarshallFormatFlat ) );
            if (sitesPath && (sitesFile = fopen( sitesPath, "r" )))
                sitesFormat = MPMarshallFormatFlat;
            else
                dbg( "Couldn't open configuration file:\n  %s: %s\n", sitesPath, strerror( errno ) );
        }
    }

    // Load the user object from file.
    MPMarshalledUser *user = NULL;
    MPMarshalledSite *site = NULL;
    MPMarshalledQuestion *question = NULL;
    if (!sitesFile) {
        mpw_free_string( sitesPath );
        sitesPath = NULL;
    }
    else {
        // Read file.
        size_t blockSize = 4096, bufSize = 0, bufOffset = 0, readSize = 0;
        char *sitesInputData = NULL;
        while ((mpw_realloc( &sitesInputData, &bufSize, blockSize )) &&
               (bufOffset += (readSize = fread( sitesInputData + bufOffset, 1, blockSize, sitesFile ))) &&
               (readSize == blockSize));
        if (ferror( sitesFile ))
            wrn( "Error while reading configuration file:\n  %s: %d\n", sitesPath, ferror( sitesFile ) );
        fclose( sitesFile );

        // Parse file.
        MPMarshallInfo *sitesInputInfo = mpw_marshall_read_info( sitesInputData );
        MPMarshallFormat sitesInputFormat = sitesFormatArg? sitesFormat: sitesInputInfo->format;
        MPMarshallError marshallError = { .type = MPMarshallSuccess };
        mpw_marshal_info_free( sitesInputInfo );
        user = mpw_marshall_read( sitesInputData, sitesInputFormat, masterPassword, &marshallError );
        if (marshallError.type == MPMarshallErrorMasterPassword) {
            // Incorrect master password.
            if (!allowPasswordUpdate) {
                ftl( "Incorrect master password according to configuration:\n  %s: %s\n", sitesPath, marshallError.description );
                mpw_marshal_free( user );
                mpw_free( sitesInputData, bufSize );
                mpw_free_string( sitesPath );
                return EX_DATAERR;
            }

            // Update user's master password.
            while (marshallError.type == MPMarshallErrorMasterPassword) {
                inf( "Given master password does not match configuration.\n" );
                inf( "To update the configuration with this new master password, first confirm the old master password.\n" );

                const char *importMasterPassword = NULL;
                while (!importMasterPassword || !strlen( importMasterPassword ))
                    importMasterPassword = mpw_getpass( "Old master password: " );

                mpw_marshal_free( user );
                user = mpw_marshall_read( sitesInputData, sitesInputFormat, importMasterPassword, &marshallError );
                mpw_free_string( importMasterPassword );
            }
            if (user) {
                mpw_free_string( user->masterPassword );
                user->masterPassword = strdup( masterPassword );
            }
        }
        mpw_free( sitesInputData, bufSize );
        if (!user || marshallError.type != MPMarshallSuccess) {
            err( "Couldn't parse configuration file:\n  %s: %s\n", sitesPath, marshallError.description );
            mpw_marshal_free( user );
            user = NULL;
            mpw_free_string( sitesPath );
            sitesPath = NULL;
        }
    }
    if (!user)
        user = mpw_marshall_user( fullName, masterPassword, MPAlgorithmVersionCurrent );
    mpw_free_string( fullName );
    mpw_free_string( masterPassword );

    // Load the site object.
    for (size_t s = 0; s < user->sites_count; ++s) {
        site = &user->sites[s];
        if (strcmp( siteName, site->name ) != 0) {
            site = NULL;
            continue;
        }
        break;
    }
    if (!site)
        site = mpw_marshall_site( user, siteName, MPResultTypeDefault, MPCounterValueDefault, user->algorithm );
    mpw_free_string( siteName );

    // Load the purpose and context / question object.
    MPKeyPurpose keyPurpose = MPKeyPurposeAuthentication;
    if (keyPurposeArg) {
        keyPurpose = mpw_purposeWithName( keyPurposeArg );
        if (ERR == (int)keyPurpose) {
            ftl( "Invalid purpose: %s\n", keyPurposeArg );
            return EX_USAGE;
        }
    }
    const char *keyContext = NULL;
    if (keyContextArg) {
        keyContext = strdup( keyContextArg );

        switch (keyPurpose) {
            case MPKeyPurposeAuthentication:
                // NOTE: keyContext is not persisted.
                break;
            case MPKeyPurposeIdentification:
                // NOTE: keyContext is not persisted.
                break;
            case MPKeyPurposeRecovery:
                for (size_t q = 0; q < site->questions_count; ++q) {
                    question = &site->questions[q];
                    if (strcmp( keyContext, question->keyword ) != 0) {
                        question = NULL;
                        continue;
                    }
                    break;
                }
                break;
        }
    }
    if (!question)
        question = mpw_marshal_question( site, keyContext );

    // Initialize purpose-specific operation parameters.
    MPResultType resultType = MPResultTypeDefault;
    MPCounterValue siteCounter = MPCounterValueDefault;
    const char *purposeResult = NULL, *resultState = NULL;
    switch (keyPurpose) {
        case MPKeyPurposeAuthentication: {
            purposeResult = "password";
            resultType = site->type;
            resultState = strdup( site->content );
            siteCounter = site->counter;
            break;
        }
        case MPKeyPurposeIdentification: {
            purposeResult = "login";
            resultType = site->loginType;
            resultState = strdup( site->loginContent );
            siteCounter = MPCounterValueInitial;
            break;
        }
        case MPKeyPurposeRecovery: {
            mpw_free_string( keyContext );
            purposeResult = "answer";
            keyContext = strdup( question->keyword );
            resultType = question->type;
            resultState = strdup( question->content );
            siteCounter = MPCounterValueInitial;
            break;
        }
    }

    // Override operation parameters from command-line arguments.
    if (resultTypeArg) {
        resultType = mpw_typeWithName( resultTypeArg );
        if (ERR == (int)resultType) {
            ftl( "Invalid type: %s\n", resultTypeArg );
            return EX_USAGE;
        }

        if (!(resultType & MPSiteFeatureAlternative)) {
            switch (keyPurpose) {
                case MPKeyPurposeAuthentication:
                    site->type = resultType;
                    break;
                case MPKeyPurposeIdentification:
                    site->loginType = resultType;
                    break;
                case MPKeyPurposeRecovery:
                    question->type = resultType;
                    break;
            }
        }
    }
    if (siteCounterArg) {
        long long int siteCounterInt = atoll( siteCounterArg );
        if (siteCounterInt < MPCounterValueFirst || siteCounterInt > MPCounterValueLast) {
            ftl( "Invalid site counter: %s\n", siteCounterArg );
            return EX_USAGE;
        }

        switch (keyPurpose) {
            case MPKeyPurposeAuthentication:
                siteCounter = site->counter = (MPCounterValue)siteCounterInt;
                break;
            case MPKeyPurposeIdentification:
            case MPKeyPurposeRecovery:
                // NOTE: counter for login & question is not persisted.
                break;
        }
    }
    const char *resultParam = NULL;
    if (resultParamArg)
        resultParam = strdup( resultParamArg );
    if (algorithmVersionArg) {
        int algorithmVersionInt = atoi( algorithmVersionArg );
        if (algorithmVersionInt < MPAlgorithmVersionFirst || algorithmVersionInt > MPAlgorithmVersionLast) {
            ftl( "Invalid algorithm version: %s\n", algorithmVersionArg );
            return EX_USAGE;
        }
        site->algorithm = (MPAlgorithmVersion)algorithmVersionInt;
    }
    if (sitesRedactedArg)
        user->redacted = strcmp( sitesRedactedArg, "1" ) == 0;
    else if (!user->redacted)
        wrn( "Sites configuration is not redacted.  Use -R 1 to change this.\n" );
    mpw_free_string( fullNameArg );
    mpw_free_string( masterPasswordArg );
    mpw_free_string( siteNameArg );
    mpw_free_string( resultTypeArg );
    mpw_free_string( resultParamArg );
    mpw_free_string( siteCounterArg );
    mpw_free_string( algorithmVersionArg );
    mpw_free_string( keyPurposeArg );
    mpw_free_string( keyContextArg );
    mpw_free_string( sitesFormatArg );
    mpw_free_string( sitesRedactedArg );

    // Operation summary.
    const char *identicon = mpw_identicon( user->fullName, user->masterPassword );
    if (!identicon)
        wrn( "Couldn't determine identicon.\n" );
    dbg( "-----------------\n" );
    dbg( "fullName         : %s\n", user->fullName );
    trc( "masterPassword   : %s\n", user->masterPassword );
    dbg( "identicon        : %s\n", identicon );
    dbg( "sitesFormat      : %s%s\n", mpw_nameForFormat( sitesFormat ), sitesFormatFixed? " (fixed)": "" );
    dbg( "sitesPath        : %s\n", sitesPath );
    dbg( "siteName         : %s\n", site->name );
    dbg( "siteCounter      : %u\n", siteCounter );
    dbg( "resultType       : %s (%u)\n", mpw_nameForType( resultType ), resultType );
    dbg( "resultParam      : %s\n", resultParam );
    dbg( "keyPurpose       : %s (%u)\n", mpw_nameForPurpose( keyPurpose ), keyPurpose );
    dbg( "keyContext       : %s\n", keyContext );
    dbg( "algorithmVersion : %u\n", site->algorithm );
    dbg( "-----------------\n\n" );
    inf( "%s's %s for %s:\n[ %s ]: ", user->fullName, purposeResult, site->name, identicon );
    mpw_free_string( identicon );
    if (sitesPath)
        mpw_free_string( sitesPath );

    // Determine master key.
    MPMasterKey masterKey = mpw_masterKey(
            user->fullName, user->masterPassword, site->algorithm );
    if (!masterKey) {
        ftl( "Couldn't derive master key.\n" );
        return EX_SOFTWARE;
    }

    // Update state.
    if (resultParam && resultType & MPResultTypeClassStateful) {
        if (!(resultState = mpw_siteState( masterKey, site->name, siteCounter,
                keyPurpose, keyContext, resultType, resultParam, site->algorithm ))) {
            ftl( "Couldn't encrypt site result.\n" );
            mpw_free( masterKey, MPMasterKeySize );
            return EX_SOFTWARE;
        }
        inf( "(state) %s => ", resultState );

        switch (keyPurpose) {
            case MPKeyPurposeAuthentication: {
                mpw_free_string( site->content );
                site->content = resultState;
                break;
            }
            case MPKeyPurposeIdentification: {
                mpw_free_string( site->loginContent );
                site->loginContent = resultState;
                break;
            }

            case MPKeyPurposeRecovery: {
                mpw_free_string( question->content );
                question->content = resultState;
                break;
            }
        }

        // resultParam is consumed.
        mpw_free_string( resultParam );
        resultParam = NULL;
    }

    // Second phase resultParam defaults to state.
    if (!resultParam && resultState)
        resultParam = strdup( resultState );
    mpw_free_string( resultState );

    // Generate result.
    const char *result = mpw_siteResult( masterKey, site->name, siteCounter,
            keyPurpose, keyContext, resultType, resultParam, site->algorithm );
    if (!result) {
        ftl( "Couldn't generate site result.\n" );
        return EX_SOFTWARE;
    }
    fprintf( stdout, "%s\n", result );
    if (site->url)
        inf( "See: %s\n", site->url );
    mpw_free( masterKey, MPMasterKeySize );
    mpw_free_string( keyContext );
    mpw_free_string( resultParam );
    mpw_free_string( result );

    // Update usage metadata.
    site->lastUsed = user->lastUsed = time( NULL );
    site->uses++;

    // Update the mpsites file.
    if (sitesFormat != MPMarshallFormatNone) {
        if (!sitesFormatFixed)
            sitesFormat = MPMarshallFormatDefault;
        sitesPath = mpw_path( user->fullName, mpw_marshall_format_extension( sitesFormat ) );

        dbg( "Updating: %s (%s)\n", sitesPath, mpw_nameForFormat( sitesFormat ) );
        if (!sitesPath || !(sitesFile = fopen( sitesPath, "w" )))
            wrn( "Couldn't create updated configuration file:\n  %s: %s\n", sitesPath, strerror( errno ) );

        else {
            char *buf = NULL;
            MPMarshallError marshallError = { .type = MPMarshallSuccess };
            if (!mpw_marshall_write( &buf, sitesFormat, user, &marshallError ) || marshallError.type != MPMarshallSuccess)
                wrn( "Couldn't encode updated configuration file:\n  %s: %s\n", sitesPath, marshallError.description );

            else if (fwrite( buf, sizeof( char ), strlen( buf ), sitesFile ) != strlen( buf ))
                wrn( "Error while writing updated configuration file:\n  %s: %d\n", sitesPath, ferror( sitesFile ) );

            mpw_free_string( buf );
            fclose( sitesFile );
        }
        mpw_free_string( sitesPath );
    }
    mpw_marshal_free( user );

    return 0;
}
