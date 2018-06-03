//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#define _POSIX_C_SOURCE 200809L

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sysexits.h>

#include "mpw-cli-util.h"
#include "mpw-algorithm.h"
#include "mpw-util.h"
#include "mpw-marshal.h"

/** Output the program's usage documentation. */
static void usage() {

    inf( ""
            "  Master Password v%s - CLI\n"
            "--------------------------------------------------------------------------------\n"
            "      https://masterpassword.app\n", stringify_def( MP_VERSION ) );
    inf( ""
            "\nUSAGE\n\n"
            "  mpw [-u|-U full-name] [-m fd] [-t pw-type] [-P value] [-c counter]\n"
            "      [-a version] [-p purpose] [-C context] [-f|F format] [-R 0|1]\n"
            "      [-v|-q]* [-h] [site-name]\n" );
    inf( ""
            "  -u full-name Specify the full name of the user.\n"
            "               -u checks the master password against the config,\n"
            "               -U allows updating to a new master password.\n"
            "               Defaults to %s in env or prompts.\n", MP_ENV_fullName );
    dbg( ""
            "  -M master-pw Specify the master password of the user.\n"
            "               Passing secrets as arguments is unsafe, for use in testing only." );
    inf( ""
            "  -m fd        Read the master password of the user from a file descriptor.\n"
            "               Tip: don't send extra characters like newlines such as by using\n"
            "               echo in a pipe.  Consider printf instead.\n" );
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
            "                   K, key      | encryption key (512 bit or -P bits).\n"
            "                   P, personal | saved personal password (save with -P pw).\n" );
    inf( ""
            "  -P value     The parameter value.\n"
            "                   -p i        | The login name for the site.\n"
            "                   -t K        | The bit size of the key to generate (eg. 256).\n"
            "                   -t P        | The personal password to encrypt.\n" );
    inf( ""
            "  -c counter   The value of the counter.\n"
            "               Defaults to 1.\n" );
    inf( ""
            "  -a version   The algorithm version to use, %d - %d.\n"
            "               Defaults to env var %s or %d.\n",
            MPAlgorithmVersionFirst, MPAlgorithmVersionLast, MP_ENV_algorithm, MPAlgorithmVersionCurrent );
    inf( ""
            "  -p purpose   The purpose of the generated token.\n"
            "               Defaults to 'auth'.\n"
            "                   a, auth     | An authentication token such as a password.\n"
            "                   i, ident    | An identification token such as a username.\n"
            "                   r, rec      | A recovery token such as a security answer.\n" );
    inf( ""
            "  -C context   A purpose-specific context.\n"
            "               Defaults to empty.\n"
            "                   -p a        | -\n"
            "                   -p i        | -\n"
            "                   -p r        | Most significant word in security question.\n" );
    inf( ""
            "  -f|F format  The mpsites format to use for reading/writing site parameters.\n"
            "               -F forces the use of the given format,\n"
            "               -f allows fallback/migration.\n"
            "               Defaults to env var %s or json, falls back to plain.\n"
            "                   n, none     | No file\n"
            "                   f, flat     | ~/.mpw.d/Full Name.%s\n"
            "                   j, json     | ~/.mpw.d/Full Name.%s\n",
            MP_ENV_format, mpw_marshal_format_extension( MPMarshalFormatFlat ), mpw_marshal_format_extension( MPMarshalFormatJSON ) );
    inf( ""
            "  -R redacted  Whether to save the mpsites in redacted format or not.\n"
            "               Redaction omits or encrypts any secrets, making the file safe\n"
            "               for saving on or transmitting via untrusted media.\n"
            "               Defaults to 1, redacted.\n" );
    inf( ""
            "  -v           Increase output verbosity (can be repeated).\n"
            "  -q           Decrease output verbosity (can be repeated).\n" );
    inf( ""
            "  -h           Show this help output instead of performing any operation.\n" );
    inf( ""
            "  site-name    Name of the site for which to generate a token.\n" );
    inf( ""
            "\nENVIRONMENT\n\n"
            "  %-12s The full name of the user (see -u).\n"
            "  %-12s The default algorithm version (see -a).\n"
            "  %-12s The default mpsites format (see -f).\n"
            "  %-12s The askpass program to use for prompting the user.\n",
            MP_ENV_fullName, MP_ENV_algorithm, MP_ENV_format, MP_ENV_askpass );
    exit( EX_OK );
}

// Internal state.

typedef struct {
    const char *fullName;
    const char *masterPasswordFD;
    const char *masterPassword;
    const char *siteName;
    const char *resultType;
    const char *resultParam;
    const char *siteCounter;
    const char *algorithmVersion;
    const char *keyPurpose;
    const char *keyContext;
    const char *sitesFormat;
    const char *sitesRedacted;
} Arguments;

typedef struct {
    bool allowPasswordUpdate;
    bool sitesFormatFixed;
    const char *fullName;
    const char *masterPassword;
    const char *identicon;
    const char *siteName;
    MPMarshalFormat sitesFormat;
    MPKeyPurpose keyPurpose;
    const char *keyContext;
    const char *sitesPath;
    MPResultType resultType;
    MPCounterValue siteCounter;
    const char *purposeResult;
    const char *resultState;
    const char *resultParam;
    MPMarshalledUser *user;
    MPMarshalledSite *site;
    MPMarshalledQuestion *question;
} Operation;

// Processing steps.

void cli_free(Arguments *args, Operation *operation);
void cli_args(Arguments *args, Operation *operation, const int argc, char *const argv[]);
void cli_fullName(Arguments *args, Operation *operation);
void cli_masterPassword(Arguments *args, Operation *operation);
void cli_siteName(Arguments *args, Operation *operation);
void cli_sitesFormat(Arguments *args, Operation *operation);
void cli_keyPurpose(Arguments *args, Operation *operation);
void cli_keyContext(Arguments *args, Operation *operation);
void cli_user(Arguments *args, Operation *operation);
void cli_site(Arguments *args, Operation *operation);
void cli_question(Arguments *args, Operation *operation);
void cli_operation(Arguments *args, Operation *operation);
void cli_resultType(Arguments *args, Operation *operation);
void cli_siteCounter(Arguments *args, Operation *operation);
void cli_resultParam(Arguments *args, Operation *operation);
void cli_algorithmVersion(Arguments *args, Operation *operation);
void cli_sitesRedacted(Arguments *args, Operation *operation);
void cli_mpw(Arguments *args, Operation *operation);
void cli_save(Arguments *args, Operation *operation);

/** ========================================================================
 *  MAIN                                                                     */
int main(const int argc, char *const argv[]) {

    // Application defaults.
    Arguments args = {
            .fullName = mpw_getenv( MP_ENV_fullName ),
            .algorithmVersion = mpw_getenv( MP_ENV_algorithm ),
            .sitesFormat = mpw_getenv( MP_ENV_format ),
    };
    Operation operation = {
            .allowPasswordUpdate = false,
            .sitesFormatFixed = false,
            .sitesFormat = MPMarshalFormatDefault,
            .keyPurpose = MPKeyPurposeAuthentication,
            .resultType = MPResultTypeDefault,
            .siteCounter = MPCounterValueDefault,
    };

    // Read the command-line options.
    cli_args( &args, &operation, argc, argv );

    // Determine the operation parameters not sourced from mpsites.
    cli_fullName( &args, &operation );
    cli_masterPassword( &args, &operation );
    cli_siteName( &args, &operation );
    cli_sitesFormat( &args, &operation );
    cli_keyPurpose( &args, &operation );
    cli_keyContext( &args, &operation );

    // Load the operation parameters from mpsites.
    cli_user( &args, &operation );
    cli_site( &args, &operation );
    cli_question( &args, &operation );
    cli_operation( &args, &operation );

    // Override the operation parameters from command-line arguments.
    cli_resultType( &args, &operation );
    cli_siteCounter( &args, &operation );
    cli_resultParam( &args, &operation );
    cli_algorithmVersion( &args, &operation );
    cli_sitesRedacted( &args, &operation );
    cli_free( &args, NULL );

    // Operation summary.
    dbg( "-----------------" );
    if (operation.user) {
        dbg( "fullName         : %s", operation.user->fullName );
        trc( "masterPassword   : %s", operation.user->masterPassword );
        dbg( "identicon        : %s", operation.identicon );
        dbg( "sitesFormat      : %s%s", mpw_nameForFormat( operation.sitesFormat ), operation.sitesFormatFixed? " (fixed)": "" );
        dbg( "sitesPath        : %s", operation.sitesPath );
    }
    if (operation.site) {
        dbg( "siteName         : %s", operation.site->name );
        dbg( "siteCounter      : %u", operation.siteCounter );
        dbg( "resultType       : %s (%u)", mpw_nameForType( operation.resultType ), operation.resultType );
        dbg( "resultParam      : %s", operation.resultParam );
        dbg( "keyPurpose       : %s (%u)", mpw_nameForPurpose( operation.keyPurpose ), operation.keyPurpose );
        dbg( "keyContext       : %s", operation.keyContext );
        dbg( "algorithmVersion : %u", operation.site->algorithm );
    }
    dbg( "-----------------" );

    // Finally ready to perform the actual operation.
    cli_mpw( &args, &operation );

    // Save changes and clean up.
    cli_save( &args, &operation );
    cli_free( &args, &operation );

    return EX_OK;
}

void cli_free(Arguments *args, Operation *operation) {

    if (args) {
        mpw_free_strings( &args->fullName, &args->masterPasswordFD, &args->masterPassword, &args->siteName, NULL );
        mpw_free_strings( &args->resultType, &args->resultParam, &args->siteCounter, &args->algorithmVersion, NULL );
        mpw_free_strings( &args->keyPurpose, &args->keyContext, &args->sitesFormat, &args->sitesRedacted, NULL );
    }

    if (operation) {
        mpw_free_strings( &operation->fullName, &operation->masterPassword, &operation->siteName, NULL );
        mpw_free_strings( &operation->keyContext, &operation->resultState, &operation->resultParam, NULL );
        mpw_free_strings( &operation->identicon, &operation->sitesPath, NULL );
        mpw_marshal_free( &operation->user );
        operation->site = NULL;
        operation->question = NULL;
    }
}

void cli_args(Arguments *args, Operation *operation, const int argc, char *const argv[]) {

    for (int opt; (opt = getopt( argc, argv, "u:U:m:M:t:P:c:a:p:C:f:F:R:vqh" )) != EOF;
         optarg? mpw_zero( optarg, strlen( optarg ) ): (void)0)
        switch (opt) {
            case 'u':
                args->fullName = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                operation->allowPasswordUpdate = false;
                break;
            case 'U':
                args->fullName = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                operation->allowPasswordUpdate = true;
                break;
            case 'm':
                args->masterPasswordFD = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'M':
                // Passing your master password via the command-line is insecure.  Testing purposes only.
                args->masterPassword = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 't':
                args->resultType = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'P':
                args->resultParam = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'c':
                args->siteCounter = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'a':
                args->algorithmVersion = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'p':
                args->keyPurpose = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'C':
                args->keyContext = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                break;
            case 'f':
                args->sitesFormat = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                operation->sitesFormatFixed = false;
                break;
            case 'F':
                args->sitesFormat = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
                operation->sitesFormatFixed = true;
                break;
            case 'R':
                args->sitesRedacted = optarg && strlen( optarg )? mpw_strdup( optarg ): NULL;
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
                        ftl( "Missing full name to option: -%c", optopt );
                        exit( EX_USAGE );
                    case 't':
                        ftl( "Missing type name to option: -%c", optopt );
                        exit( EX_USAGE );
                    case 'c':
                        ftl( "Missing counter value to option: -%c", optopt );
                        exit( EX_USAGE );
                    default:
                        ftl( "Unknown option: -%c", optopt );
                        exit( EX_USAGE );
                }
            default:
                ftl( "Unexpected option: %c", opt );
                exit( EX_USAGE );
        }

    if (optind < argc && argv[optind])
        args->siteName = mpw_strdup( argv[optind] );
}

void cli_fullName(Arguments *args, Operation *operation) {

    mpw_free_string( &operation->fullName );

    if (args->fullName)
        operation->fullName = mpw_strdup( args->fullName );

    if (!operation->fullName || !strlen( operation->fullName ))
        do {
            operation->fullName = mpw_getline( "Your full name:" );
        } while (operation->fullName && !strlen( operation->fullName ));

    if (!operation->fullName || !strlen( operation->fullName )) {
        ftl( "Missing full name." );
        cli_free( args, operation );
        exit( EX_DATAERR );
    }
}

void cli_masterPassword(Arguments *args, Operation *operation) {

    mpw_free_string( &operation->masterPassword );

    if (args->masterPasswordFD) {
        operation->masterPassword = mpw_read_fd( atoi( args->masterPasswordFD ) );
        if (!operation->masterPassword && errno)
            wrn( "Error reading master password from FD %s: %s", args->masterPasswordFD, strerror( errno ) );
    }

    if (args->masterPassword && !operation->masterPassword)
        operation->masterPassword = mpw_strdup( args->masterPassword );

    if (!operation->masterPassword || !strlen( operation->masterPassword ))
        do {
            operation->masterPassword = mpw_getpass( "Your master password: " );
        } while (operation->masterPassword && !strlen( operation->masterPassword ));

    if (!operation->masterPassword || !strlen( operation->masterPassword )) {
        ftl( "Missing master password." );
        cli_free( args, operation );
        exit( EX_DATAERR );
    }
}

void cli_siteName(Arguments *args, Operation *operation) {

    mpw_free_string( &operation->siteName );

    if (args->siteName)
        operation->siteName = mpw_strdup( args->siteName );
    if (!operation->siteName)
        operation->siteName = mpw_getline( "Site name:" );

    if (!operation->siteName) {
        ftl( "Missing site name." );
        cli_free( args, operation );
        exit( EX_DATAERR );
    }
}

void cli_sitesFormat(Arguments *args, Operation *operation) {

    if (!args->sitesFormat)
        return;

    operation->sitesFormat = mpw_formatWithName( args->sitesFormat );
    if (ERR == (int)operation->sitesFormat) {
        ftl( "Invalid sites format: %s", args->sitesFormat );
        cli_free( args, operation );
        exit( EX_DATAERR );
    }
}

void cli_keyPurpose(Arguments *args, Operation *operation) {

    if (!args->keyPurpose)
        return;

    operation->keyPurpose = mpw_purposeWithName( args->keyPurpose );
    if (ERR == (int)operation->keyPurpose) {
        ftl( "Invalid purpose: %s", args->keyPurpose );
        cli_free( args, operation );
        exit( EX_DATAERR );
    }
}

void cli_keyContext(Arguments *args, Operation *operation) {

    if (!args->keyContext)
        return;

    operation->keyContext = mpw_strdup( args->keyContext );
}

void cli_user(Arguments *args, Operation *operation) {

    // Find mpsites file from parameters.
    FILE *sitesFile = NULL;
    mpw_free_string( &operation->sitesPath );
    operation->sitesPath = mpw_path( operation->fullName, mpw_marshal_format_extension( operation->sitesFormat ) );
    if (!operation->sitesPath || !(sitesFile = fopen( operation->sitesPath, "r" ))) {
        dbg( "Couldn't open configuration file:\n  %s: %s", operation->sitesPath, strerror( errno ) );

        // Try to fall back to the flat format.
        if (!operation->sitesFormatFixed) {
            mpw_free_string( &operation->sitesPath );
            operation->sitesPath = mpw_path( operation->fullName, mpw_marshal_format_extension( MPMarshalFormatFlat ) );
            if (operation->sitesPath && (sitesFile = fopen( operation->sitesPath, "r" )))
                operation->sitesFormat = MPMarshalFormatFlat;
            else
                dbg( "Couldn't open configuration file:\n  %s: %s", operation->sitesPath, strerror( errno ) );
        }
    }

    // Load the user object from mpsites.
    if (!sitesFile)
        mpw_free_string( &operation->sitesPath );

    else {
        // Read file.
        char *sitesInputData = mpw_read_file( sitesFile );
        if (ferror( sitesFile ))
            wrn( "Error while reading configuration file:\n  %s: %d", operation->sitesPath, ferror( sitesFile ) );
        fclose( sitesFile );

        // Parse file.
        MPMarshalInfo *sitesInputInfo = mpw_marshal_read_info( sitesInputData );
        MPMarshalFormat sitesInputFormat = args->sitesFormat? operation->sitesFormat: sitesInputInfo->format;
        MPMarshalError marshalError = { .type = MPMarshalSuccess };
        mpw_marshal_info_free( &sitesInputInfo );
        mpw_marshal_free( &operation->user );
        operation->user = mpw_marshal_read( sitesInputData, sitesInputFormat, operation->masterPassword, &marshalError );
        if (marshalError.type == MPMarshalErrorMasterPassword && operation->allowPasswordUpdate) {
            // Update master password in mpsites.
            while (marshalError.type == MPMarshalErrorMasterPassword) {
                inf( "Given master password does not match configuration." );
                inf( "To update the configuration with this new master password, first confirm the old master password." );

                const char *importMasterPassword = NULL;
                while (!importMasterPassword || !strlen( importMasterPassword ))
                    importMasterPassword = mpw_getpass( "Old master password: " );

                mpw_marshal_free( &operation->user );
                operation->user = mpw_marshal_read( sitesInputData, sitesInputFormat, importMasterPassword, &marshalError );
                mpw_free_string( &importMasterPassword );
            }
            if (operation->user) {
                mpw_free_string( &operation->user->masterPassword );
                operation->user->masterPassword = mpw_strdup( operation->masterPassword );
            }
        }
        mpw_free_string( &sitesInputData );

        // Incorrect master password.
        if (marshalError.type == MPMarshalErrorMasterPassword) {
            ftl( "Incorrect master password according to configuration:\n  %s: %s", operation->sitesPath, marshalError.description );
            cli_free( args, operation );
            exit( EX_DATAERR );
        }

        // Any other parse error.
        if (!operation->user || marshalError.type != MPMarshalSuccess) {
            err( "Couldn't parse configuration file:\n  %s: %s", operation->sitesPath, marshalError.description );
            cli_free( args, operation );
            exit( EX_DATAERR );
        }
    }

    // If no user from mpsites, create a new one.
    if (!operation->user)
        operation->user = mpw_marshal_user(
                operation->fullName, operation->masterPassword, MPAlgorithmVersionCurrent );
}

void cli_site(Arguments __unused *args, Operation *operation) {

    if (!operation->siteName)
        abort();

    // Load the site object from mpsites.
    for (size_t s = 0; !operation->site && s < operation->user->sites_count; ++s)
        if (strcmp( operation->siteName, (&operation->user->sites[s])->name ) == 0)
            operation->site = &operation->user->sites[s];

    // If no site from mpsites, create a new one.
    if (!operation->site)
        operation->site = mpw_marshal_site(
                operation->user, operation->siteName, operation->user->defaultType, MPCounterValueDefault, operation->user->algorithm );
}

void cli_question(Arguments __unused *args, Operation *operation) {

    if (!operation->site)
        abort();

    // Load the question object from mpsites.
    switch (operation->keyPurpose) {
        case MPKeyPurposeAuthentication:
        case MPKeyPurposeIdentification:
            break;
        case MPKeyPurposeRecovery:
            for (size_t q = 0; !operation->question && q < operation->site->questions_count; ++q)
                if ((!operation->keyContext && !strlen( (&operation->site->questions[q])->keyword )) ||
                    (operation->keyContext && strcmp( (&operation->site->questions[q])->keyword, operation->keyContext ) == 0))
                    operation->question = &operation->site->questions[q];

            // If no question from mpsites, create a new one.
            if (!operation->question)
                operation->question = mpw_marshal_question( operation->site, operation->keyContext );
            break;
    }
}

void cli_operation(Arguments __unused *args, Operation *operation) {

    mpw_free_string( &operation->identicon );
    operation->identicon = mpw_identicon_str( mpw_identicon( operation->user->fullName, operation->user->masterPassword ) );

    if (!operation->site)
        abort();

    switch (operation->keyPurpose) {
        case MPKeyPurposeAuthentication: {
            operation->purposeResult = "password";
            operation->resultType = operation->site->type;
            operation->resultState = operation->site->content? mpw_strdup( operation->site->content ): NULL;
            operation->siteCounter = operation->site->counter;
            break;
        }
        case MPKeyPurposeIdentification: {
            operation->purposeResult = "login";
            operation->resultType = operation->site->loginType;
            operation->resultState = operation->site->loginContent? mpw_strdup( operation->site->loginContent ): NULL;
            operation->siteCounter = MPCounterValueInitial;
            break;
        }
        case MPKeyPurposeRecovery: {
            mpw_free_string( &operation->keyContext );
            operation->purposeResult = "answer";
            operation->keyContext = operation->question->keyword? mpw_strdup( operation->question->keyword ): NULL;
            operation->resultType = operation->question->type;
            operation->resultState = operation->question->content? mpw_strdup( operation->question->content ): NULL;
            operation->siteCounter = MPCounterValueInitial;
            break;
        }
    }
}

void cli_resultType(Arguments *args, Operation *operation) {

    if (!args->resultType)
        return;
    if (!operation->site)
        abort();

    operation->resultType = mpw_typeWithName( args->resultType );
    if (ERR == (int)operation->resultType) {
        ftl( "Invalid type: %s", args->resultType );
        cli_free( args, operation );
        exit( EX_USAGE );
    }

    if (!(operation->resultType & MPSiteFeatureAlternative)) {
        switch (operation->keyPurpose) {
            case MPKeyPurposeAuthentication:
                operation->site->type = operation->resultType;
                break;
            case MPKeyPurposeIdentification:
                operation->site->loginType = operation->resultType;
                break;
            case MPKeyPurposeRecovery:
                operation->question->type = operation->resultType;
                break;
        }
    }
}

void cli_siteCounter(Arguments *args, Operation *operation) {

    if (!args->siteCounter)
        return;
    if (!operation->site)
        abort();

    long long int siteCounterInt = atoll( args->siteCounter );
    if (siteCounterInt < MPCounterValueFirst || siteCounterInt > MPCounterValueLast) {
        ftl( "Invalid site counter: %s", args->siteCounter );
        cli_free( args, operation );
        exit( EX_USAGE );
    }

    switch (operation->keyPurpose) {
        case MPKeyPurposeAuthentication:
            operation->siteCounter = operation->site->counter = (MPCounterValue)siteCounterInt;
            break;
        case MPKeyPurposeIdentification:
        case MPKeyPurposeRecovery:
            // NOTE: counter for login & question is not persisted.
            break;
    }
}

void cli_resultParam(Arguments *args, Operation *operation) {

    if (!args->resultParam)
        return;

    mpw_free_string( &operation->resultParam );
    operation->resultParam = mpw_strdup( args->resultParam );
}

void cli_algorithmVersion(Arguments *args, Operation *operation) {

    if (!args->algorithmVersion)
        return;
    if (!operation->site)
        abort();

    int algorithmVersionInt = atoi( args->algorithmVersion );
    if (algorithmVersionInt < MPAlgorithmVersionFirst || algorithmVersionInt > MPAlgorithmVersionLast) {
        ftl( "Invalid algorithm version: %s", args->algorithmVersion );
        cli_free( args, operation );
        exit( EX_USAGE );
    }
    operation->site->algorithm = (MPAlgorithmVersion)algorithmVersionInt;
}

void cli_sitesRedacted(Arguments *args, Operation *operation) {

    if (args->sitesRedacted)
        operation->user->redacted = strcmp( args->sitesRedacted, "1" ) == 0;

    else if (!operation->user->redacted)
        wrn( "Sites configuration is not redacted.  Use -R 1 to change this." );
}

void cli_mpw(Arguments *args, Operation *operation) {

    if (!operation->site)
        abort();

    if (mpw_verbosity >= inf_level)
        fprintf( stderr, "%s's %s for %s:\n[ %s ]: ",
                operation->user->fullName, operation->purposeResult, operation->site->name, operation->identicon );

    // Determine master key.
    MPMasterKey masterKey = mpw_masterKey(
            operation->user->fullName, operation->user->masterPassword, operation->site->algorithm );
    if (!masterKey) {
        ftl( "Couldn't derive master key." );
        cli_free( args, operation );
        exit( EX_SOFTWARE );
    }

    // Update state from resultParam if stateful.
    if (operation->resultParam && operation->resultType & MPResultTypeClassStateful) {
        mpw_free_string( &operation->resultState );
        if (!(operation->resultState = mpw_siteState( masterKey, operation->site->name, operation->siteCounter,
                operation->keyPurpose, operation->keyContext, operation->resultType, operation->resultParam,
                operation->site->algorithm ))) {
            ftl( "Couldn't encrypt site result." );
            mpw_free( &masterKey, MPMasterKeySize );
            cli_free( args, operation );
            exit( EX_SOFTWARE );
        }
        inf( "(state) %s => ", operation->resultState );

        switch (operation->keyPurpose) {
            case MPKeyPurposeAuthentication: {
                mpw_free_string( &operation->site->content );
                operation->site->content = mpw_strdup( operation->resultState );
                break;
            }
            case MPKeyPurposeIdentification: {
                mpw_free_string( &operation->site->loginContent );
                operation->site->loginContent = mpw_strdup( operation->resultState );
                break;
            }

            case MPKeyPurposeRecovery: {
                mpw_free_string( &operation->question->content );
                operation->question->content = mpw_strdup( operation->resultState );
                break;
            }
        }

        // resultParam is consumed.
        mpw_free_string( &operation->resultParam );
    }

    // resultParam defaults to state.
    if (!operation->resultParam && operation->resultState)
        operation->resultParam = mpw_strdup( operation->resultState );

    // Generate result.
    const char *result = mpw_siteResult( masterKey, operation->site->name, operation->siteCounter,
            operation->keyPurpose, operation->keyContext, operation->resultType, operation->resultParam, operation->site->algorithm );
    mpw_free( &masterKey, MPMasterKeySize );
    if (!result) {
        ftl( "Couldn't generate site result." );
        cli_free( args, operation );
        exit( EX_SOFTWARE );
    }
    fflush( NULL );
    fprintf( stdout, "%s\n", result );
    if (operation->site->url)
        inf( "See: %s", operation->site->url );
    mpw_free_string( &result );

    // Update usage metadata.
    operation->site->lastUsed = operation->user->lastUsed = time( NULL );
    operation->site->uses++;
}

void cli_save(Arguments __unused *args, Operation *operation) {

    if (operation->sitesFormat == MPMarshalFormatNone)
        return;

    if (!operation->sitesFormatFixed)
        operation->sitesFormat = MPMarshalFormatDefault;

    mpw_free_string( &operation->sitesPath );
    operation->sitesPath = mpw_path( operation->user->fullName, mpw_marshal_format_extension( operation->sitesFormat ) );
    dbg( "Updating: %s (%s)", operation->sitesPath, mpw_nameForFormat( operation->sitesFormat ) );

    FILE *sitesFile = NULL;
    if (!operation->sitesPath || !mpw_mkdirs( operation->sitesPath ) || !(sitesFile = fopen( operation->sitesPath, "w" ))) {
        wrn( "Couldn't create updated configuration file:\n  %s: %s", operation->sitesPath, strerror( errno ) );
        return;
    }

    char *buf = NULL;
    MPMarshalError marshalError = { .type = MPMarshalSuccess };
    if (!mpw_marshal_write( &buf, operation->sitesFormat, operation->user, &marshalError ) || marshalError.type != MPMarshalSuccess)
        wrn( "Couldn't encode updated configuration file:\n  %s: %s", operation->sitesPath, marshalError.description );

    else if (fwrite( buf, sizeof( char ), strlen( buf ), sitesFile ) != strlen( buf ))
        wrn( "Error while writing updated configuration file:\n  %s: %d", operation->sitesPath, ferror( sitesFile ) );

    mpw_free_string( &buf );
    fclose( sitesFile );
}
