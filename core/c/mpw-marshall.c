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

static time_t mpw_mktime(
        const char *time) {

    struct tm tm = { .tm_isdst = -1, .tm_gmtoff = 0 };
    if (time && sscanf( time, "%4d-%2d-%2dT%2d:%2d:%2dZ",
            &tm.tm_year, &tm.tm_mon, &tm.tm_mday,
            &tm.tm_hour, &tm.tm_min, &tm.tm_sec ) == 6) {
        tm.tm_year -= 1900; // tm_year 0 = rfc3339 year  1900
        tm.tm_mon -= 1;     // tm_mon  0 = rfc3339 month 1
        return mktime( &tm );
    }

    return false;
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

    MPMarshalledUser *user;
    if (!fullName || !masterPassword || !(user = malloc( sizeof( MPMarshalledUser ) )))
        return NULL;

    *user = (MPMarshalledUser){
            .name = strdup( fullName ),
            .masterPassword = strdup( masterPassword ),
            .algorithm = algorithmVersion,
            .redacted = true,

            .avatar = 0,
            .defaultType = MPSiteTypeDefault,
            .lastUsed = 0,

            .sites_count = 0,
            .sites = NULL,
    };
    return user;
};

MPMarshalledSite *mpw_marshall_site(
        MPMarshalledUser *marshalledUser,
        const char *siteName, const MPSiteType siteType, const uint32_t siteCounter, const MPAlgorithmVersion algorithmVersion) {

    if (!siteName || !(marshalledUser->sites =
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

    if (!keyword || !(marshalledSite->questions =
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
        char **out, const MPMarshalledUser *user, MPMarshallError *error) {

    *error = MPMarshallErrorInternal;
    if (!user->name || !strlen( user->name )) {
        err( "Missing full name.\n" );
        *error = MPMarshallErrorMissing;
        return false;
    }
    if (!user->masterPassword || !strlen( user->masterPassword )) {
        err( "Missing master password.\n" );
        *error = MPMarshallErrorMasterPassword;
        return false;
    }
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = user->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user->algorithm, user->name, user->masterPassword )) {
        err( "Couldn't derive master key.\n" );
        return false;
    }

    try_asprintf( out, "# Master Password site export\n" );
    if (user->redacted)
        try_asprintf( out, "#     Export of site names and passwords in clear-text.\n" );
    else
        try_asprintf( out, "#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n" );
    try_asprintf( out, "# \n" );
    try_asprintf( out, "##\n" );
    try_asprintf( out, "# Format: %d\n", 1 );

    char dateString[21];
    time_t now = time( NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &now ) ))
        try_asprintf( out, "# Date: %s\n", dateString );
    try_asprintf( out, "# User Name: %s\n", user->name );
    try_asprintf( out, "# Full Name: %s\n", user->name );
    try_asprintf( out, "# Avatar: %u\n", user->avatar );
    try_asprintf( out, "# Key ID: %s\n", mpw_id_buf( masterKey, MPMasterKeySize ) );
    try_asprintf( out, "# Algorithm: %d\n", user->algorithm );
    try_asprintf( out, "# Default Type: %d\n", user->defaultType );
    try_asprintf( out, "# Passwords: %s\n", user->redacted? "PROTECTED": "VISIBLE" );
    try_asprintf( out, "##\n" );
    try_asprintf( out, "#\n" );
    try_asprintf( out, "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
    try_asprintf( out, "#               used      used      type                       name\t                     name\tpassword\n" );

    // Sites.
    for (int s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite site = user->sites[s];
        if (!site.name || !strlen( site.name ))
            continue;

        const char *content = site.type & MPSiteFeatureExportContent? site.content: NULL;
        if (!user->redacted) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site.algorithm, user->name, user->masterPassword )) {
                err( "Couldn't derive master key.\n" );
                return false;
            }

            if (site.type & MPSiteTypeClassGenerated)
                content = mpw_passwordForSite( masterKey, site.name, site.type, site.counter, MPSiteVariantPassword, NULL, site.algorithm );
            else if (content) {
                // TODO: Decrypt Personal Passwords
                //content = aes128_cbc( masterKey, content );
            }
        }

        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site.lastUsed ) ))
            try_asprintf( out, "%s  %8ld  %lu:%lu:%lu  %25s\t%25s\t%s\n",
                    dateString, (long)site.uses, (long)site.type, (long)site.algorithm, (long)site.counter,
                    site.loginName?: "", site.name, content?: "" );
    }
    mpw_free( masterKey, MPMasterKeySize );

    *error = MPMarshallSuccess;
    return true;
}

bool mpw_marshall_write_json(
        char **out, const MPMarshalledUser *user, MPMarshallError *error) {

    *error = MPMarshallErrorInternal;
    if (!user->name || !strlen( user->name )) {
        err( "Missing full name.\n" );
        *error = MPMarshallErrorMissing;
        return false;
    }
    if (!user->masterPassword || !strlen( user->masterPassword )) {
        err( "Missing master password.\n" );
        *error = MPMarshallErrorMasterPassword;
        return false;
    }
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = user->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user->algorithm, user->name, user->masterPassword )) {
        err( "Couldn't derive master key.\n" );
        return false;
    }

    // Section: "export"
    json_object *json_file = json_object_new_object();
    json_object *json_export = json_object_new_object();
    json_object_object_add( json_file, "export", json_export );
    json_object_object_add( json_export, "format", json_object_new_int( 1 ) );
    json_object_object_add( json_export, "redacted", json_object_new_boolean( user->redacted ) );

    char dateString[21];
    time_t now = time( NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &now ) ))
        json_object_object_add( json_export, "date", json_object_new_string( dateString ) );

    // Section: "user"
    json_object *json_user = json_object_new_object();
    json_object_object_add( json_file, "user", json_user );
    json_object_object_add( json_user, "avatar", json_object_new_int( user->avatar ) );
    json_object_object_add( json_user, "full_name", json_object_new_string( user->name ) );

    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &user->lastUsed ) ))
        json_object_object_add( json_user, "last_used", json_object_new_string( dateString ) );
    json_object_object_add( json_user, "key_id", json_object_new_string( mpw_id_buf( masterKey, MPMasterKeySize ) ) );

    json_object_object_add( json_user, "algorithm", json_object_new_int( user->algorithm ) );
    json_object_object_add( json_user, "default_type", json_object_new_int( user->defaultType ) );

    // Section "sites"
    json_object *json_sites = json_object_new_object();
    json_object_object_add( json_file, "sites", json_sites );
    for (int s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite site = user->sites[s];
        if (!site.name || !strlen( site.name ))
            continue;

        const char *content = site.type & MPSiteFeatureExportContent? site.content: NULL;
        if (!user->redacted) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site.algorithm, user->name, user->masterPassword )) {
                err( "Couldn't derive master key.\n" );
                return false;
            }

            if (site.type & MPSiteTypeClassGenerated)
                content = mpw_passwordForSite( masterKey, site.name, site.type, site.counter, MPSiteVariantPassword, NULL, site.algorithm );
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
        if (site.loginName)
            json_object_object_add( json_site, "login_name", json_object_new_string( site.loginName ) );
        json_object_object_add( json_site, "login_generated", json_object_new_boolean( site.loginGenerated ) );

        json_object_object_add( json_site, "uses", json_object_new_int( site.uses ) );
        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site.lastUsed ) ))
            json_object_object_add( json_site, "last_used", json_object_new_string( dateString ) );

        json_object *json_site_questions = json_object_new_object();
        json_object_object_add( json_site, "questions", json_site_questions );
        for (int q = 0; q < site.questions_count; ++q) {
            MPMarshalledQuestion question = site.questions[q];
            if (!question.keyword)
                continue;

            json_object *json_site_question = json_object_new_object();
            json_object_object_add( json_site_questions, question.keyword, json_site_question );

            if (!user->redacted) {
                const char *answer = mpw_passwordForSite( masterKey, site.name, MPSiteTypeGeneratedPhrase, 1,
                        MPSiteVariantAnswer, question.keyword, site.algorithm );
                if (answer)
                    json_object_object_add( json_site_question, "answer", json_object_new_string( answer ) );
            }
        }

        json_object *json_site_mpw = json_object_new_object();
        json_object_object_add( json_site, "_ext_mpw", json_site_mpw );
        if (site.url)
            json_object_object_add( json_site_mpw, "url", json_object_new_string( site.url ) );
    }

    try_asprintf( out, "%s\n", json_object_to_json_string_ext( json_file, JSON_C_TO_STRING_PRETTY | JSON_C_TO_STRING_SPACED ) );
    mpw_free( masterKey, MPMasterKeySize );
    json_object_put( json_file );

    *error = MPMarshallSuccess;
    return true;
}

bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, const MPMarshalledUser *marshalledUser, MPMarshallError *error) {

    switch (outFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_write_flat( out, marshalledUser, error );
        case MPMarshallFormatJSON:
            return mpw_marshall_write_json( out, marshalledUser, error );
    }

    err( "Unsupported output format: %u\n", outFormat );
    *error = MPMarshallErrorFormat;
    return false;
}

MPMarshalledUser *mpw_marshall_read_flat(
        char *in, const char *masterPassword, MPMarshallError *error) {

    *error = MPMarshallErrorInternal;

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPMarshalledUser *user = NULL;
    unsigned int importFormat = 0, importAvatar = 0;
    char *importUserName = NULL, *importKeyID = NULL, *importDate = NULL;
    MPAlgorithmVersion importAlgorithm = MPAlgorithmVersionCurrent, masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPSiteType importDefaultType = MPSiteTypeDefault;
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
                *error = MPMarshallErrorStructure;
                return NULL;
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
                    *error = MPMarshallErrorIllegal;
                    return NULL;
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
            *error = MPMarshallErrorMissing;
            return NULL;
        }
        if (positionInLine >= endOfLine)
            continue;

        if (!user) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, importAlgorithm, importUserName, masterPassword )) {
                err( "Couldn't derive master key.\n" );
                return NULL;
            }
            if (importKeyID && !mpw_id_buf_equals( importKeyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
                err( "Incorrect master password for user import file: %s != %s\n", importKeyID, mpw_id_buf( masterKey, MPMasterKeySize ) );
                *error = MPMarshallErrorMasterPassword;
                return NULL;
            }
            if (!(user = mpw_marshall_user( importUserName, masterPassword, importAlgorithm ))) {
                err( "Couldn't allocate a new user.\n" );
                return NULL;
            }

            user->redacted = importRedacted;
            user->avatar = importAvatar;
            user->defaultType = importDefaultType;
        }

        // Site
        char *siteLastUsed = NULL, *siteUses = NULL, *siteType = NULL, *siteAlgorithm = NULL, *siteCounter = NULL;
        char *siteLoginName = NULL, *siteName = NULL, *siteContent = NULL;
        switch (importFormat) {
            case 0: {
                siteLastUsed = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                siteUses = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                char *typeAndVersion = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                if (typeAndVersion) {
                    siteType = strdup( strtok( typeAndVersion, ":" ) );
                    siteAlgorithm = strdup( strtok( NULL, "" ) );
                    mpw_free_string( typeAndVersion );
                }
                siteCounter = strdup( "1" );
                siteLoginName = NULL;
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            case 1: {
                siteLastUsed = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                siteUses = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                char *typeAndVersionAndCounter = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                if (typeAndVersionAndCounter) {
                    siteType = strdup( strtok( typeAndVersionAndCounter, ":" ) );
                    siteAlgorithm = strdup( strtok( NULL, ":" ) );
                    siteCounter = strdup( strtok( NULL, "" ) );
                    mpw_free_string( typeAndVersionAndCounter );
                }
                siteLoginName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            default: {
                err( "Unexpected import format: %u\n", importFormat );
                *error = MPMarshallErrorFormat;
                return NULL;
            }
        }

        if (siteName && siteType && siteCounter && siteAlgorithm && siteUses && siteLastUsed) {
            MPAlgorithmVersion siteAlgorithmInt = (MPAlgorithmVersion)atoi( siteAlgorithm );
            if (siteAlgorithmInt < MPAlgorithmVersionFirst || siteAlgorithmInt > MPAlgorithmVersionLast) {
                err( "Invalid site algorithm version: %u\n", siteAlgorithmInt );
                *error = MPMarshallErrorIllegal;
                return NULL;
            }

            MPMarshalledSite *site = mpw_marshall_site( user, siteName,
                    (MPSiteType)atoi( siteType ), (uint32_t)atoi( siteCounter ), siteAlgorithmInt );
            if (!site) {
                err( "Couldn't allocate a new site.\n" );
                return NULL;
            }

            site->loginName = siteLoginName? strdup( siteLoginName ): NULL;
            site->uses = (unsigned int)atoi( siteUses );
            site->lastUsed = mpw_mktime( siteLastUsed );
            if (siteContent && strlen( siteContent )) {
                if (user->redacted) {
                    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, importUserName, masterPassword )) {
                        err( "Couldn't derive master key.\n" );
                        return NULL;
                    }

                    // TODO: Encrypt Personal Passwords
                    //site->content = aes128_cbc( masterKey, exportContent );
                }
                else
                    site->content = strdup( siteContent );
            }
        }
        else
            wrn( "Skipping: lastUsed=%s, uses=%s, type=%s, version=%s, counter=%s, loginName=%s, siteName=%s\n",
                    siteLastUsed, siteUses, siteType, siteAlgorithm, siteCounter, siteLoginName, siteName );

        mpw_free_string( siteLastUsed );
        mpw_free_string( siteUses );
        mpw_free_string( siteType );
        mpw_free_string( siteAlgorithm );
        mpw_free_string( siteCounter );
        mpw_free_string( siteLoginName );
        mpw_free_string( siteName );
        mpw_free_string( siteContent );
    }
    mpw_free_string( importUserName );
    mpw_free_string( importKeyID );
    mpw_free_string( importDate );
    mpw_free( masterKey, MPMasterKeySize );

    *error = MPMarshallSuccess;
    return user;
}

static json_object *mpw_marshall_get_json_section(
        json_object *obj, const char *section) {

    json_object *json_value = obj;
    char *sectionTokenizer = strdup( section ), *sectionToken = sectionTokenizer;
    for (sectionToken = strtok( sectionToken, "." ); sectionToken; sectionToken = strtok( NULL, "." ))
        if (!json_object_object_get_ex( json_value, sectionToken, &json_value ) || !json_value) {
            dbg( "While resolving: %s: Missing value for: %s\n", section, sectionToken );
            json_value = NULL;
            break;
        }
    free( sectionTokenizer );

    return json_value;
}

static const char *mpw_marshall_get_json_string(
        json_object *obj, const char *section, const char *defaultValue) {

    json_object *json_value = mpw_marshall_get_json_section( obj, section );
    if (!json_value)
        return defaultValue;

    return json_object_get_string( json_value );
}

static int32_t mpw_marshall_get_json_int(
        json_object *obj, const char *section, int32_t defaultValue) {

    json_object *json_value = mpw_marshall_get_json_section( obj, section );
    if (!json_value)
        return defaultValue;

    return json_object_get_int( json_value );
}

static bool mpw_marshall_get_json_boolean(
        json_object *obj, const char *section, bool defaultValue) {

    json_object *json_value = mpw_marshall_get_json_section( obj, section );
    if (!json_value)
        return defaultValue;

    return json_object_get_boolean( json_value ) == TRUE;
}

MPMarshalledUser *mpw_marshall_read_json(
        char *in, const char *masterPassword, MPMarshallError *error) {

    *error = MPMarshallErrorInternal;

    // Parse JSON.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (json_error != json_tokener_success)
        err( "JSON error: %s\n", json_tokener_error_desc( json_error ) );
    if (!json_file) {
        *error = MPMarshallErrorStructure;
        return NULL;
    }

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPMarshalledUser *user = NULL;

    // Section: "export"
    unsigned int fileFormat = (unsigned int)mpw_marshall_get_json_int( json_file, "export.format", 0 );
    if (fileFormat < 1) {
        err( "Unsupported format: %u\n", fileFormat );
        *error = MPMarshallErrorFormat;
        return NULL;
    }
    bool fileRedacted = mpw_marshall_get_json_boolean( json_file, "export.redacted", true );
    const char *fileDate = mpw_marshall_get_json_string( json_file, "export.date", NULL );

    // Section: "user"
    unsigned int avatar = (unsigned int)mpw_marshall_get_json_int( json_file, "user.avatar", 0 );
    const char *fullName = mpw_marshall_get_json_string( json_file, "user.full_name", NULL );
    const char *lastUsed = mpw_marshall_get_json_string( json_file, "user.last_used", NULL );
    const char *keyID = mpw_marshall_get_json_string( json_file, "user.key_id", NULL );
    MPAlgorithmVersion algorithm = (MPAlgorithmVersion)mpw_marshall_get_json_int( json_file, "user.algorithm", MPAlgorithmVersionCurrent );
    if (algorithm < MPAlgorithmVersionFirst || algorithm > MPAlgorithmVersionLast) {
        err( "Invalid user algorithm version: %u\n", algorithm );
        *error = MPMarshallErrorIllegal;
        return NULL;
    }
    MPSiteType defaultType = (MPSiteType)mpw_marshall_get_json_int( json_file, "user.default_type", MPSiteTypeDefault );

    if (!fullName || !strlen( fullName )) {
        err( "Missing value for full name.\n" );
        *error = MPMarshallErrorMissing;
        return NULL;
    }
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, algorithm, fullName, masterPassword )) {
        err( "Couldn't derive master key.\n" );
        return NULL;
    }
    if (keyID && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
        err( "Incorrect master password for user import file: %s != %s\n", keyID, mpw_id_buf( masterKey, MPMasterKeySize ) );
        *error = MPMarshallErrorMasterPassword;
        return NULL;
    }
    if (!(user = mpw_marshall_user( fullName, masterPassword, algorithm ))) {
        err( "Couldn't allocate a new user.\n" );
        return NULL;
    }

    user->redacted = fileRedacted;
    user->avatar = avatar;
    user->defaultType = defaultType;
    user->lastUsed = mpw_mktime( lastUsed );

    // Section "sites"
    json_object_iter json_site;
    json_object *json_sites = mpw_marshall_get_json_section( json_file, "sites" );
    json_object_object_foreachC( json_sites, json_site ) {
        MPSiteType siteType = (MPSiteType)mpw_marshall_get_json_int( json_site.val, "type", user->defaultType );
        uint32_t siteCounter = (uint32_t)mpw_marshall_get_json_int( json_site.val, "counter", 1 );
        MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)mpw_marshall_get_json_int( json_site.val, "algorithm", user->algorithm );
        if (siteAlgorithm < MPAlgorithmVersionFirst || siteAlgorithm > MPAlgorithmVersionLast) {
            err( "Invalid site algorithm version: %u\n", siteAlgorithm );
            *error = MPMarshallErrorIllegal;
            return NULL;
        }
        const char *siteContent = mpw_marshall_get_json_string( json_site.val, "password", NULL );
        const char *siteLoginName = mpw_marshall_get_json_string( json_site.val, "login_name", NULL );
        bool siteLoginGenerated = mpw_marshall_get_json_boolean( json_site.val, "login_generated", false );
        unsigned int siteUses = (unsigned int)mpw_marshall_get_json_int( json_site.val, "uses", 0 );
        const char *siteLastUsed = mpw_marshall_get_json_string( json_site.val, "last_used", NULL );

        json_object *json_site_mpw = mpw_marshall_get_json_section( json_site.val, "_ext_mpw" );
        const char *siteURL = mpw_marshall_get_json_string( json_site_mpw, "url", NULL );

        MPMarshalledSite *site = mpw_marshall_site( user, json_site.key, siteType, siteCounter, siteAlgorithm );
        if (!site) {
            err( "Couldn't allocate a new site.\n" );
            return NULL;
        }

        site->loginName = siteLoginName? strdup( siteLoginName ): NULL;
        site->loginGenerated = siteLoginGenerated;
        site->url = siteURL? strdup( siteURL ): NULL;
        site->uses = siteUses;
        site->lastUsed = mpw_mktime( siteLastUsed );
        if (siteContent && strlen( siteContent )) {
            if (user->redacted) {
                if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, fullName, masterPassword )) {
                    err( "Couldn't derive master key.\n" );
                    return NULL;
                }

                // TODO: Encrypt Personal Passwords
                //site->content = aes128_cbc( masterKey, exportContent );
            }
            else
                site->content = strdup( siteContent );
        }

        json_object_iter json_site_question;
        json_object *json_site_questions = mpw_marshall_get_json_section( json_site.val, "questions" );
        json_object_object_foreachC( json_site_questions, json_site_question )
            mpw_marshal_question( site, json_site_question.key );
    }
    json_object_put( json_file );

    *error = MPMarshallSuccess;
    return user;
}

MPMarshalledUser *mpw_marshall_read(
        char *in, const MPMarshallFormat inFormat, const char *masterPassword, MPMarshallError *error) {

    switch (inFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_read_flat( in, masterPassword, error );
        case MPMarshallFormatJSON:
            return mpw_marshall_read_json( in, masterPassword, error );
    }

    err( "Unsupported input format: %u\n", inFormat );
    *error = MPMarshallErrorFormat;
    return NULL;
}
