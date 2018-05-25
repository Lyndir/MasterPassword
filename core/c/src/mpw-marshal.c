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
#include <ctype.h>

#include "mpw-marshal.h"
#include "mpw-util.h"
#include "mpw-marshal-util.h"

MPMarshalledUser *mpw_marshal_user(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    MPMarshalledUser *user;
    if (!fullName || !masterPassword || !(user = malloc( sizeof( MPMarshalledUser ) )))
        return NULL;

    *user = (MPMarshalledUser){
            .fullName = mpw_strdup( fullName ),
            .masterPassword = mpw_strdup( masterPassword ),
            .algorithm = algorithmVersion,
            .redacted = true,

            .avatar = 0,
            .defaultType = MPResultTypeDefault,
            .lastUsed = 0,

            .sites_count = 0,
            .sites = NULL,
    };
    return user;
}

MPMarshalledSite *mpw_marshal_site(
        MPMarshalledUser *user, const char *siteName, const MPResultType resultType,
        const MPCounterValue siteCounter, const MPAlgorithmVersion algorithmVersion) {

    if (!siteName || !mpw_realloc( &user->sites, NULL, sizeof( MPMarshalledSite ) * ++user->sites_count ))
        return NULL;

    MPMarshalledSite *site = &user->sites[user->sites_count - 1];
    *site = (MPMarshalledSite){
            .name = mpw_strdup( siteName ),
            .content = NULL,
            .type = resultType,
            .counter = siteCounter,
            .algorithm = algorithmVersion,

            .loginContent = NULL,
            .loginType = MPResultTypeTemplateName,

            .url = NULL,
            .uses = 0,
            .lastUsed = 0,

            .questions_count = 0,
            .questions = NULL,
    };
    return site;
}

MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword) {

    if (!mpw_realloc( &site->questions, NULL, sizeof( MPMarshalledQuestion ) * ++site->questions_count ))
        return NULL;
    if (!keyword)
        keyword = "";

    MPMarshalledQuestion *question = &site->questions[site->questions_count - 1];
    *question = (MPMarshalledQuestion){
            .keyword = mpw_strdup( keyword ),
            .content = NULL,
            .type = MPResultTypeTemplatePhrase,
    };
    return question;
}

bool mpw_marshal_info_free(
        MPMarshalInfo **info) {

    if (!info || !*info)
        return true;

    bool success = true;
    success &= mpw_free_strings( &(*info)->fullName, &(*info)->keyID, NULL );
    success &= mpw_free( info, sizeof( MPMarshalInfo ) );

    return success;
}

bool mpw_marshal_free(
        MPMarshalledUser **user) {

    if (!user || !*user)
        return true;

    bool success = true;
    success &= mpw_free_strings( &(*user)->fullName, &(*user)->masterPassword, NULL );

    for (size_t s = 0; s < (*user)->sites_count; ++s) {
        MPMarshalledSite *site = &(*user)->sites[s];
        success &= mpw_free_strings( &site->name, &site->content, &site->loginContent, &site->url, NULL );

        for (size_t q = 0; q < site->questions_count; ++q) {
            MPMarshalledQuestion *question = &site->questions[q];
            success &= mpw_free_strings( &question->keyword, &question->content, NULL );
        }
        success &= mpw_free( &site->questions, sizeof( MPMarshalledQuestion ) * site->questions_count );
    }

    success &= mpw_free( &(*user)->sites, sizeof( MPMarshalledSite ) * (*user)->sites_count );
    success &= mpw_free( user, sizeof( MPMarshalledUser ) );

    return success;
}

static bool mpw_marshal_write_flat(
        char **out, const MPMarshalledUser *user, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    if (!user->fullName || !strlen( user->fullName )) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing full name." };
        return false;
    }
    if (!user->masterPassword || !strlen( user->masterPassword )) {
        *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Missing master password." };
        return false;
    }
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = user->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user->algorithm, user->fullName, user->masterPassword )) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
        return false;
    }

    mpw_string_pushf( out, "# Master Password site export\n" );
    if (user->redacted)
        mpw_string_pushf( out, "#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n" );
    else
        mpw_string_pushf( out, "#     Export of site names and passwords in clear-text.\n" );
    mpw_string_pushf( out, "# \n" );
    mpw_string_pushf( out, "##\n" );
    mpw_string_pushf( out, "# Format: %d\n", 1 );

    char dateString[21];
    time_t now = time( NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &now ) ))
        mpw_string_pushf( out, "# Date: %s\n", dateString );
    mpw_string_pushf( out, "# User Name: %s\n", user->fullName );
    mpw_string_pushf( out, "# Full Name: %s\n", user->fullName );
    mpw_string_pushf( out, "# Avatar: %u\n", user->avatar );
    mpw_string_pushf( out, "# Key ID: %s\n", mpw_id_buf( masterKey, MPMasterKeySize ) );
    mpw_string_pushf( out, "# Algorithm: %d\n", user->algorithm );
    mpw_string_pushf( out, "# Default Type: %d\n", user->defaultType );
    mpw_string_pushf( out, "# Passwords: %s\n", user->redacted? "PROTECTED": "VISIBLE" );
    mpw_string_pushf( out, "##\n" );
    mpw_string_pushf( out, "#\n" );
    mpw_string_pushf( out, "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
    mpw_string_pushf( out, "#               used      used      type                       name\t                     name\tpassword\n" );

    // Sites.
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        if (!site->name || !strlen( site->name ))
            continue;

        const char *content = NULL, *loginContent = NULL;
        if (!user->redacted) {
            // Clear Text
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, user->fullName, user->masterPassword )) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                return false;
            }

            content = mpw_siteResult( masterKey, site->name, site->counter,
                    MPKeyPurposeAuthentication, NULL, site->type, site->content, site->algorithm );
            loginContent = mpw_siteResult( masterKey, site->name, MPCounterValueInitial,
                    MPKeyPurposeIdentification, NULL, site->loginType, site->loginContent, site->algorithm );
        }
        else {
            // Redacted
            if (site->type & MPSiteFeatureExportContent && site->content && strlen( site->content ))
                content = mpw_strdup( site->content );
            if (site->loginType & MPSiteFeatureExportContent && site->loginContent && strlen( site->loginContent ))
                loginContent = mpw_strdup( site->loginContent );
        }

        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site->lastUsed ) ))
            mpw_string_pushf( out, "%s  %8ld  %lu:%lu:%lu  %25s\t%25s\t%s\n",
                    dateString, (long)site->uses, (long)site->type, (long)site->algorithm, (long)site->counter,
                    loginContent?: "", site->name, content?: "" );
        mpw_free_strings( &content, &loginContent, NULL );
    }
    mpw_free( &masterKey, MPMasterKeySize );

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return true;
}

#if MPW_JSON
static bool mpw_marshal_write_json(
        char **out, const MPMarshalledUser *user, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    if (!user->fullName || !strlen( user->fullName )) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing full name." };
        return false;
    }
    if (!user->masterPassword || !strlen( user->masterPassword )) {
        *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Missing master password." };
        return false;
    }
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = user->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user->algorithm, user->fullName, user->masterPassword )) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
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
    json_object_object_add( json_user, "avatar", json_object_new_int( (int32_t)user->avatar ) );
    json_object_object_add( json_user, "full_name", json_object_new_string( user->fullName ) );

    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &user->lastUsed ) ))
        json_object_object_add( json_user, "last_used", json_object_new_string( dateString ) );
    json_object_object_add( json_user, "key_id", json_object_new_string( mpw_id_buf( masterKey, MPMasterKeySize ) ) );

    json_object_object_add( json_user, "algorithm", json_object_new_int( (int32_t)user->algorithm ) );
    json_object_object_add( json_user, "default_type", json_object_new_int( (int32_t)user->defaultType ) );

    // Section "sites"
    json_object *json_sites = json_object_new_object();
    json_object_object_add( json_file, "sites", json_sites );
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        if (!site->name || !strlen( site->name ))
            continue;

        const char *content = NULL, *loginContent = NULL;
        if (!user->redacted) {
            // Clear Text
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, user->fullName, user->masterPassword )) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                return false;
            }

            content = mpw_siteResult( masterKey, site->name, site->counter,
                    MPKeyPurposeAuthentication, NULL, site->type, site->content, site->algorithm );
            loginContent = mpw_siteResult( masterKey, site->name, MPCounterValueInitial,
                    MPKeyPurposeIdentification, NULL, site->loginType, site->loginContent, site->algorithm );
        }
        else {
            // Redacted
            if (site->type & MPSiteFeatureExportContent && site->content && strlen( site->content ))
                content = mpw_strdup( site->content );
            if (site->loginType & MPSiteFeatureExportContent && site->loginContent && strlen( site->loginContent ))
                loginContent = mpw_strdup( site->loginContent );
        }

        json_object *json_site = json_object_new_object();
        json_object_object_add( json_sites, site->name, json_site );
        json_object_object_add( json_site, "type", json_object_new_int( (int32_t)site->type ) );
        json_object_object_add( json_site, "counter", json_object_new_int( (int32_t)site->counter ) );
        json_object_object_add( json_site, "algorithm", json_object_new_int( (int32_t)site->algorithm ) );
        if (content)
            json_object_object_add( json_site, "password", json_object_new_string( content ) );
        if (loginContent)
            json_object_object_add( json_site, "login_name", json_object_new_string( loginContent ) );
        json_object_object_add( json_site, "login_type", json_object_new_int( (int32_t)site->loginType ) );

        json_object_object_add( json_site, "uses", json_object_new_int( (int32_t)site->uses ) );
        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site->lastUsed ) ))
            json_object_object_add( json_site, "last_used", json_object_new_string( dateString ) );

        json_object *json_site_questions = json_object_new_object();
        json_object_object_add( json_site, "questions", json_site_questions );
        for (size_t q = 0; q < site->questions_count; ++q) {
            MPMarshalledQuestion *question = &site->questions[q];
            if (!question->keyword)
                continue;

            json_object *json_site_question = json_object_new_object();
            json_object_object_add( json_site_questions, question->keyword, json_site_question );
            json_object_object_add( json_site_question, "type", json_object_new_int( (int32_t)question->type ) );

            if (!user->redacted) {
                // Clear Text
                const char *answerContent = mpw_siteResult( masterKey, site->name, MPCounterValueInitial,
                        MPKeyPurposeRecovery, question->keyword, question->type, question->content, site->algorithm );
                json_object_object_add( json_site_question, "answer", json_object_new_string( answerContent ) );
            }
            else {
                // Redacted
                if (site->type & MPSiteFeatureExportContent && question->content && strlen( question->content ))
                    json_object_object_add( json_site_question, "answer", json_object_new_string( question->content ) );
            }
        }

        json_object *json_site_mpw = json_object_new_object();
        json_object_object_add( json_site, "_ext_mpw", json_site_mpw );
        if (site->url)
            json_object_object_add( json_site_mpw, "url", json_object_new_string( site->url ) );

        mpw_free_strings( &content, &loginContent, NULL );
    }

    mpw_string_pushf( out, "%s\n", json_object_to_json_string_ext( json_file, JSON_C_TO_STRING_PRETTY | JSON_C_TO_STRING_SPACED ) );
    mpw_free( &masterKey, MPMasterKeySize );
    json_object_put( json_file );

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return true;
}
#endif

bool mpw_marshal_write(
        char **out, const MPMarshalFormat outFormat, const MPMarshalledUser *user, MPMarshalError *error) {

    switch (outFormat) {
        case MPMarshalFormatNone:
            *error = (MPMarshalError){ .type = MPMarshalSuccess };
            return false;
        case MPMarshalFormatFlat:
            return mpw_marshal_write_flat( out, user, error );
#if MPW_JSON
        case MPMarshalFormatJSON:
            return mpw_marshal_write_json( out, user, error );
#endif
        default:
            *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unsupported output format: %u", outFormat ) };
            return false;
    }
}

static void mpw_marshal_read_flat_info(
        const char *in, MPMarshalInfo *info) {

    info->algorithm = MPAlgorithmVersionCurrent;

    // Parse import data.
    bool headerStarted = false;
    for (const char *endOfLine, *positionInLine = in; (endOfLine = strstr( positionInLine, "\n" )); positionInLine = endOfLine + 1) {

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
            if (*positionInLine == '#')
                // ## ends header
                break;

            // Header
            char *headerName = mpw_get_token( &positionInLine, endOfLine, ":\n" );
            char *headerValue = mpw_get_token( &positionInLine, endOfLine, "\n" );
            if (!headerName || !headerValue)
                continue;

            if (strcmp( headerName, "Algorithm" ) == 0)
                info->algorithm = (MPAlgorithmVersion)atoi( headerValue );
            if (strcmp( headerName, "Full Name" ) == 0 || strcmp( headerName, "User Name" ) == 0)
                info->fullName = mpw_strdup( headerValue );
            if (strcmp( headerName, "Key ID" ) == 0)
                info->keyID = mpw_strdup( headerValue );
            if (strcmp( headerName, "Passwords" ) == 0)
                info->redacted = strcmp( headerValue, "VISIBLE" ) != 0;
            if (strcmp( headerName, "Date" ) == 0)
                info->date = mpw_mktime( headerValue );

            mpw_free_strings( &headerName, &headerValue, NULL );
            continue;
        }
    }
}

static MPMarshalledUser *mpw_marshal_read_flat(
        const char *in, const char *masterPassword, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    if (!in || !strlen( in )) {
        error->type = MPMarshalErrorStructure;
        error->description = mpw_str( "No input data." );
        return NULL;
    }

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPMarshalledUser *user = NULL;
    unsigned int format = 0, avatar = 0;
    char *fullName = NULL, *keyID = NULL;
    MPAlgorithmVersion algorithm = MPAlgorithmVersionCurrent, masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPResultType defaultType = MPResultTypeDefault;
    bool headerStarted = false, headerEnded = false, importRedacted = false;
    for (const char *endOfLine, *positionInLine = in; (endOfLine = strstr( positionInLine, "\n" )); positionInLine = endOfLine + 1) {

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
                error->type = MPMarshalErrorStructure;
                error->description = mpw_str( "Invalid header: %s", mpw_strndup( positionInLine, (size_t)(endOfLine - positionInLine) ) );
                return NULL;
            }

            if (strcmp( headerName, "Format" ) == 0)
                format = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Full Name" ) == 0 || strcmp( headerName, "User Name" ) == 0)
                fullName = mpw_strdup( headerValue );
            if (strcmp( headerName, "Avatar" ) == 0)
                avatar = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Key ID" ) == 0)
                keyID = mpw_strdup( headerValue );
            if (strcmp( headerName, "Algorithm" ) == 0) {
                int value = atoi( headerValue );
                if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                    *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user algorithm version: %s", headerValue ) };
                    return NULL;
                }
                algorithm = (MPAlgorithmVersion)value;
            }
            if (strcmp( headerName, "Default Type" ) == 0) {
                int value = atoi( headerValue );
                if (!mpw_nameForType( (MPResultType)value )) {
                    *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user default type: %s", headerValue ) };
                    return NULL;
                }
                defaultType = (MPResultType)value;
            }
            if (strcmp( headerName, "Passwords" ) == 0)
                importRedacted = strcmp( headerValue, "VISIBLE" ) != 0;

            mpw_free_strings( &headerName, &headerValue, NULL );
            continue;
        }
        if (!headerEnded)
            continue;
        if (!fullName) {
            *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing header: Full Name" };
            return NULL;
        }
        if (positionInLine >= endOfLine)
            continue;

        if (!user) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, algorithm, fullName, masterPassword )) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                return NULL;
            }
            if (keyID && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
                *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Master password doesn't match key ID." };
                return NULL;
            }
            if (!(user = mpw_marshal_user( fullName, masterPassword, algorithm ))) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new user." };
                return NULL;
            }

            user->redacted = importRedacted;
            user->avatar = avatar;
            user->defaultType = defaultType;
        }

        // Site
        char *siteLoginName = NULL, *siteName = NULL, *siteContent = NULL;
        char *str_lastUsed = NULL, *str_uses = NULL, *str_type = NULL, *str_algorithm = NULL, *str_counter = NULL;
        switch (format) {
            case 0: {
                str_lastUsed = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                str_uses = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                char *typeAndVersion = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                if (typeAndVersion) {
                    str_type = mpw_strdup( strtok( typeAndVersion, ":" ) );
                    str_algorithm = mpw_strdup( strtok( NULL, "" ) );
                    mpw_free_string( &typeAndVersion );
                }
                str_counter = mpw_strdup( "1" );
                siteLoginName = NULL;
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            case 1: {
                str_lastUsed = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                str_uses = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                char *typeAndVersionAndCounter = mpw_get_token( &positionInLine, endOfLine, " \t\n" );
                if (typeAndVersionAndCounter) {
                    str_type = mpw_strdup( strtok( typeAndVersionAndCounter, ":" ) );
                    str_algorithm = mpw_strdup( strtok( NULL, ":" ) );
                    str_counter = mpw_strdup( strtok( NULL, "" ) );
                    mpw_free_string( &typeAndVersionAndCounter );
                }
                siteLoginName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            default: {
                *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unexpected import format: %u", format ) };
                return NULL;
            }
        }

        if (siteName && str_type && str_counter && str_algorithm && str_uses && str_lastUsed) {
            MPResultType siteType = (MPResultType)atoi( str_type );
            if (!mpw_nameForType( siteType )) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site type: %s: %s", siteName, str_type ) };
                return NULL;
            }
            long long int value = atoll( str_counter );
            if (value < MPCounterValueFirst || value > MPCounterValueLast) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site counter: %s: %s", siteName, str_counter ) };
                return NULL;
            }
            MPCounterValue siteCounter = (MPCounterValue)value;
            value = atoll( str_algorithm );
            if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site algorithm: %s: %s", siteName, str_algorithm ) };
                return NULL;
            }
            MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
            time_t siteLastUsed = mpw_mktime( str_lastUsed );
            if (!siteLastUsed) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site last used: %s: %s", siteName, str_lastUsed ) };
                return NULL;
            }

            MPMarshalledSite *site = mpw_marshal_site(
                    user, siteName, siteType, siteCounter, siteAlgorithm );
            if (!site) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new site." };
                return NULL;
            }

            site->uses = (unsigned int)atoi( str_uses );
            site->lastUsed = siteLastUsed;
            if (!user->redacted) {
                // Clear Text
                if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, fullName, masterPassword )) {
                    *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                    return NULL;
                }

                if (siteContent && strlen( siteContent ))
                    site->content = mpw_siteState( masterKey, site->name, site->counter,
                            MPKeyPurposeAuthentication, NULL, site->type, siteContent, site->algorithm );
                if (siteLoginName && strlen( siteLoginName ))
                    site->loginContent = mpw_siteState( masterKey, site->name, MPCounterValueInitial,
                            MPKeyPurposeIdentification, NULL, site->loginType, siteLoginName, site->algorithm );
            }
            else {
                // Redacted
                if (siteContent && strlen( siteContent ))
                    site->content = mpw_strdup( siteContent );
                if (siteLoginName && strlen( siteLoginName ))
                    site->loginContent = mpw_strdup( siteLoginName );
            }
        }
        else {
            error->type = MPMarshalErrorMissing;
            error->description = mpw_str(
                    "Missing one of: lastUsed=%s, uses=%s, type=%s, version=%s, counter=%s, loginName=%s, siteName=%s",
                    str_lastUsed, str_uses, str_type, str_algorithm, str_counter, siteLoginName, siteName );
            return NULL;
        }

        mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
        mpw_free_strings( &siteLoginName, &siteName, &siteContent, NULL );
    }
    mpw_free_strings( &fullName, &keyID, NULL );
    mpw_free( &masterKey, MPMasterKeySize );

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return user;
}

#if MPW_JSON
static void mpw_marshal_read_json_info(
        const char *in, MPMarshalInfo *info) {

    // Parse JSON.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (!json_file || json_error != json_tokener_success)
        return;

    // Section: "export"
    int64_t fileFormat = mpw_get_json_int( json_file, "export.format", 0 );
    if (fileFormat < 1)
        return;
    info->redacted = mpw_get_json_boolean( json_file, "export.redacted", true );
    info->date = mpw_mktime( mpw_get_json_string( json_file, "export.date", NULL ) );

    // Section: "user"
    info->algorithm = (MPAlgorithmVersion)mpw_get_json_int( json_file, "user.algorithm", MPAlgorithmVersionCurrent );
    info->fullName = mpw_strdup( mpw_get_json_string( json_file, "user.full_name", NULL ) );
    info->keyID = mpw_strdup( mpw_get_json_string( json_file, "user.key_id", NULL ) );

    json_object_put( json_file );
}

static MPMarshalledUser *mpw_marshal_read_json(
        const char *in, const char *masterPassword, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    if (!in || !strlen( in )) {
        error->type = MPMarshalErrorStructure;
        error->description = mpw_str( "No input data." );
        return NULL;
    }

    // Parse JSON.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (!json_file || json_error != json_tokener_success) {
        *error = (MPMarshalError){ MPMarshalErrorStructure, mpw_str( "JSON error: %s", json_tokener_error_desc( json_error ) ) };
        return NULL;
    }

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPMarshalledUser *user = NULL;

    // Section: "export"
    int64_t fileFormat = mpw_get_json_int( json_file, "export.format", 0 );
    if (fileFormat < 1) {
        *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unsupported format: %u", fileFormat ) };
        return NULL;
    }
    bool fileRedacted = mpw_get_json_boolean( json_file, "export.redacted", true );

    // Section: "user"
    unsigned int avatar = (unsigned int)mpw_get_json_int( json_file, "user.avatar", 0 );
    const char *fullName = mpw_get_json_string( json_file, "user.full_name", NULL );
    const char *str_lastUsed = mpw_get_json_string( json_file, "user.last_used", NULL );
    const char *keyID = mpw_get_json_string( json_file, "user.key_id", NULL );
    int64_t value = mpw_get_json_int( json_file, "user.algorithm", MPAlgorithmVersionCurrent );
    if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
        *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user algorithm version: %u", value ) };
        return NULL;
    }
    MPAlgorithmVersion algorithm = (MPAlgorithmVersion)value;
    MPResultType defaultType = (MPResultType)mpw_get_json_int( json_file, "user.default_type", MPResultTypeDefault );
    if (!mpw_nameForType( defaultType )) {
        *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user default type: %u", defaultType ) };
        return NULL;
    }
    time_t lastUsed = mpw_mktime( str_lastUsed );
    if (!lastUsed) {
        *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user last used: %s", str_lastUsed ) };
        return NULL;
    }
    if (!fullName || !strlen( fullName )) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing value for full name." };
        return NULL;
    }
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, algorithm, fullName, masterPassword )) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
        return NULL;
    }
    if (keyID && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
        *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Master password doesn't match key ID." };
        return NULL;
    }
    if (!(user = mpw_marshal_user( fullName, masterPassword, algorithm ))) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new user." };
        return NULL;
    }
    user->redacted = fileRedacted;
    user->avatar = avatar;
    user->defaultType = defaultType;
    user->lastUsed = lastUsed;

    // Section "sites"
    json_object_iter json_site;
    json_object *json_sites = mpw_get_json_section( json_file, "sites" );
    json_object_object_foreachC( json_sites, json_site ) {
        const char *siteName = json_site.key;
        value = mpw_get_json_int( json_site.val, "algorithm", (int32_t)user->algorithm );
        if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site algorithm version: %s: %d", siteName, value ) };
            return NULL;
        }
        MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
        MPResultType siteType = (MPResultType)mpw_get_json_int( json_site.val, "type", (int32_t)user->defaultType );
        if (!mpw_nameForType( siteType )) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site type: %s: %u", siteName, siteType ) };
            return NULL;
        }
        value = mpw_get_json_int( json_site.val, "counter", 1 );
        if (value < MPCounterValueFirst || value > MPCounterValueLast) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site counter: %s: %d", siteName, value ) };
            return NULL;
        }
        MPCounterValue siteCounter = (MPCounterValue)value;
        const char *siteContent = mpw_get_json_string( json_site.val, "password", NULL );
        const char *siteLoginName = mpw_get_json_string( json_site.val, "login_name", NULL );
        MPResultType siteLoginType = (MPResultType)mpw_get_json_int( json_site.val, "login_type", MPResultTypeTemplateName );
        unsigned int siteUses = (unsigned int)mpw_get_json_int( json_site.val, "uses", 0 );
        str_lastUsed = mpw_get_json_string( json_site.val, "last_used", NULL );
        time_t siteLastUsed = mpw_mktime( str_lastUsed );
        if (!siteLastUsed) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site last used: %s: %s", siteName, str_lastUsed ) };
            return NULL;
        }

        json_object *json_site_mpw = mpw_get_json_section( json_site.val, "_ext_mpw" );
        const char *siteURL = mpw_get_json_string( json_site_mpw, "url", NULL );

        MPMarshalledSite *site = mpw_marshal_site( user, siteName, siteType, siteCounter, siteAlgorithm );
        if (!site) {
            *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new site." };
            return NULL;
        }

        site->loginType = siteLoginType;
        site->url = siteURL? mpw_strdup( siteURL ): NULL;
        site->uses = siteUses;
        site->lastUsed = siteLastUsed;
        if (!user->redacted) {
            // Clear Text
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, fullName, masterPassword )) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                return NULL;
            }

            if (siteContent && strlen( siteContent ))
                site->content = mpw_siteState( masterKey, site->name, site->counter,
                        MPKeyPurposeAuthentication, NULL, site->type, siteContent, site->algorithm );
            if (siteLoginName && strlen( siteLoginName ))
                site->loginContent = mpw_siteState( masterKey, site->name, MPCounterValueInitial,
                        MPKeyPurposeIdentification, NULL, site->loginType, siteLoginName, site->algorithm );
        }
        else {
            // Redacted
            if (siteContent && strlen( siteContent ))
                site->content = mpw_strdup( siteContent );
            if (siteLoginName && strlen( siteLoginName ))
                site->loginContent = mpw_strdup( siteLoginName );
        }

        json_object_iter json_site_question;
        json_object *json_site_questions = mpw_get_json_section( json_site.val, "questions" );
        json_object_object_foreachC( json_site_questions, json_site_question ) {
            MPMarshalledQuestion *question = mpw_marshal_question( site, json_site_question.key );
            const char *answerContent = mpw_get_json_string( json_site_question.val, "answer", NULL );
            question->type = (MPResultType)mpw_get_json_int( json_site_question.val, "type", MPResultTypeTemplatePhrase );

            if (!user->redacted) {
                // Clear Text
                if (answerContent && strlen( answerContent ))
                    question->content = mpw_siteState( masterKey, site->name, MPCounterValueInitial,
                            MPKeyPurposeRecovery, question->keyword, question->type, answerContent, site->algorithm );
            }
            else {
                // Redacted
                if (answerContent && strlen( answerContent ))
                    question->content = mpw_strdup( answerContent );
            }
        }
    }
    json_object_put( json_file );

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return user;
}
#endif

MPMarshalInfo *mpw_marshal_read_info(
        const char *in) {

    MPMarshalInfo *info = malloc( sizeof( MPMarshalInfo ) );
    *info = (MPMarshalInfo){ .format = MPMarshalFormatNone };

    if (in && strlen( in )) {
        if (in[0] == '#') {
            *info = (MPMarshalInfo){ .format = MPMarshalFormatFlat };
            mpw_marshal_read_flat_info( in, info );
        }
        else if (in[0] == '{') {
            *info = (MPMarshalInfo){ .format = MPMarshalFormatJSON };
#if MPW_JSON
            mpw_marshal_read_json_info( in, info );
#endif
        }
    }

    return info;
}

MPMarshalledUser *mpw_marshal_read(
        const char *in, const MPMarshalFormat inFormat, const char *masterPassword, MPMarshalError *error) {

    switch (inFormat) {
        case MPMarshalFormatNone:
            *error = (MPMarshalError){ .type = MPMarshalSuccess };
            return false;
        case MPMarshalFormatFlat:
            return mpw_marshal_read_flat( in, masterPassword, error );
#if MPW_JSON
        case MPMarshalFormatJSON:
            return mpw_marshal_read_json( in, masterPassword, error );
#endif
        default:
            *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unsupported input format: %u", inFormat ) };
            return NULL;
    }
}

const MPMarshalFormat mpw_formatWithName(
        const char *formatName) {

    if (!formatName || !strlen( formatName ))
        return MPMarshalFormatNone;

    // Lower-case to standardize it.
    size_t stdFormatNameSize = strlen( formatName );
    char stdFormatName[stdFormatNameSize + 1];
    for (size_t c = 0; c < stdFormatNameSize; ++c)
        stdFormatName[c] = (char)tolower( formatName[c] );
    stdFormatName[stdFormatNameSize] = '\0';

    if (strncmp( mpw_nameForFormat( MPMarshalFormatNone ), stdFormatName, strlen( stdFormatName ) ) == 0)
        return MPMarshalFormatNone;
    if (strncmp( mpw_nameForFormat( MPMarshalFormatFlat ), stdFormatName, strlen( stdFormatName ) ) == 0)
        return MPMarshalFormatFlat;
    if (strncmp( mpw_nameForFormat( MPMarshalFormatJSON ), stdFormatName, strlen( stdFormatName ) ) == 0)
        return MPMarshalFormatJSON;

    dbg( "Not a format name: %s", stdFormatName );
    return (MPMarshalFormat)ERR;
}

const char *mpw_nameForFormat(
        const MPMarshalFormat format) {

    switch (format) {
        case MPMarshalFormatNone:
            return "none";
        case MPMarshalFormatFlat:
            return "flat";
        case MPMarshalFormatJSON:
            return "json";
        default: {
            dbg( "Unknown format: %d", format );
            return NULL;
        }
    }
}

const char *mpw_marshal_format_extension(
        const MPMarshalFormat format) {

    switch (format) {
        case MPMarshalFormatNone:
            return NULL;
        case MPMarshalFormatFlat:
            return "mpsites";
        case MPMarshalFormatJSON:
            return "mpsites.json";
        default: {
            dbg( "Unknown format: %d", format );
            return NULL;
        }
    }
}
