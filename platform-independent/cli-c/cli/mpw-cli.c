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

#define MP_env_fullName     "MP_FULLNAME"
#define MP_env_algorithm    "MP_ALGORITHM"

static void usage() {

    inf( ""
            "Usage:\n"
            "  mpw [-u|-U full-name] [-t pw-type] [-c counter] [-a algorithm] [-s value]\n"
            "      [-p purpose] [-C context] [-f|-F format] [-R 0|1] [-v|-q] [-h] site-name\n\n" );
    inf( ""
            "  -u full-name Specify the full name of the user.\n"
            "               -u checks the master password against the config,\n"
            "               -U allows updating to a new master password.\n"
            "               Defaults to %s in env or prompts.\n\n", MP_env_fullName );
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
            "                   P, personal | saved personal password (see -s).\n\n" );
    inf( ""
            "  -c counter   The value of the counter.\n"
            "               Defaults to 1.\n\n" );
    inf( ""
            "  -a version   The algorithm version to use, %d - %d.\n"
            "               Defaults to %s in env or %d.\n\n",
            MPAlgorithmVersionFirst, MPAlgorithmVersionLast, MP_env_algorithm, MPAlgorithmVersionCurrent );
    inf( ""
            "  -s value     The value to save for -t P or -p i.\n\n" );
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
            "               Defaults to json, falls back to plain.\n"
            "                   f, flat     | ~/.mpw.d/Full Name.%s\n"
            "                   j, json     | ~/.mpw.d/Full Name.%s\n\n",
            mpw_marshall_format_extension( MPMarshallFormatFlat ), mpw_marshall_format_extension( MPMarshallFormatJSON ) );
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
            MP_env_fullName, MP_env_algorithm );
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

    // Master Password defaults.
    const char *fullName = NULL, *masterPassword = NULL, *siteName = NULL, *saveValue = NULL, *keyContext = NULL;
    MPCounterValue siteCounter = MPCounterValueDefault;
    MPPasswordType passwordType = MPPasswordTypeDefault;
    MPKeyPurpose keyPurpose = MPKeyPurposeAuthentication;
    MPAlgorithmVersion algorithmVersion = MPAlgorithmVersionCurrent;
    MPMarshallFormat sitesFormat = MPMarshallFormatDefault;
    bool allowPasswordUpdate = false, sitesFormatFixed = false, sitesRedacted = true;

    // Read the environment.
    const char *fullNameArg = NULL, *masterPasswordArg = NULL, *siteNameArg = NULL;
    const char *passwordTypeArg = NULL, *siteCounterArg = NULL, *algorithmVersionArg = NULL, *saveValueArg = NULL;
    const char *keyPurposeArg = NULL, *keyContextArg = NULL, *sitesFormatArg = NULL, *sitesRedactedArg = NULL;
    fullNameArg = mpw_getenv( MP_env_fullName );
    algorithmVersionArg = mpw_getenv( MP_env_algorithm );

    // Read the command-line options.
    for (int opt; (opt = getopt( argc, argv, "u:U:P:t:c:a:s:p:C:f:F:R:vqh" )) != EOF;)
        switch (opt) {
            case 'u':
                fullNameArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                allowPasswordUpdate = false;
                break;
            case 'U':
                fullNameArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                allowPasswordUpdate = true;
                break;
            case 'P':
                // Passing your master password via the command-line is insecure.  Testing purposes only.
                masterPasswordArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 't':
                passwordTypeArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'c':
                siteCounterArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 'a':
                algorithmVersionArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
                break;
            case 's':
                saveValueArg = optarg && strlen( optarg )? strdup( optarg ): NULL;
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
    if (!(siteNameArg && (siteName = strdup( siteNameArg ))) &&
        !(siteName = mpw_getline( "Site name:" ))) {
        ftl( "Missing site name.\n" );
        return EX_DATAERR;
    }
    if (!(masterPasswordArg && (masterPassword = strdup( masterPasswordArg ))))
        while (!masterPassword || !strlen( masterPassword ))
            masterPassword = mpw_getpass( "Your master password: " );
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
        free( sitesPath );

        // Try to fall back to the flat format.
        if (!sitesFormatFixed) {
            sitesFormat = MPMarshallFormatFlat;
            sitesPath = mpw_path( fullName, mpw_marshall_format_extension( sitesFormat ) );
            if (!sitesPath || !(sitesFile = fopen( sitesPath, "r" )))
                dbg( "Couldn't open configuration file:\n  %s: %s\n", sitesPath, strerror( errno ) );
        }
    }

    // Read the user's sites file.
    MPMarshalledUser *user = NULL;
    MPMarshalledSite *site = NULL;
    if (!sitesFile) {
        free( sitesPath );
        sitesPath = NULL;
    }
    else {
        // Read file.
        size_t readAmount = 4096, bufSize = 0, bufOffset = 0, readSize = 0;
        char *buf = NULL;
        while ((mpw_realloc( &buf, &bufSize, readAmount )) &&
               (bufOffset += (readSize = fread( buf + bufOffset, 1, readAmount, sitesFile ))) &&
               (readSize == readAmount));
        if (ferror( sitesFile ))
            wrn( "Error while reading configuration file:\n  %s: %d\n", sitesPath, ferror( sitesFile ) );
        fclose( sitesFile );

        // Parse file.
        MPMarshallError marshallError = { MPMarshallSuccess };
        user = mpw_marshall_read( buf, sitesFormat, masterPassword, &marshallError );
        if (marshallError.type == MPMarshallErrorMasterPassword) {
            // Incorrect master password.
            if (!allowPasswordUpdate) {
                ftl( "Incorrect master password according to configuration:\n  %s: %s\n", sitesPath, marshallError.description );
                mpw_marshal_free( user );
                mpw_free( buf, bufSize );
                free( sitesPath );
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
                user = mpw_marshall_read( buf, sitesFormat, importMasterPassword, &marshallError );
            }
            if (user) {
                mpw_free_string( user->masterPassword );
                user->masterPassword = strdup( masterPassword );
            }
        }
        mpw_free( buf, bufSize );
        if (!user || marshallError.type != MPMarshallSuccess) {
            err( "Couldn't parse configuration file:\n  %s: %s\n", sitesPath, marshallError.description );
            mpw_marshal_free( user );
            user = NULL;
            free( sitesPath );
            sitesPath = NULL;
        }

        if (user) {
            // Load defaults.
            mpw_free_string( fullName );
            mpw_free_string( masterPassword );
            fullName = strdup( user->fullName );
            masterPassword = strdup( user->masterPassword );
            algorithmVersion = user->algorithm;
            passwordType = user->defaultType;
            sitesRedacted = user->redacted;

            if (!sitesRedacted && !sitesRedactedArg)
                wrn( "Sites configuration is not redacted.  Use -R 1 to change this.\n" );

            for (size_t s = 0; s < user->sites_count; ++s) {
                site = &user->sites[s];
                if (strcmp( siteName, site->name ) != 0) {
                    site = NULL;
                    continue;
                }

                mpw_free_string( saveValue );
                passwordType = site->type;
                siteCounter = site->counter;
                algorithmVersion = site->algorithm;
                break;
            }
        }
    }

    // Parse default/config-overriding command-line parameters.
    if (sitesRedactedArg)
        sitesRedacted = strcmp( sitesRedactedArg, "1" ) == 0;
    if (siteCounterArg) {
        long long int siteCounterInt = atoll( siteCounterArg );
        if (siteCounterInt < MPCounterValueFirst || siteCounterInt > MPCounterValueLast) {
            ftl( "Invalid site counter: %s\n", siteCounterArg );
            return EX_USAGE;
        }
        siteCounter = (MPCounterValue)siteCounterInt;
    }
    if (algorithmVersionArg) {
        int algorithmVersionInt = atoi( algorithmVersionArg );
        if (algorithmVersionInt < MPAlgorithmVersionFirst || algorithmVersionInt > MPAlgorithmVersionLast) {
            ftl( "Invalid algorithm version: %s\n", algorithmVersionArg );
            return EX_USAGE;
        }
        algorithmVersion = (MPAlgorithmVersion)algorithmVersionInt;
    }
    if (saveValueArg) {
        mpw_free_string( saveValue );
        saveValue = strdup( saveValueArg );
    }
    if (keyPurposeArg) {
        keyPurpose = mpw_purposeWithName( keyPurposeArg );
        if (ERR == (int)keyPurpose) {
            ftl( "Invalid purpose: %s\n", keyPurposeArg );
            return EX_USAGE;
        }
    }
    char *purposeResult = "password";
    switch (keyPurpose) {
        case MPKeyPurposeAuthentication:
            break;
        case MPKeyPurposeIdentification: {
            passwordType = MPPasswordTypeGeneratedName;
            purposeResult = "login";
            break;
        }
        case MPKeyPurposeRecovery: {
            passwordType = MPPasswordTypeGeneratedPhrase;
            purposeResult = "answer";
            break;
        }
    }
    if (passwordTypeArg) {
        passwordType = mpw_typeWithName( passwordTypeArg );
        if (ERR == (int)passwordType) {
            ftl( "Invalid type: %s\n", passwordTypeArg );
            return EX_USAGE;
        }
    }
    if (keyContextArg) {
        mpw_free_string( keyContext );
        keyContext = strdup( keyContextArg );
    }
    mpw_free_string( fullNameArg );
    mpw_free_string( masterPasswordArg );
    mpw_free_string( siteNameArg );
    mpw_free_string( passwordTypeArg );
    mpw_free_string( siteCounterArg );
    mpw_free_string( algorithmVersionArg );
    mpw_free_string( saveValueArg );
    mpw_free_string( keyPurposeArg );
    mpw_free_string( keyContextArg );
    mpw_free_string( sitesFormatArg );
    mpw_free_string( sitesRedactedArg );

    // Operation summary.
    const char *identicon = mpw_identicon( fullName, masterPassword );
    if (!identicon)
        wrn( "Couldn't determine identicon.\n" );
    dbg( "-----------------\n" );
    dbg( "fullName         : %s\n", fullName );
    trc( "masterPassword   : %s\n", masterPassword );
    dbg( "identicon        : %s\n", identicon );
    dbg( "sitesFormat      : %s%s\n", mpw_nameForFormat( sitesFormat ), sitesFormatFixed? " (fixed)": "" );
    dbg( "sitesPath        : %s\n", sitesPath );
    dbg( "siteName         : %s\n", siteName );
    dbg( "siteCounter      : %u\n", siteCounter );
    dbg( "saveValue        : %s\n", saveValue );
    dbg( "keyPurpose       : %s (%u)\n", mpw_nameForPurpose( keyPurpose ), keyPurpose );
    dbg( "keyContext       : %s\n", keyContext );
    dbg( "passwordType     : %s (%u)\n", mpw_nameForType( passwordType ), passwordType );
    dbg( "algorithmVersion : %u\n", algorithmVersion );
    dbg( "-----------------\n\n" );
    inf( "%s's %s for %s:\n[ %s ]: ", fullName, purposeResult, siteName, identicon );
    mpw_free_string( identicon );
    if (sitesPath)
        free( sitesPath );

    // Determine master key.
    MPMasterKey masterKey = mpw_masterKey(
            fullName, masterPassword, algorithmVersion );
    mpw_free_string( masterPassword );
    mpw_free_string( fullName );
    if (!masterKey) {
        ftl( "Couldn't derive master key.\n" );
        return EX_SOFTWARE;
    }

    // Output the result.
    if (keyPurpose == MPKeyPurposeIdentification && site && !site->loginGenerated && site->loginName)
        fprintf( stdout, "%s\n", site->loginName );

    else if (passwordType & MPPasswordTypeClassGenerated) {
        MPSiteKey siteKey = mpw_siteKey( masterKey, siteName, siteCounter, keyPurpose, keyContext, algorithmVersion );
        const char *sitePassword = mpw_sitePassword( siteKey, passwordType, algorithmVersion );
        mpw_free( siteKey, MPSiteKeySize );
        if (!sitePassword) {
            ftl( "Couldn't derive site password.\n" );
            mpw_free( masterKey, MPMasterKeySize );
            return EX_SOFTWARE;
        }

        fprintf( stdout, "%s\n", sitePassword );
        mpw_free_string( sitePassword );
    }

    else {
        const char *content = NULL;
        if (saveValue) {
            content = strdup( saveValue );
            if (site) {
                // TODO: Doesn't save content for newly created sites.
                mpw_free_string( site->content );
                if (!(site->content = mpw_encrypt( masterKey, saveValue, algorithmVersion )))
                    err( "Couldn't encrypt site content.\n" );
            }
        }

        else if (site && site->content) {
            content = mpw_decrypt( masterKey, site->content, algorithmVersion );
            if (!content) {
                ftl( "Couldn't decrypt site content.\n" );
                mpw_free( masterKey, MPMasterKeySize );
                return EX_SOFTWARE;
            }
        }

        fprintf( stdout, "%s\n", content );
        mpw_free_string( content );
    }

    if (site && site->url)
        inf( "See: %s\n", site->url );
    mpw_free( masterKey, MPMasterKeySize );
    mpw_free_string( siteName );
    mpw_free_string( saveValue );
    mpw_free_string( keyContext );

    // Update the mpsites file.
    if (user) {
        // TODO: Move this up above the summary and replace the mpw lvars by user/site accessors.
        if (keyPurpose == MPKeyPurposeAuthentication) {
            if (!site)
                site = mpw_marshall_site( user, siteName, passwordType, siteCounter, algorithmVersion );
            else {
                site->type = passwordType;
                site->counter = siteCounter;
                site->algorithm = algorithmVersion;
            }
        }
        else if (keyPurpose == MPKeyPurposeIdentification && site) {
            // TODO: We're not persisting the passwordType of the generated login
            if (passwordType & MPPasswordTypeClassGenerated)
                site->loginGenerated = true;
        }
        else if (keyPurpose == MPKeyPurposeRecovery && site && keyContext) {
            // TODO: We're not persisting the passwordType of the recovery question
            MPMarshalledQuestion *question = NULL;
            for (size_t q = 0; q < site->questions_count; ++q) {
                question = &site->questions[q];
                if (strcmp( keyContext, question->keyword ) != 0) {
                    question = NULL;
                    continue;
                }
                break;
            }
            if (!question)
                mpw_marshal_question( site, keyContext );
        }
        if (site) {
            site->lastUsed = user->lastUsed = time( NULL );
            site->uses++;
        }

        if (!sitesFormatFixed)
            sitesFormat = MPMarshallFormatDefault;
        user->redacted = sitesRedacted;

        sitesPath = mpw_path( user->fullName, mpw_marshall_format_extension( sitesFormat ) );
        dbg( "Updating: %s (%s)\n", sitesPath, mpw_nameForFormat( sitesFormat ) );
        if (!sitesPath || !(sitesFile = fopen( sitesPath, "w" )))
            wrn( "Couldn't create updated configuration file:\n  %s: %s\n", sitesPath, strerror( errno ) );

        else {
            char *buf = NULL;
            MPMarshallError marshallError = { MPMarshallSuccess };
            if (!mpw_marshall_write( &buf, sitesFormat, user, &marshallError ) || marshallError.type != MPMarshallSuccess)
                wrn( "Couldn't encode updated configuration file:\n  %s: %s\n", sitesPath, marshallError.description );

            else if (fwrite( buf, sizeof( char ), strlen( buf ), sitesFile ) != strlen( buf ))
                wrn( "Error while writing updated configuration file:\n  %s: %d\n", sitesPath, ferror( sitesFile ) );

            mpw_free_string( buf );
            fclose( sitesFile );
        }
        free( sitesPath );
        mpw_marshal_free( user );
    }

    return 0;
}
