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

#include "mpw-marshall.h"
#include "mpw-util.h"
#include "mpw-marshall-util.h"

MPMarshalledUser *mpw_marshall_user(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion) {

    MPMarshalledUser *user;
    if (!fullName || !masterPassword || !(user = malloc( sizeof( MPMarshalledUser ) )))
        return NULL;

    *user = (MPMarshalledUser){
            .fullName = strdup( fullName ),
            .masterPassword = strdup( masterPassword ),
            .algorithm = algorithmVersion,
            .redacted = true,

            .avatar = 0,
            .defaultType = MPResultTypeDefault,
            .lastUsed = 0,

            .sites_count = 0,
            .sites = NULL,
    };
    return user;
};

MPMarshalledSite *mpw_marshall_site(
        MPMarshalledUser *user, const char *siteName, const MPResultType resultType,
        const MPCounterValue siteCounter, const MPAlgorithmVersion algorithmVersion) {

    if (!siteName || !mpw_realloc( &user->sites, NULL, sizeof( MPMarshalledSite ) * ++user->sites_count ))
        return NULL;

    MPMarshalledSite *site = &user->sites[user->sites_count - 1];
    *site = (MPMarshalledSite){
            .name = strdup( siteName ),
            .content = NULL,
            .type = resultType,
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
    return site;
};

MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword) {

    if (!keyword || !mpw_realloc( &site->questions, NULL, sizeof( MPMarshalledQuestion ) * ++site->questions_count ))
        return NULL;

    MPMarshalledQuestion *question = &site->questions[site->questions_count - 1];
    *question = (MPMarshalledQuestion){
            .keyword = strdup( keyword ),
    };
    return question;
}

bool mpw_marshal_free(
        MPMarshalledUser *user) {

    if (!user)
        return true;

    bool success = true;
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        success &= mpw_free_string( site->name );
        for (size_t q = 0; q < site->questions_count; ++q) {
            MPMarshalledQuestion *question = &site->questions[q];
            success &= mpw_free_string( question->keyword );
        }
        success &= mpw_free( site->questions, sizeof( MPMarshalledQuestion ) * site->questions_count );
    }
    success &= mpw_free( user->sites, sizeof( MPMarshalledSite ) * user->sites_count );
    success &= mpw_free_string( user->fullName );
    success &= mpw_free_string( user->masterPassword );
    success &= mpw_free( user, sizeof( MPMarshalledUser ) );

    return success;
}

static bool mpw_marshall_write_flat(
        char **out, const MPMarshalledUser *user, MPMarshallError *error) {

    *error = (MPMarshallError){ MPMarshallErrorInternal, "Unexpected internal error." };
    if (!user->fullName || !strlen( user->fullName )) {
        *error = (MPMarshallError){ MPMarshallErrorMissing, "Missing full name." };
        return false;
    }
    if (!user->masterPassword || !strlen( user->masterPassword )) {
        *error = (MPMarshallError){ MPMarshallErrorMasterPassword, "Missing master password." };
        return false;
    }
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = user->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user->algorithm, user->fullName, user->masterPassword )) {
        *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
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

        const char *content = NULL;
        if (!user->redacted) {
            // Clear Text
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, user->fullName, user->masterPassword )) {
                *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
                return false;
            }

            if (site->type & MPResultTypeClassTemplate)
                content = mpw_siteResult( masterKey, site->name, site->counter,
                        MPKeyPurposeAuthentication, NULL, site->type, site->content, site->algorithm );
        }
        else if (site->type & MPSiteFeatureExportContent && site->content && strlen( site->content ))
            // Redacted
            content = strdup( site->content );

        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site->lastUsed ) ))
            mpw_string_pushf( out, "%s  %8ld  %lu:%lu:%lu  %25s\t%25s\t%s\n",
                    dateString, (long)site->uses, (long)site->type, (long)site->algorithm, (long)site->counter,
                    site->loginName?: "", site->name, content?: "" );
        mpw_free_string( content );
    }
    mpw_free( masterKey, MPMasterKeySize );

    *error = (MPMarshallError){ .type = MPMarshallSuccess };
    return true;
}

static bool mpw_marshall_write_json(
        char **out, const MPMarshalledUser *user, MPMarshallError *error) {

    *error = (MPMarshallError){ MPMarshallErrorInternal, "Unexpected internal error." };
    if (!user->fullName || !strlen( user->fullName )) {
        *error = (MPMarshallError){ MPMarshallErrorMissing, "Missing full name." };
        return false;
    }
    if (!user->masterPassword || !strlen( user->masterPassword )) {
        *error = (MPMarshallError){ MPMarshallErrorMasterPassword, "Missing master password." };
        return false;
    }
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = user->algorithm - 1;
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, user->algorithm, user->fullName, user->masterPassword )) {
        *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
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
    json_object_object_add( json_user, "avatar", json_object_new_int( (int)user->avatar ) );
    json_object_object_add( json_user, "full_name", json_object_new_string( user->fullName ) );

    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &user->lastUsed ) ))
        json_object_object_add( json_user, "last_used", json_object_new_string( dateString ) );
    json_object_object_add( json_user, "key_id", json_object_new_string( mpw_id_buf( masterKey, MPMasterKeySize ) ) );

    json_object_object_add( json_user, "algorithm", json_object_new_int( (int)user->algorithm ) );
    json_object_object_add( json_user, "default_type", json_object_new_int( (int)user->defaultType ) );

    // Section "sites"
    json_object *json_sites = json_object_new_object();
    json_object_object_add( json_file, "sites", json_sites );
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        if (!site->name || !strlen( site->name ))
            continue;

        const char *content = NULL;
        if (!user->redacted) {
            // Clear Text
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, user->fullName, user->masterPassword )) {
                *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
                return false;
            }

            if (site->type & MPResultTypeClassTemplate)
                content = mpw_siteResult( masterKey, site->name, site->counter,
                        MPKeyPurposeAuthentication, NULL, site->type, site->content, site->algorithm );
        }
        else if (site->type & MPSiteFeatureExportContent && site->content && strlen( site->content ))
            // Redacted
            content = strdup( site->content );

        json_object *json_site = json_object_new_object();
        json_object_object_add( json_sites, site->name, json_site );
        json_object_object_add( json_site, "type", json_object_new_int( (int)site->type ) );
        json_object_object_add( json_site, "counter", json_object_new_int( (int)site->counter ) );
        json_object_object_add( json_site, "algorithm", json_object_new_int( (int)site->algorithm ) );
        if (content)
            json_object_object_add( json_site, "password", json_object_new_string( content ) );
        if (site->loginName)
            json_object_object_add( json_site, "login_name", json_object_new_string( site->loginName ) );
        json_object_object_add( json_site, "login_generated", json_object_new_boolean( site->loginGenerated ) );

        json_object_object_add( json_site, "uses", json_object_new_int( (int)site->uses ) );
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

            if (!user->redacted) {
                // Clear Text
                const char *answer = mpw_siteResult( masterKey, site->name, MPCounterValueInitial,
                        MPKeyPurposeRecovery, question->keyword, MPResultTypeTemplatePhrase, NULL, site->algorithm );
                if (answer)
                    json_object_object_add( json_site_question, "answer", json_object_new_string( answer ) );
            }
        }

        json_object *json_site_mpw = json_object_new_object();
        json_object_object_add( json_site, "_ext_mpw", json_site_mpw );
        if (site->url)
            json_object_object_add( json_site_mpw, "url", json_object_new_string( site->url ) );

        mpw_free_string( content );
    }

    mpw_string_pushf( out, "%s\n", json_object_to_json_string_ext( json_file, JSON_C_TO_STRING_PRETTY | JSON_C_TO_STRING_SPACED ) );
    mpw_free( masterKey, MPMasterKeySize );
    json_object_put( json_file );

    *error = (MPMarshallError){ .type = MPMarshallSuccess };
    return true;
}

bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, const MPMarshalledUser *user, MPMarshallError *error) {

    switch (outFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_write_flat( out, user, error );
        case MPMarshallFormatJSON:
            return mpw_marshall_write_json( out, user, error );
        default:
            *error = (MPMarshallError){ MPMarshallErrorFormat, mpw_str( "Unsupported output format: %u", outFormat ) };
            return false;
    }
}

static MPMarshalledUser *mpw_marshall_read_flat(
        char *in, const char *masterPassword, MPMarshallError *error) {

    *error = (MPMarshallError){ MPMarshallErrorInternal, "Unexpected internal error." };

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPMarshalledUser *user = NULL;
    unsigned int format = 0, avatar = 0;
    char *fullName = NULL, *keyID = NULL;
    MPAlgorithmVersion algorithm = MPAlgorithmVersionCurrent, masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPResultType defaultType = MPResultTypeDefault;
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
                error->type = MPMarshallErrorStructure;
                error->description = mpw_str( "Invalid header: %s", strndup( positionInLine, (size_t)(endOfLine - positionInLine) ) );
                return NULL;
            }

            if (strcmp( headerName, "Format" ) == 0)
                format = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Full Name" ) == 0 || strcmp( headerName, "User Name" ) == 0)
                fullName = strdup( headerValue );
            if (strcmp( headerName, "Avatar" ) == 0)
                avatar = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Key ID" ) == 0)
                keyID = strdup( headerValue );
            if (strcmp( headerName, "Algorithm" ) == 0) {
                int value = atoi( headerValue );
                if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                    *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid user algorithm version: %s", headerValue ) };
                    return NULL;
                }
                algorithm = (MPAlgorithmVersion)value;
            }
            if (strcmp( headerName, "Default Type" ) == 0) {
                int value = atoi( headerValue );
                if (!mpw_nameForType( (MPResultType)value )) {
                    *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid user default type: %s", headerValue ) };
                    return NULL;
                }
                defaultType = (MPResultType)value;
            }
            if (strcmp( headerName, "Passwords" ) == 0)
                importRedacted = strcmp( headerValue, "VISIBLE" ) != 0;

            mpw_free_string( headerName );
            mpw_free_string( headerValue );
            continue;
        }
        if (!headerEnded)
            continue;
        if (!fullName) {
            *error = (MPMarshallError){ MPMarshallErrorMissing, "Missing header: Full Name" };
            return NULL;
        }
        if (positionInLine >= endOfLine)
            continue;

        if (!user) {
            if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, algorithm, fullName, masterPassword )) {
                *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
                return NULL;
            }
            if (keyID && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
                *error = (MPMarshallError){ MPMarshallErrorMasterPassword, "Master password doesn't match key ID." };
                return NULL;
            }
            if (!(user = mpw_marshall_user( fullName, masterPassword, algorithm ))) {
                *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't allocate a new user." };
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
                    str_type = strdup( strtok( typeAndVersion, ":" ) );
                    str_algorithm = strdup( strtok( NULL, "" ) );
                    mpw_free_string( typeAndVersion );
                }
                str_counter = strdup( "1" );
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
                    str_type = strdup( strtok( typeAndVersionAndCounter, ":" ) );
                    str_algorithm = strdup( strtok( NULL, ":" ) );
                    str_counter = strdup( strtok( NULL, "" ) );
                    mpw_free_string( typeAndVersionAndCounter );
                }
                siteLoginName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteContent = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            default: {
                *error = (MPMarshallError){ MPMarshallErrorFormat, mpw_str( "Unexpected import format: %u", format ) };
                return NULL;
            }
        }

        if (siteName && str_type && str_counter && str_algorithm && str_uses && str_lastUsed) {
            MPResultType siteType = (MPResultType)atoi( str_type );
            if (!mpw_nameForType( siteType )) {
                *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site type: %s: %s", siteName, str_type ) };
                return NULL;
            }
            long long int value = atoll( str_counter );
            if (value < MPCounterValueFirst || value > MPCounterValueLast) {
                *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site counter: %s: %s", siteName, str_counter ) };
                return NULL;
            }
            MPCounterValue siteCounter = (MPCounterValue)value;
            value = atoll( str_algorithm );
            if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site algorithm: %s: %s", siteName, str_algorithm ) };
                return NULL;
            }
            MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
            time_t siteLastUsed = mpw_mktime( str_lastUsed );
            if (!siteLastUsed) {
                *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site last used: %s: %s", siteName, str_lastUsed ) };
                return NULL;
            }

            MPMarshalledSite *site = mpw_marshall_site(
                    user, siteName, siteType, siteCounter, siteAlgorithm );
            if (!site) {
                *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't allocate a new site." };
                return NULL;
            }

            site->loginName = siteLoginName? strdup( siteLoginName ): NULL;
            site->uses = (unsigned int)atoi( str_uses );
            site->lastUsed = siteLastUsed;
            if (siteContent && strlen( siteContent )) {
                if (!user->redacted) {
                    // Clear Text
                    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, fullName, masterPassword )) {
                        *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
                        return NULL;
                    }

                    site->content = mpw_siteState( masterKey, site->name, site->counter,
                            MPKeyPurposeAuthentication, NULL, site->type, siteContent, site->algorithm );
                }
                else
                    // Redacted
                    site->content = strdup( siteContent );
            }
        }
        else {
            error->type = MPMarshallErrorMissing;
            error->description = mpw_str(
                    "Missing one of: lastUsed=%s, uses=%s, type=%s, version=%s, counter=%s, loginName=%s, siteName=%s",
                    str_lastUsed, str_uses, str_type, str_algorithm, str_counter, siteLoginName, siteName );
            return NULL;
        }

        mpw_free_string( str_lastUsed );
        mpw_free_string( str_uses );
        mpw_free_string( str_type );
        mpw_free_string( str_algorithm );
        mpw_free_string( str_counter );
        mpw_free_string( siteLoginName );
        mpw_free_string( siteName );
        mpw_free_string( siteContent );
    }
    mpw_free_string( fullName );
    mpw_free_string( keyID );
    mpw_free( masterKey, MPMasterKeySize );

    *error = (MPMarshallError){ .type = MPMarshallSuccess };
    return user;
}

static MPMarshalledUser *mpw_marshall_read_json(
        char *in, const char *masterPassword, MPMarshallError *error) {

    *error = (MPMarshallError){ MPMarshallErrorInternal, "Unexpected internal error." };

    // Parse JSON.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (!json_file || json_error != json_tokener_success) {
        *error = (MPMarshallError){ MPMarshallErrorStructure, mpw_str( "JSON error: %s", json_tokener_error_desc( json_error ) ) };
        return NULL;
    }

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPAlgorithmVersion masterKeyAlgorithm = (MPAlgorithmVersion)-1;
    MPMarshalledUser *user = NULL;

    // Section: "export"
    int64_t fileFormat = mpw_get_json_int( json_file, "export.format", 0 );
    if (fileFormat < 1) {
        *error = (MPMarshallError){ MPMarshallErrorFormat, mpw_str( "Unsupported format: %u", fileFormat ) };
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
        *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid user algorithm version: %u", value ) };
        return NULL;
    }
    MPAlgorithmVersion algorithm = (MPAlgorithmVersion)value;
    MPResultType defaultType = (MPResultType)mpw_get_json_int( json_file, "user.default_type", MPResultTypeDefault );
    if (!mpw_nameForType( defaultType )) {
        *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid user default type: %u", defaultType ) };
        return NULL;
    }
    time_t lastUsed = mpw_mktime( str_lastUsed );
    if (!lastUsed) {
        *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid user last used: %s", str_lastUsed ) };
        return NULL;
    }
    if (!fullName || !strlen( fullName )) {
        *error = (MPMarshallError){ MPMarshallErrorMissing, "Missing value for full name." };
        return NULL;
    }
    if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, algorithm, fullName, masterPassword )) {
        *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
        return NULL;
    }
    if (keyID && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
        *error = (MPMarshallError){ MPMarshallErrorMasterPassword, "Master password doesn't match key ID." };
        return NULL;
    }
    if (!(user = mpw_marshall_user( fullName, masterPassword, algorithm ))) {
        *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't allocate a new user." };
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
            *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site algorithm version: %s: %d", siteName, value ) };
            return NULL;
        }
        MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
        MPResultType siteType = (MPResultType)mpw_get_json_int( json_site.val, "type", (int32_t)user->defaultType );
        if (!mpw_nameForType( siteType )) {
            *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site type: %s: %u", siteName, siteType ) };
            return NULL;
        }
        value = mpw_get_json_int( json_site.val, "counter", 1 );
        if (value < MPCounterValueFirst || value > MPCounterValueLast) {
            *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site counter: %s: %d", siteName, value ) };
            return NULL;
        }
        MPCounterValue siteCounter = (MPCounterValue)value;
        const char *siteContent = mpw_get_json_string( json_site.val, "password", NULL );
        const char *siteLoginName = mpw_get_json_string( json_site.val, "login_name", NULL );
        bool siteLoginGenerated = mpw_get_json_boolean( json_site.val, "login_generated", false );
        unsigned int siteUses = (unsigned int)mpw_get_json_int( json_site.val, "uses", 0 );
        str_lastUsed = mpw_get_json_string( json_site.val, "last_used", NULL );
        time_t siteLastUsed = mpw_mktime( str_lastUsed );
        if (!siteLastUsed) {
            *error = (MPMarshallError){ MPMarshallErrorIllegal, mpw_str( "Invalid site last used: %s: %s", siteName, str_lastUsed ) };
            return NULL;
        }

        json_object *json_site_mpw = mpw_get_json_section( json_site.val, "_ext_mpw" );
        const char *siteURL = mpw_get_json_string( json_site_mpw, "url", NULL );

        MPMarshalledSite *site = mpw_marshall_site( user, siteName, siteType, siteCounter, siteAlgorithm );
        if (!site) {
            *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't allocate a new site." };
            return NULL;
        }

        site->loginName = siteLoginName? strdup( siteLoginName ): NULL;
        site->loginGenerated = siteLoginGenerated;
        site->url = siteURL? strdup( siteURL ): NULL;
        site->uses = siteUses;
        site->lastUsed = siteLastUsed;
        if (siteContent && strlen( siteContent )) {
            if (!user->redacted) {
                // Clear Text
                if (!mpw_update_masterKey( &masterKey, &masterKeyAlgorithm, site->algorithm, fullName, masterPassword )) {
                    *error = (MPMarshallError){ MPMarshallErrorInternal, "Couldn't derive master key." };
                    return NULL;
                }

                site->content = mpw_siteState( masterKey, site->name, site->counter,
                        MPKeyPurposeAuthentication, NULL, site->type, siteContent, site->algorithm );
            }
            else
                // Redacted
                site->content = strdup( siteContent );
        }

        json_object_iter json_site_question;
        json_object *json_site_questions = mpw_get_json_section( json_site.val, "questions" );
        json_object_object_foreachC( json_site_questions, json_site_question )
            mpw_marshal_question( site, json_site_question.key );
    }
    json_object_put( json_file );

    *error = (MPMarshallError){ .type = MPMarshallSuccess };
    return user;
}

MPMarshalledUser *mpw_marshall_read(
        char *in, const MPMarshallFormat inFormat, const char *masterPassword, MPMarshallError *error) {

    switch (inFormat) {
        case MPMarshallFormatFlat:
            return mpw_marshall_read_flat( in, masterPassword, error );
        case MPMarshallFormatJSON:
            return mpw_marshall_read_json( in, masterPassword, error );
        default:
            *error = (MPMarshallError){ MPMarshallErrorFormat, mpw_str( "Unsupported input format: %u", inFormat ) };
            return NULL;
    }
}

const MPMarshallFormat mpw_formatWithName(
        const char *formatName) {

    // Lower-case to standardize it.
    size_t stdFormatNameSize = strlen( formatName );
    char stdFormatName[stdFormatNameSize + 1];
    for (size_t c = 0; c < stdFormatNameSize; ++c)
        stdFormatName[c] = (char)tolower( formatName[c] );
    stdFormatName[stdFormatNameSize] = '\0';

    if (strncmp( mpw_nameForFormat( MPMarshallFormatFlat ), stdFormatName, strlen( stdFormatName ) ) == 0)
        return MPMarshallFormatFlat;
    if (strncmp( mpw_nameForFormat( MPMarshallFormatJSON ), stdFormatName, strlen( stdFormatName ) ) == 0)
        return MPMarshallFormatJSON;

    dbg( "Not a format name: %s\n", stdFormatName );
    return (MPMarshallFormat)ERR;
}

const char *mpw_nameForFormat(
        const MPMarshallFormat format) {

    switch (format) {
        case MPMarshallFormatFlat:
            return "flat";
        case MPMarshallFormatJSON:
            return "json";
        default: {
            dbg( "Unknown format: %d\n", format );
            return NULL;
        }
    }
}

const char *mpw_marshall_format_extension(
        const MPMarshallFormat format) {

    switch (format) {
        case MPMarshallFormatFlat:
            return "mpsites";
        case MPMarshallFormatJSON:
            return "mpsites.json";
        default: {
            dbg( "Unknown format: %d\n", format );
            return NULL;
        }
    }
}
