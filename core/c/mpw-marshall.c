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


#include <stdio.h>
#include <string.h>
#include <time.h>
#include <json-c/json.h>
#include "mpw-marshall.h"
#include "mpw-util.h"

static char *mpw_get_token(char **in, char *eol, char *delim) {

    // Skip leading spaces.
    for (; **in == ' '; ++*in);

    // Find characters up to the first delim.
    size_t len = strcspn( *in, delim );
    char *token = len? strndup( *in, len ): NULL;

    // Advance past the delimitor.
    *in = min( eol, *in + len + 1 );
    return token;
}

static bool mpw_update_masterKey(MPMasterKey *masterKey, MPAlgorithmVersion *masterKeyAlgorithm, MPAlgorithmVersion targetKeyAlgorithm,
        const char *fullName, const char *masterPassword) {

    if (*masterKeyAlgorithm != targetKeyAlgorithm) {
        mpw_free( *masterKey, MPMasterKeySize );
        *masterKeyAlgorithm = targetKeyAlgorithm;
        *masterKey = mpw_masterKeyForUser(
                fullName, masterPassword, *masterKeyAlgorithm );
        if (!*masterKey) {
            err( "Couldn't derive master key for user %s, algorithm %d.\n", fullName, *masterKeyAlgorithm );
            return false;
        }
    }

    return true;
}

MPMarshalledUser *mpw_marshall_user(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    MPMarshalledUser *user = malloc( sizeof( MPMarshalledUser ) );
    if (!user)
        return NULL;

    *user = (MPMarshalledUser){
            .name = strdup( fullName ),
            .masterPassword = strdup( masterPassword ),
            .algorithm = algorithmVersion,
            .redacted = true,

            .avatar = 0,
            .defaultType = MPSiteTypeGeneratedLong,
            .lastUsed = 0,

            .sites_count = 0,
            .sites = NULL,
    };
    return user;
};

MPMarshalledSite *mpw_marshall_site(
        MPMarshalledUser *marshalledUser,
        const char *siteName, const MPSiteType siteType, const uint32_t siteCounter, const MPAlgorithmVersion algorithmVersion) {

    if (!(marshalledUser->sites =
            realloc( marshalledUser->sites, sizeof( MPMarshalledSite ) * (++marshalledUser->sites_count) )))
        return NULL;

    marshalledUser->sites[marshalledUser->sites_count - 1] = (MPMarshalledSite){
            .name = strdup( siteName ),
            .content = NULL,
            .type = siteType,
            .counter = siteCounter,
            .algorithm = algorithmVersion,

            .loginName = NULL,
            .loginGenerated = false,

            .url = NULL,
            .uses = 0,
            .lastUsed = 0,

            .questions_count = 0,
            .questions = NULL,
    };
    return marshalledUser->sites + sizeof( MPMarshalledSite ) * (marshalledUser->sites_count - 1);
};

MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *marshalledSite, const char *keyword) {

    if (!(marshalledSite->questions =
            realloc( marshalledSite->questions, sizeof( MPMarshalledQuestion ) * (++marshalledSite->questions_count) )))
        return NULL;

    marshalledSite->questions[marshalledSite->questions_count - 1] = (MPMarshalledQuestion){
            .keyword = strdup( keyword ),
    };
    return marshalledSite->questions + sizeof( MPMarshalledSite ) * (marshalledSite->questions_count - 1);
}

bool mpw_marshal_free(
        MPMarshalledUser *marshalledUser) {

    bool success = true;
    for (int s = 0; s < marshalledUser->sites_count; ++s) {
        MPMarshalledSite site = marshalledUser->sites[s];
        success &= mpw_free_string( site.name );
        for (int q = 0; q < site.questions_count; ++q) {
            MPMarshalledQuestion question = site.questions[q];
            success &= mpw_free_string( question.keyword );
        }
        success &= mpw_free( site.questions, sizeof( MPMarshalledQuestion ) * site.questions_count );
    }
    success &= mpw_free( marshalledUser->sites, sizeof( MPMarshalledSite ) * marshalledUser->sites_count );
    success &= mpw_free_string( marshalledUser->name );
    success &= mpw_free_string( marshalledUser->masterPassword );
    success &= mpw_free( marshalledUser, sizeof( MPMarshalledUser ) );

    return success;
}

#define try_asprintf(...) ({ if (asprintf( __VA_ARGS__ ) < 0) return false; })

bool mpw_marshall_write_flat(
        char **out, const MPMarshalledUser *marshalledUser) {

    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = marshalledUser->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm,
            marshalledUser->algorithm, marshalledUser->name, marshalledUser->masterPassword ))
        return false;

    try_asprintf( out, "# Master Password site export\n" );
    if (marshalledUser->redacted)
        try_asprintf( out, "#     Export of site names and passwords in clear-text.\n" );
    else
        try_asprintf( out, "#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n" );
    try_asprintf( out, "# \n" );
    try_asprintf( out, "##\n" );
    try_asprintf( out, "# Format: %d\n", 1 );

    size_t dateSize = 21;
    char dateString[dateSize];
    time_t now = time( NULL );
    if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &now ) ))
        try_asprintf( out, "# Date: %s\n", dateString );
    try_asprintf( out, "# User Name: %s\n", marshalledUser->name );
    try_asprintf( out, "# Full Name: %s\n", marshalledUser->name );
    try_asprintf( out, "# Avatar: %u\n", marshalledUser->avatar );
    try_asprintf( out, "# Key ID: %s\n", mpw_id_buf( masterKey, MPMasterKeySize ) );
    try_asprintf( out, "# Algorithm: %d\n", marshalledUser->algorithm );
    try_asprintf( out, "# Default Type: %d\n", marshalledUser->defaultType );
    try_asprintf( out, "# Passwords: %s\n", marshalledUser->redacted? "PROTECTED": "VISIBLE" );
    try_asprintf( out, "##\n" );
    try_asprintf( out, "#\n" );
    try_asprintf( out, "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
    try_asprintf( out, "#               used      used      type                       name\t                     name\tpassword\n" );

    // Sites.
    for (int s = 0; s < marshalledUser->sites_count; ++s) {
        MPMarshalledSite site = marshalledUser->sites[s];

        const char *content = site.type & MPSiteFeatureExportContent? site.content: NULL;
        if (!marshalledUser->redacted) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm,
                    site.algorithm, marshalledUser->name, marshalledUser->masterPassword ))
                return false;

            if (site.type & MPSiteTypeClassGenerated)
                content = mpw_passwordForSite( masterKey, site.name, site.type, site.counter,
                        MPSiteVariantPassword, NULL, site.algorithm );
            else if (content) {
                // TODO: Decrypt Personal Passwords
                //content = aes128_cbc( masterKey, content );
            }
        }

        if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &site.lastUsed ) ))
            try_asprintf( out, "%s  %8ld  %lu:%lu:%lu  %25s\t%25s\t%s\n",
                    dateString, (long)site.uses, (long)site.type, (long)site.algorithm, (long)site.counter,
                    site.loginName?: "", site.name, content?: "" );
    }
    mpw_free( masterKey, MPMasterKeySize );

    return true;
}

bool mpw_marshall_write_json(
        char **out, const MPMarshalledUser *marshalledUser) {

    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = marshalledUser->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm,
            marshalledUser->algorithm, marshalledUser->name, marshalledUser->masterPassword ))
        return false;

    json_object *json_out = json_object_new_object();

    // Section: "export"
    json_object *json_export = json_object_new_object();
    json_object_object_add( json_out, "export", json_export );
    json_object_object_add( json_export, "format", json_object_new_int( 1 ) );
    json_object_object_add( json_export, "redacted", json_object_new_boolean( marshalledUser->redacted ) );

    size_t dateSize = 21;
    char dateString[dateSize];
    time_t now = time( NULL );
    if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &now ) ))
        json_object_object_add( json_export, "date", json_object_new_string( dateString ) );
    json_object_put( json_export );

    // Section: "user"
    json_object *json_user = json_object_new_object();
    json_object_object_add( json_out, "user", json_user );
    json_object_object_add( json_user, "avatar", json_object_new_int( marshalledUser->avatar ) );
    json_object_object_add( json_user, "full_name", json_object_new_string( marshalledUser->name ) );

    if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &marshalledUser->lastUsed ) ))
        json_object_object_add( json_user, "last_used", json_object_new_string( dateString ) );
    json_object_object_add( json_user, "key_id", json_object_new_string( mpw_id_buf( masterKey, MPMasterKeySize ) ) );

    json_object_object_add( json_user, "algorithm", json_object_new_int( marshalledUser->algorithm ) );
    json_object_object_add( json_user, "default_type", json_object_new_int( marshalledUser->defaultType ) );
    json_object_put( json_user );

    // Section "sites"
    json_object *json_sites = json_object_new_object();
    json_object_object_add( json_out, "sites", json_sites );
    for (int s = 0; s < marshalledUser->sites_count; ++s) {
        MPMarshalledSite site = marshalledUser->sites[s];

        const char *content = site.type & MPSiteFeatureExportContent? site.content: NULL;
        if (!marshalledUser->redacted) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm,
                    site.algorithm, marshalledUser->name, marshalledUser->masterPassword ))
                return false;

            if (site.type & MPSiteTypeClassGenerated)
                content = mpw_passwordForSite( masterKey, site.name, site.type, site.counter,
                        MPSiteVariantPassword, NULL, site.algorithm );
            else if (content) {
                // TODO: Decrypt Personal Passwords
                //content = aes128_cbc( masterKey, content );
            }
        }

        json_object *json_site = json_object_new_object();
        json_object_object_add( json_sites, site.name, json_site );
        json_object_object_add( json_site, "type", json_object_new_int( site.type ) );
        json_object_object_add( json_site, "counter", json_object_new_int( site.counter ) );
        json_object_object_add( json_site, "algorithm", json_object_new_int( site.algorithm ) );
        if (content)
            json_object_object_add( json_site, "password", json_object_new_string( content ) );

        json_object_object_add( json_site, "login_name", json_object_new_string( site.loginName?: "" ) );
        json_object_object_add( json_site, "login_generated", json_object_new_boolean( site.loginGenerated ) );

        json_object_object_add( json_site, "uses", json_object_new_int( site.uses ) );
        if (strftime( dateString, dateSize, "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", gmtime( &site.lastUsed ) ))
            json_object_object_add( json_site, "last_used", json_object_new_string( dateString ) );

        json_object *json_site_questions = json_object_new_object();
        json_object_object_add( json_site, "questions", json_site_questions );
        for (int q = 0; q < site.questions_count; ++q) {
            MPMarshalledQuestion question = site.questions[q];

            json_object *json_site_question = json_object_new_object();
            json_object_object_add( json_site_questions, question.keyword, json_site_question );

            if (!marshalledUser->redacted)
                json_object_object_add( json_site_question, "answer", json_object_new_string(
                        mpw_passwordForSite( masterKey, site.name, MPSiteTypeGeneratedPhrase, 1,
                                MPSiteVariantAnswer, question.keyword, site.algorithm ) ) );
            json_object_put( json_site_question );
        }
        json_object_put( json_site_questions );

        json_object *json_site_mpw = json_object_new_object();
        json_object_object_add( json_site, "_ext_mpw", json_site_mpw );
        json_object_object_add( json_site_mpw, "url", json_object_new_string( site.url ) );
        json_object_put( json_site_mpw );
        json_object_put( json_site );
    }
    json_object_put( json_sites );

    try_asprintf( out, "%s\n", json_object_to_json_string_ext( json_out, JSON_C_TO_STRING_PRETTY ) );
    json_object_put( json_out );
    mpw_free( masterKey, MPMasterKeySize );

    return true;
}

bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, const MPMarshalledUser *marshalledUser) {

    switch (outFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_write_flat( out, marshalledUser );
        case MPMarshallFormatJSON:
            return mpw_marshall_write_json( out, marshalledUser );
    }

    return false;
}

MPMarshalledUser *mpw_marshall_read_flat(
        char *in, const char *masterPassword) {

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPMarshalledUser *user = NULL;
    unsigned int importFormat = 0, importAvatar = 0;
    char *importUserName = NULL, *importKeyID = NULL, *importDate = NULL;
    MPAlgorithmVersion importAlgorithm = MPAlgorithmVersionCurrent, masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPSiteType importDefaultType = (MPSiteType)0;
    bool headerStarted = false, headerEnded = false, importRedacted = false;
    for (char *endOfLine, *positionInLine = in; (endOfLine = strstr( positionInLine, "\n" )); positionInLine = endOfLine + 1) {

        // Comment or header
        if (*positionInLine == '#') {
            ++positionInLine;

            if (!headerStarted) {
                if (*positionInLine == '#')
                    // ## starts header
                    headerStarted = true;
                // Comment before header
                continue;
            }
            if (headerEnded)
                // Comment after header
                continue;
            if (*positionInLine == '#') {
                // ## ends header
                headerEnded = true;
                continue;
            }

            // Header
            char *headerName = mpw_get_token( &positionInLine, endOfLine, ":\n" );
            char *headerValue = mpw_get_token( &positionInLine, endOfLine, "\n" );
            if (!headerName || !headerValue) {
                err( "Invalid header: %s\n", strndup( positionInLine, endOfLine - positionInLine ) );
                return false;
            }

            if (strcmp( headerName, "Format" ) == 0)
                importFormat = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Date" ) == 0)
                importDate = strdup( headerValue );
            if (strcmp( headerName, "Full Name" ) == 0 || strcmp( headerName, "User Name" ) == 0)
                importUserName = strdup( headerValue );
            if (strcmp( headerName, "Avatar" ) == 0)
                importAvatar = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Key ID" ) == 0)
                importKeyID = strdup( headerValue );
            if (strcmp( headerName, "Algorithm" ) == 0) {
                int importAlgorithmInt = atoi( headerValue );
                if (importAlgorithmInt < MPAlgorithmVersionFirst || importAlgorithmInt > MPAlgorithmVersionLast) {
                    err( "Invalid algorithm version: %s\n", headerValue );
                    return false;
                }
                importAlgorithm = (MPAlgorithmVersion)importAlgorithmInt;
            }
            if (strcmp( headerName, "Default Type" ) == 0)
                importDefaultType = (MPSiteType)atoi( headerValue );
            if (strcmp( headerName, "Passwords" ) == 0)
                importRedacted = strcmp( headerValue, "VISIBLE" ) != 0;

            mpw_free_string( headerName );
            mpw_free_string( headerValue );
            continue;
        }
        if (!headerEnded)
            continue;
        if (!importUserName) {
            err( "Missing header: Full Name\n" );
            return false;
        }
        if (positionInLine >= endOfLine)
            continue;

        if (!user) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm,
                    importAlgorithm, importUserName, masterPassword ))
                return false;
            if (importKeyID && strcmp( importKeyID, mpw_id_buf( masterKey, MPMasterKeySize ) ) != 0) {
                err( "Incorrect master password for user import file.\n" );
                return false;
            }
            if (!(user = mpw_marshall_user( importUserName, masterPassword, importAlgorithm ))) {
                err( "Couldn't allocate a new user." );
                return false;
            }

            user->redacted = importRedacted;
            user->avatar = importAvatar;
            user->defaultType = importDefaultType;
        }

        // Site
        char *lastUsed = NULL, *uses = NULL, *type = NULL, *version = NULL, *counter = NULL;
        char *loginName = NULL, *siteName = NULL, *exportContent = NULL;
        switch (importFormat) {
            case 0: {
                lastUsed = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                uses = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                char *typeAndVersion = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                if (typeAndVersion) {
                    type = strdup( strtok( typeAndVersion, ":" ) );
                    version = strdup( strtok( NULL, "" ) );
                    mpw_free_string( typeAndVersion );
                }
                counter = strdup( "1" );
                loginName = NULL;
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                exportContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            case 1: {
                lastUsed = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                uses = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                char *typeAndVersionAndCounter = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                if (typeAndVersionAndCounter) {
                    type = strdup( strtok( typeAndVersionAndCounter, ":" ) );
                    version = strdup( strtok( NULL, ":" ) );
                    counter = strdup( strtok( NULL, "" ) );
                    mpw_free_string( typeAndVersionAndCounter );
                }
                loginName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                exportContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            default: {
                err( "Unexpected import format: %lu\n", (unsigned long)importFormat );
                return false;
            }
        }

        if (siteName && type && counter && version && uses && lastUsed) {
            MPMarshalledSite *site = mpw_marshall_site( user, siteName,
                    (MPSiteType)atoi( type ), (uint32_t)atoi( counter ), (MPAlgorithmVersion)atoi( version ) );
            if (exportContent) {
                if (user->redacted) {
                    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm,
                            site->algorithm, importUserName, masterPassword ))
                        return false;

                    // TODO: Encrypt Personal Passwords
                    //site->content = aes128_cbc( masterKey, exportContent );
                }
                else
                    site->content = exportContent;
            }

            site->loginName = loginName;
            site->uses = (unsigned int)atoi( uses );
            struct tm lastUsed_tm = { .tm_isdst = -1, .tm_gmtoff = 0 };
            sscanf( lastUsed, "%4d-%2d-%2dT%2d:%2d:%2dZ",
                    &lastUsed_tm.tm_year, &lastUsed_tm.tm_mon, &lastUsed_tm.tm_mday,
                    &lastUsed_tm.tm_hour, &lastUsed_tm.tm_min, &lastUsed_tm.tm_sec );
            lastUsed_tm.tm_year -= 1900; // tm_year 0 = rfc3339 year  1900
            lastUsed_tm.tm_mon -= 1;     // tm_mon  0 = rfc3339 month 1
            site->lastUsed = mktime( &lastUsed_tm );
        }
        else
            wrn( "Skipping: lastUsed=%s, uses=%s, type=%s, version=%s, counter=%s, loginName=%s, siteName=%s\n",
                    lastUsed, uses, type, version, counter, loginName, siteName );

        mpw_free_string( lastUsed );
        mpw_free_string( uses );
        mpw_free_string( type );
        mpw_free_string( version );
        mpw_free_string( counter );
        mpw_free_string( loginName );
        mpw_free_string( siteName );
        mpw_free_string( exportContent );
    }
    mpw_free_string( importUserName );
    mpw_free_string( importKeyID );
    mpw_free_string( importDate );
    mpw_free( masterKey, MPMasterKeySize );

    return user;
}

MPMarshalledUser *mpw_marshall_read_json(
        char *in, const char *masterPassword) {

    return NULL;
}

MPMarshalledUser *mpw_marshall_read(
        char *in, const MPMarshallFormat inFormat, const char *masterPassword) {

    switch (inFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_read_flat( in, masterPassword );
        case MPMarshallFormatJSON:
            return mpw_marshall_read_json( in, masterPassword );
    }

    return NULL;
}
