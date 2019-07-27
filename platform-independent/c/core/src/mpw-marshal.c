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


#include "mpw-marshal.h"
#include "mpw-util.h"
#include "mpw-marshal-util.h"

MP_LIBS_BEGIN
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
MP_LIBS_END

MPMarshalledUser *mpw_marshal_user(
        const char *fullName, MPMasterKeyProvider masterKeyProvider, const MPAlgorithmVersion algorithmVersion) {

    MPMarshalledUser *user;
    if (!fullName || !(user = malloc( sizeof( MPMarshalledUser ) )))
        return NULL;

    *user = (MPMarshalledUser){
            .masterKeyProvider = masterKeyProvider,
            .algorithm = algorithmVersion,
            .redacted = true,

            .avatar = 0,
            .fullName = mpw_strdup( fullName ),
            .identicon = MPIdenticonUnset,
            .keyID = NULL,
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

    if (!siteName)
        return NULL;
    if (!mpw_realloc( &user->sites, NULL, sizeof( MPMarshalledSite ) * ++user->sites_count )) {
        user->sites_count--;
        return NULL;
    }

    MPMarshalledSite *site = &user->sites[user->sites_count - 1];
    *site = (MPMarshalledSite){
            .siteName = mpw_strdup( siteName ),
            .algorithm = algorithmVersion,
            .counter = siteCounter,

            .resultType = resultType,
            .resultState = NULL,

            .loginType = MPResultTypeTemplateName,
            .loginState = NULL,

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

    if (!mpw_realloc( &site->questions, NULL, sizeof( MPMarshalledQuestion ) * ++site->questions_count )) {
        site->questions_count--;
        return NULL;
    }
    if (!keyword)
        keyword = "";

    MPMarshalledQuestion *question = &site->questions[site->questions_count - 1];
    *question = (MPMarshalledQuestion){
            .keyword = mpw_strdup( keyword ),
            .type = MPResultTypeTemplatePhrase,
            .state = NULL,
    };
    return question;
}

MPMarshalledFile *mpw_marshal_file(
        MPMarshalledUser *user, MPMarshalledData *data) {

    MPMarshalledFile *file;
    if (!user || !(file = malloc( sizeof( MPMarshalledFile ) )))
        return NULL;

    *file = (MPMarshalledFile){
            .info = NULL,
            .user = user,
            .data = data,
    };
    return file;
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

static bool mpw_marshal_user_free(
        MPMarshalledUser **user) {

    if (!user || !*user)
        return true;

    bool success = mpw_free_strings( &(*user)->fullName, &(*user)->keyID, NULL );

    for (size_t s = 0; s < (*user)->sites_count; ++s) {
        MPMarshalledSite *site = &(*user)->sites[s];
        success &= mpw_free_strings( &site->siteName, &site->resultState, &site->loginState, &site->url, NULL );

        for (size_t q = 0; q < site->questions_count; ++q) {
            MPMarshalledQuestion *question = &site->questions[q];
            success &= mpw_free_strings( &question->keyword, &question->state, NULL );
        }
        success &= mpw_free( &site->questions, sizeof( MPMarshalledQuestion ) * site->questions_count );
    }

    success &= mpw_free( &(*user)->sites, sizeof( MPMarshalledSite ) * (*user)->sites_count );
    success &= mpw_free( user, sizeof( MPMarshalledUser ) );

    return success;
}

static bool mpw_marshal_data_null(
        MPMarshalledData *data) {

    if (!data)
        return true;

    bool success = mpw_free_strings( &data->key, &data->str_value, NULL );
    for (unsigned int c = 0; c < data->children_count; ++c)
        success &= mpw_marshal_data_null( &data->children[c] );
    success &= mpw_free( &data->children, sizeof( MPMarshalledData ) * data->children_count );
    data->children_count = 0;
    data->num_value = NAN;
    data->is_bool = false;
    data->is_null = true;

    return success;
}

bool mpw_marshal_free(
        MPMarshalledFile **file) {

    if (!file || !*file)
        return true;

    bool success = true;

    success &= mpw_marshal_info_free( &(*file)->info );
    success &= mpw_marshal_user_free( &(*file)->user );
    success &= mpw_marshal_data_null( (*file)->data );
    success &= mpw_free( &(*file)->data, sizeof( MPMarshalledData ) );
    success &= mpw_free( file, sizeof( MPMarshalledFile ) );

    return success;
}

static const char *mpw_marshal_write_flat(
        const MPMarshalledFile *file, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    MPMarshalledUser *user = file->user;
    if (!user) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing user." };
        return NULL;
    }
    if (!user->fullName || !strlen( user->fullName )) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing full name." };
        return NULL;
    }
    MPMasterKey masterKey = NULL;
    if (user->masterKeyProvider)
        masterKey = user->masterKeyProvider( user->algorithm, user->fullName );

    char *out = NULL;
    mpw_string_pushf( &out, "# Master Password site export\n" );
    if (user->redacted)
        mpw_string_pushf( &out,
                "#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n" );
    else
        mpw_string_pushf( &out, "#     Export of site names and passwords in clear-text.\n" );
    mpw_string_pushf( &out, "# \n" );
    mpw_string_pushf( &out, "##\n" );
    mpw_string_pushf( &out, "# Format: %d\n", 1 );

    char dateString[21];
    time_t now = time( NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &now ) ))
        mpw_string_pushf( &out, "# Date: %s\n", dateString );
    mpw_string_pushf( &out, "# User Name: %s\n", user->fullName );
    mpw_string_pushf( &out, "# Full Name: %s\n", user->fullName );
    mpw_string_pushf( &out, "# Avatar: %u\n", user->avatar );
    if (user->identicon.color != MPIdenticonColorUnset)
        mpw_string_pushf( &out, "# Identicon: %s\n", mpw_identicon_encode( user->identicon ) );
    if (user->keyID)
        mpw_string_pushf( &out, "# Key ID: %s\n", user->keyID );
    mpw_string_pushf( &out, "# Algorithm: %d\n", user->algorithm );
    if (user->defaultType)
        mpw_string_pushf( &out, "# Default Type: %d\n", user->defaultType );
    mpw_string_pushf( &out, "# Passwords: %s\n", user->redacted? "PROTECTED": "VISIBLE" );
    mpw_string_pushf( &out, "##\n" );
    mpw_string_pushf( &out, "#\n" );
    mpw_string_pushf( &out, "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
    mpw_string_pushf( &out, "#               used      used      type                       name\t                     name\tpassword\n" );

    // Sites.
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        if (!site->siteName || !strlen( site->siteName ))
            continue;

        const char *resultState = NULL, *loginState = NULL;
        if (!user->redacted) {
            // Clear Text
            mpw_free( &masterKey, MPMasterKeySize );
            if (!user->masterKeyProvider || !(masterKey = user->masterKeyProvider( site->algorithm, user->fullName ))) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                mpw_free_string( &out );
                return NULL;
            }

            resultState = mpw_site_result( masterKey, site->siteName, site->counter,
                    MPKeyPurposeAuthentication, NULL, site->resultType, site->resultState, site->algorithm );
            loginState = mpw_site_result( masterKey, site->siteName, MPCounterValueInitial,
                    MPKeyPurposeIdentification, NULL, site->loginType, site->loginState, site->algorithm );
        }
        else {
            // Redacted
            if (site->resultType & MPSiteFeatureExportContent && site->resultState && strlen( site->resultState ))
                resultState = mpw_strdup( site->resultState );
            if (site->loginType & MPSiteFeatureExportContent && site->loginState && strlen( site->loginState ))
                loginState = mpw_strdup( site->loginState );
        }

        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site->lastUsed ) ))
            mpw_string_pushf( &out, "%s  %8ld  %lu:%lu:%lu  %25s\t%25s\t%s\n",
                    dateString, (long)site->uses, (long)site->resultType, (long)site->algorithm, (long)site->counter,
                    loginState? loginState: "", site->siteName, resultState? resultState: "" );
        mpw_free_strings( &resultState, &loginState, NULL );
    }
    mpw_free( &masterKey, MPMasterKeySize );

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return out;
}

#if MPW_JSON

static json_object *mpw_get_json_data(
        MPMarshalledData *data) {

    if (!data || data->is_null)
        return NULL;
    if (data->is_bool)
        return json_object_new_boolean( data->num_value != false );
    if (!isnan( data->num_value ))
        return json_object_new_double_s( data->num_value, data->str_value );
    if (data->str_value)
        return json_object_new_string( data->str_value );

    json_object *obj = NULL;
    for (size_t index = 0; index < data->children_count; ++index) {
        MPMarshalledData *child = &data->children[index];
        if (!obj) {
            if (child->key)
                obj = json_object_new_object();
            else
                obj = json_object_new_array();
        }

        if (child->key)
            json_object_object_add( obj, child->key, mpw_get_json_data( child ) );
        else
            json_object_array_add( obj, mpw_get_json_data( child ) );
    }

    return obj;
}

static const char *mpw_marshal_write_json(
        const MPMarshalledFile *file, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    MPMarshalledUser *user = file->user;
    if (!user) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing user." };
        return NULL;
    }
    if (!user->fullName || !strlen( user->fullName )) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing full name." };
        return NULL;
    }
    MPMasterKey masterKey = NULL;
    if (user->masterKeyProvider)
        masterKey = user->masterKeyProvider( user->algorithm, user->fullName );

    // Section: "export"
    json_object *json_file = mpw_get_json_data( file->data );
    if (!json_file)
        json_file = json_object_new_object();
    json_object *json_export = mpw_get_json_object( json_file, "export", true );
    json_object_object_add( json_export, "format", json_object_new_int( 1 ) );
    json_object_object_add( json_export, "redacted", json_object_new_boolean( user->redacted ) );

    char dateString[21];
    time_t now = time( NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &now ) ))
        json_object_object_add( json_export, "date", json_object_new_string( dateString ) );

    // Section: "user"
    json_object *json_user = mpw_get_json_object( json_file, "user", true );
    json_object_object_add( json_user, "avatar", json_object_new_int( (int32_t)user->avatar ) );
    json_object_object_add( json_user, "full_name", json_object_new_string( user->fullName ) );

    if (user->identicon.color != MPIdenticonColorUnset)
        json_object_object_add( json_user, "identicon", json_object_new_string( mpw_identicon_encode( user->identicon ) ) );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &user->lastUsed ) ))
        json_object_object_add( json_user, "last_used", json_object_new_string( dateString ) );
    if (user->keyID)
        json_object_object_add( json_user, "key_id", json_object_new_string( user->keyID ) );
    json_object_object_add( json_user, "algorithm", json_object_new_int( (int32_t)user->algorithm ) );
    if (user->defaultType)
        json_object_object_add( json_user, "default_type", json_object_new_int( (int32_t)user->defaultType ) );

    // Section "sites"
    json_object *json_sites = mpw_get_json_object( json_file, "sites", true );
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        if (!site->siteName || !strlen( site->siteName ))
            continue;

        const char *resultState = NULL, *loginState = NULL;
        if (!user->redacted) {
            // Clear Text
            mpw_free( &masterKey, MPMasterKeySize );
            if (!user->masterKeyProvider || !(masterKey = user->masterKeyProvider( site->algorithm, user->fullName ))) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                json_object_put( json_file );
                return NULL;
            }

            resultState = mpw_site_result( masterKey, site->siteName, site->counter,
                    MPKeyPurposeAuthentication, NULL, site->resultType, site->resultState, site->algorithm );
            loginState = mpw_site_result( masterKey, site->siteName, MPCounterValueInitial,
                    MPKeyPurposeIdentification, NULL, site->loginType, site->loginState, site->algorithm );
        }
        else {
            // Redacted
            if (site->resultType & MPSiteFeatureExportContent && site->resultState && strlen( site->resultState ))
                resultState = mpw_strdup( site->resultState );
            if (site->loginType & MPSiteFeatureExportContent && site->loginState && strlen( site->loginState ))
                loginState = mpw_strdup( site->loginState );
        }

        json_object *json_site = mpw_get_json_object( json_sites, site->siteName, true );
        json_object_object_add( json_site, "type", json_object_new_int( (int32_t)site->resultType ) );
        json_object_object_add( json_site, "counter", json_object_new_int( (int32_t)site->counter ) );
        json_object_object_add( json_site, "algorithm", json_object_new_int( (int32_t)site->algorithm ) );
        if (resultState)
            json_object_object_add( json_site, "password", json_object_new_string( resultState ) );
        if (loginState)
            json_object_object_add( json_site, "login_name", json_object_new_string( loginState ) );
        json_object_object_add( json_site, "login_type", json_object_new_int( (int32_t)site->loginType ) );

        json_object_object_add( json_site, "uses", json_object_new_int( (int32_t)site->uses ) );
        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site->lastUsed ) ))
            json_object_object_add( json_site, "last_used", json_object_new_string( dateString ) );

        if (site->questions_count) {
            json_object *json_site_questions = mpw_get_json_object( json_site, "questions", true );
            for (size_t q = 0; q < site->questions_count; ++q) {
                MPMarshalledQuestion *question = &site->questions[q];
                if (!question->keyword)
                    continue;

                json_object *json_site_question = mpw_get_json_object( json_site_questions, question->keyword, true );
                json_object_object_add( json_site_question, "type", json_object_new_int( (int32_t)question->type ) );

                if (!user->redacted) {
                    // Clear Text
                    const char *answerState = mpw_site_result( masterKey, site->siteName, MPCounterValueInitial,
                            MPKeyPurposeRecovery, question->keyword, question->type, question->state, site->algorithm );
                    json_object_object_add( json_site_question, "answer", json_object_new_string( answerState ) );
                }
                else {
                    // Redacted
                    if (site->resultType & MPSiteFeatureExportContent && question->state && strlen( question->state ))
                        json_object_object_add( json_site_question, "answer", json_object_new_string( question->state ) );
                }
            }
        }

        json_object *json_site_mpw = mpw_get_json_object( json_site, "_ext_mpw", true );
        if (site->url)
            json_object_object_add( json_site_mpw, "url", json_object_new_string( site->url ) );
        if (!json_object_object_length( json_site_mpw ))
            json_object_object_del( json_site, "_ext_mpw" );

        mpw_free_strings( &resultState, &loginState, NULL );
    }

    const char *out = mpw_strdup( json_object_to_json_string_ext( json_file,
            JSON_C_TO_STRING_PRETTY | JSON_C_TO_STRING_SPACED | JSON_C_TO_STRING_NOSLASHESCAPE ) );
    json_object_put( json_file );
    mpw_free( &masterKey, MPMasterKeySize );

    if (out)
        *error = (MPMarshalError){ .type = MPMarshalSuccess };
    else
        *error = (MPMarshalError){ .type = MPMarshalErrorFormat, .message = "Couldn't encode JSON." };

    return out;
}

#endif

const char *mpw_marshal_write(
        const MPMarshalFormat outFormat, MPMarshalledFile *file, MPMarshalError *error) {

    const char *out = NULL;
    switch (outFormat) {
        case MPMarshalFormatNone:
            *error = (MPMarshalError){ .type = MPMarshalSuccess };
            break;
        case MPMarshalFormatFlat:
            out = mpw_marshal_write_flat( file, error );
            break;
#if MPW_JSON
        case MPMarshalFormatJSON:
            out = mpw_marshal_write_json( file, error );
            break;
#endif
        default:
            *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unsupported output format: %u", outFormat ) };
            break;
    }
    if (file) {
        mpw_marshal_info_free( &file->info );
        file->info = mpw_marshal_read_info( out );
    }

    return out;
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

            if (strcmp( headerName, "Date" ) == OK)
                info->exportDate = info->lastUsed = mpw_timegm( headerValue );
            if (strcmp( headerName, "Passwords" ) == OK)
                info->redacted = strcmp( headerValue, "VISIBLE" ) != OK;
            if (strcmp( headerName, "Algorithm" ) == OK)
                info->algorithm = (MPAlgorithmVersion)atoi( headerValue );
            if (strcmp( headerName, "Avatar" ) == OK)
                info->avatar = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Full Name" ) == OK || strcmp( headerName, "User Name" ) == OK)
                info->fullName = mpw_strdup( headerValue );
            if (strcmp( headerName, "Identicon" ) == OK)
                info->identicon = mpw_identicon_encoded( headerValue );
            if (strcmp( headerName, "Key ID" ) == OK)
                info->keyID = mpw_strdup( headerValue );

            mpw_free_strings( &headerName, &headerValue, NULL );
            continue;
        }
    }
}

static MPMarshalledFile *mpw_marshal_read_flat(
        const char *in, MPMasterKeyProvider masterKeyProvider, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    if (!in || !strlen( in )) {
        error->type = MPMarshalErrorStructure;
        error->message = mpw_str( "No input data." );
        return NULL;
    }

    // Parse import data.
    MPMasterKey masterKey = NULL;
    MPMarshalledUser *user = NULL;
    unsigned int format = 0, avatar = 0;
    char *fullName = NULL, *keyID = NULL;
    MPAlgorithmVersion algorithm = MPAlgorithmVersionCurrent;
    MPIdenticon identicon = MPIdenticonUnset;
    MPResultType defaultType = MPResultTypeDefault;
    time_t exportDate = 0;
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
                mpw_free( &masterKey, MPMasterKeySize );
                if (masterKeyProvider && !(masterKey = masterKeyProvider( algorithm, fullName ))) {
                    *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                    mpw_free_strings( &fullName, &keyID, NULL );
                    mpw_free( &masterKey, MPMasterKeySize );
                    mpw_marshal_user_free( &user );
                    return NULL;
                }
                if (keyID && masterKey && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
                    *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Master key doesn't match key ID." };
                    mpw_free_strings( &fullName, &keyID, NULL );
                    mpw_free( &masterKey, MPMasterKeySize );
                    mpw_marshal_user_free( &user );
                    return NULL;
                }

                mpw_marshal_user_free( &user );
                if (!(user = mpw_marshal_user( fullName, masterKeyProvider, algorithm ))) {
                    *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new user." };
                    mpw_free_strings( &fullName, &keyID, NULL );
                    mpw_free( &masterKey, MPMasterKeySize );
                    mpw_marshal_user_free( &user );
                    return NULL;
                }

                user->redacted = importRedacted;
                user->avatar = avatar;
                user->identicon = identicon;
                user->keyID = mpw_strdup( keyID );
                user->defaultType = defaultType;
                user->lastUsed = exportDate;
                continue;
            }

            // Header
            char *headerName = mpw_get_token( &positionInLine, endOfLine, ":\n" );
            char *headerValue = mpw_get_token( &positionInLine, endOfLine, "\n" );
            if (!headerName || !headerValue) {
                error->type = MPMarshalErrorStructure;
                error->message = mpw_str( "Invalid header: %s", mpw_strndup( positionInLine, (size_t)(endOfLine - positionInLine) ) );
                mpw_free_strings( &headerName, &headerValue, NULL );
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }

            if (strcmp( headerName, "Format" ) == OK)
                format = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Date" ) == OK)
                exportDate = mpw_timegm( headerValue );
            if (strcmp( headerName, "Passwords" ) == OK)
                importRedacted = strcmp( headerValue, "VISIBLE" ) != OK;
            if (strcmp( headerName, "Algorithm" ) == OK) {
                int value = atoi( headerValue );
                if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                    *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user algorithm version: %s", headerValue ) };
                    mpw_free_strings( &headerName, &headerValue, NULL );
                    mpw_free_strings( &fullName, &keyID, NULL );
                    mpw_free( &masterKey, MPMasterKeySize );
                    mpw_marshal_user_free( &user );
                    return NULL;
                }
                algorithm = (MPAlgorithmVersion)value;
            }
            if (strcmp( headerName, "Avatar" ) == OK)
                avatar = (unsigned int)atoi( headerValue );
            if (strcmp( headerName, "Full Name" ) == OK || strcmp( headerName, "User Name" ) == OK)
                fullName = mpw_strdup( headerValue );
            if (strcmp( headerName, "Identicon" ) == OK)
                identicon = mpw_identicon_encoded( headerValue );
            if (strcmp( headerName, "Key ID" ) == OK)
                keyID = mpw_strdup( headerValue );
            if (strcmp( headerName, "Default Type" ) == OK) {
                int value = atoi( headerValue );
                if (!mpw_type_short_name( (MPResultType)value )) {
                    *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user default type: %s", headerValue ) };
                    mpw_free_strings( &headerName, &headerValue, NULL );
                    mpw_free_strings( &fullName, &keyID, NULL );
                    mpw_free( &masterKey, MPMasterKeySize );
                    mpw_marshal_user_free( &user );
                    return NULL;
                }
                defaultType = (MPResultType)value;
            }

            mpw_free_strings( &headerName, &headerValue, NULL );
            continue;
        }
        if (!headerEnded)
            continue;
        if (!fullName) {
            *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing header: Full Name" };
            mpw_free_strings( &fullName, &keyID, NULL );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }
        if (positionInLine >= endOfLine)
            continue;

        // Site
        char *siteName = NULL, *siteResultState = NULL, *siteLoginState = NULL;
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
                str_counter = mpw_strdup( mpw_str( "%u", MPCounterValueDefault ) );
                siteLoginState = NULL;
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteResultState = mpw_get_token( &positionInLine, endOfLine, "\n" );
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
                siteLoginState = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteName = mpw_get_token( &positionInLine, endOfLine, "\t\n" );
                siteResultState = mpw_get_token( &positionInLine, endOfLine, "\n" );
                break;
            }
            default: {
                *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unexpected import format: %u", format ) };
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }
        }

        if (siteName && str_type && str_counter && str_algorithm && str_uses && str_lastUsed) {
            MPResultType siteType = (MPResultType)atoi( str_type );
            if (!mpw_type_short_name( siteType )) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site type: %s: %s", siteName, str_type ) };
                mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
                mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }
            long long int value = atoll( str_counter );
            if (value < MPCounterValueFirst || value > MPCounterValueLast) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site counter: %s: %s", siteName, str_counter ) };
                mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
                mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }
            MPCounterValue siteCounter = (MPCounterValue)value;
            value = atoll( str_algorithm );
            if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site algorithm: %s: %s", siteName, str_algorithm ) };
                mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
                mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }
            MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
            time_t siteLastUsed = mpw_timegm( str_lastUsed );
            if (!siteLastUsed) {
                *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site last used: %s: %s", siteName, str_lastUsed ) };
                mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
                mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }

            MPMarshalledSite *site = mpw_marshal_site( user, siteName, siteType, siteCounter, siteAlgorithm );
            if (!site) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new site." };
                mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
                mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
                mpw_free_strings( &fullName, &keyID, NULL );
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                return NULL;
            }

            site->uses = (unsigned int)atoi( str_uses );
            site->lastUsed = siteLastUsed;
            if (!user->redacted) {
                // Clear Text
                mpw_free( &masterKey, MPMasterKeySize );
                if (!masterKeyProvider || !(masterKey = masterKeyProvider( site->algorithm, user->fullName ))) {
                    *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                    mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
                    mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
                    mpw_free_strings( &fullName, &keyID, NULL );
                    mpw_free( &masterKey, MPMasterKeySize );
                    mpw_marshal_user_free( &user );
                    return NULL;
                }

                if (siteResultState && strlen( siteResultState ))
                    site->resultState = mpw_site_state( masterKey, site->siteName, site->counter,
                            MPKeyPurposeAuthentication, NULL, site->resultType, siteResultState, site->algorithm );
                if (siteLoginState && strlen( siteLoginState ))
                    site->loginState = mpw_site_state( masterKey, site->siteName, MPCounterValueInitial,
                            MPKeyPurposeIdentification, NULL, site->loginType, siteLoginState, site->algorithm );
            }
            else {
                // Redacted
                if (siteResultState && strlen( siteResultState ))
                    site->resultState = mpw_strdup( siteResultState );
                if (siteLoginState && strlen( siteLoginState ))
                    site->loginState = mpw_strdup( siteLoginState );
            }
        }
        else {
            error->type = MPMarshalErrorMissing;
            error->message = mpw_str(
                    "Missing one of: lastUsed=%s, uses=%s, type=%s, version=%s, counter=%s, loginName=%s, siteName=%s",
                    str_lastUsed, str_uses, str_type, str_algorithm, str_counter, siteLoginState, siteName );
            mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
            mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
            mpw_free_strings( &fullName, &keyID, NULL );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }

        mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
        mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
    }
    mpw_free_strings( &fullName, &keyID, NULL );
    mpw_free( &masterKey, MPMasterKeySize );

    MPMarshalledFile *file = mpw_marshal_file( user, NULL );
    if (!file) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new marshal file." };
        mpw_marshal_user_free( &user );
        return NULL;
    }

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return file;
}

#if MPW_JSON

static void mpw_set_json_data(
        MPMarshalledData *data, json_object *obj) {

    json_type type = json_object_get_type( obj );
    data->is_null = type == json_type_null;
    data->is_bool = type == json_type_boolean;

    if (type == json_type_boolean)
        data->num_value = json_object_get_boolean( obj );
    else if (type == json_type_double)
        data->num_value = json_object_get_double( obj );
    else if (type == json_type_int)
        data->num_value = json_object_get_int64( obj );
    else
        data->num_value = NAN;

    const char *str = NULL;
    if (type == json_type_string || !isnan( data->num_value ))
        str = json_object_get_string( obj );
    if (!str || !data->str_value || strcmp( str, data->str_value ) != OK) {
        mpw_free_string( &data->str_value );
        data->str_value = mpw_strdup( str );
    }

    // Clean up children
    MPMarshalledData *newChildren = NULL;
    size_t newChildrenCount = 0;
    for (size_t c = 0; c < data->children_count; ++c) {
        MPMarshalledData *child = &data->children[c];
        if ((type != json_type_object && type != json_type_array) ||
            (child->key && type != json_type_object) || (!isnan( child->index ) && type != json_type_array)) {
            mpw_marshal_data_null( child );
            if (!newChildren) {
                newChildren = malloc( sizeof( MPMarshalledData ) * newChildrenCount );
                if (newChildren)
                    memcpy( newChildren, data->children, sizeof( MPMarshalledData ) * newChildrenCount );
            }
        }
        else {
            ++newChildrenCount;
            if (newChildren) {
                if (!mpw_realloc( &newChildren, NULL, sizeof( MPMarshalledData ) * newChildrenCount )) {
                    --newChildrenCount;
                    continue;
                }
                child->index = newChildrenCount - 1;
                newChildren[child->index] = *child;
            }
        }
    }
    if (newChildren) {
        mpw_free( &data->children, sizeof( MPMarshalledData ) * data->children_count );
        data->children = newChildren;
        data->children_count = newChildrenCount;
    }

    // Object
    if (type == json_type_object) {
        json_object_iter entry;
        json_object_object_foreachC( obj, entry ) {
            MPMarshalledData *child = NULL;

            // Find existing child.
            for (size_t c = 0; c < data->children_count; ++c)
                if (data->children[c].key == entry.key ||
                    (data->children[c].key && entry.key && strcmp( data->children[c].key, entry.key )) == OK) {
                    child = &data->children[c];
                    break;
                }

            // Create new child.
            if (!child) {
                if (!mpw_realloc( &data->children, NULL, sizeof( MPMarshalledData ) * ++data->children_count )) {
                    --data->children_count;
                    continue;
                }
                *(child = &data->children[data->children_count - 1]) = (MPMarshalledData){ .key = mpw_strdup( entry.key ) };
            }

            mpw_set_json_data( child, entry.val );
        }
    }

    // Array
    if (type == json_type_array) {
        for (size_t index = 0; index < json_object_array_length( obj ); ++index) {
            MPMarshalledData *child = NULL;

            if (index < data->children_count)
                child = &data->children[index];

            else {
                if (!mpw_realloc( &data->children, NULL, sizeof( MPMarshalledData ) * ++data->children_count )) {
                    --data->children_count;
                    continue;
                }
                *(child = &data->children[data->children_count - 1]) = (MPMarshalledData){ .index = index };
            }

            mpw_set_json_data( child, json_object_array_get_idx( obj, index ) );
        }
    }
}

static void mpw_marshal_read_json_info(
        const char *in, MPMarshalInfo *info) {

    // Parse JSON.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (!json_file || json_error != json_tokener_success)
        return;

    // Section: "export"
    json_object *json_export = mpw_get_json_object( json_file, "export", false );
    int64_t fileFormat = mpw_get_json_int( json_export, "format", 0 );
    if (fileFormat < 1)
        return;
    info->exportDate = mpw_timegm( mpw_get_json_string( json_export, "date", NULL ) );
    info->redacted = mpw_get_json_boolean( json_export, "redacted", true );

    // Section: "user"
    json_object *json_user = mpw_get_json_object( json_file, "user", false );
    info->algorithm = (MPAlgorithmVersion)mpw_get_json_int( json_user, "algorithm", MPAlgorithmVersionCurrent );
    info->avatar = (unsigned int)mpw_get_json_int( json_user, "avatar", 0 );
    info->fullName = mpw_strdup( mpw_get_json_string( json_user, "full_name", NULL ) );
    info->identicon = mpw_identicon_encoded( mpw_get_json_string( json_user, "identicon", NULL ) );
    info->keyID = mpw_strdup( mpw_get_json_string( json_user, "key_id", NULL ) );
    info->lastUsed = mpw_timegm( mpw_get_json_string( json_user, "last_used", NULL ) );

    json_object_put( json_file );
}

static MPMarshalledFile *mpw_marshal_read_json(
        const char *in, MPMasterKeyProvider masterKeyProvider, MPMarshalError *error) {

    *error = (MPMarshalError){ MPMarshalErrorInternal, "Unexpected internal error." };
    if (!in || !strlen( in )) {
        error->type = MPMarshalErrorStructure;
        error->message = mpw_str( "No input data." );
        return NULL;
    }

    // Parse JSON.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (!json_file || json_error != json_tokener_success) {
        *error = (MPMarshalError){ MPMarshalErrorStructure, mpw_str( "JSON error: %s", json_tokener_error_desc( json_error ) ) };
        json_object_put( json_file );
        return NULL;
    }

    // Section: "export"
    json_object *json_export = mpw_get_json_object( json_file, "export", false );
    int64_t fileFormat = mpw_get_json_int( json_export, "format", 0 );
    if (fileFormat < 1) {
        *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unsupported format: %u", fileFormat ) };
        json_object_put( json_file );
        return NULL;
    }
    bool fileRedacted = mpw_get_json_boolean( json_export, "redacted", true );

    // Section: "user"
    json_object *json_user = mpw_get_json_object( json_file, "user", false );
    int64_t value = mpw_get_json_int( json_user, "algorithm", MPAlgorithmVersionCurrent );
    if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
        *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user algorithm version: %u", value ) };
        json_object_put( json_file );
        return NULL;
    }
    MPAlgorithmVersion algorithm = (MPAlgorithmVersion)value;
    unsigned int avatar = (unsigned int)mpw_get_json_int( json_user, "avatar", 0 );
    const char *fullName = mpw_get_json_string( json_user, "full_name", NULL );
    if (!fullName || !strlen( fullName )) {
        *error = (MPMarshalError){ MPMarshalErrorMissing, "Missing value for full name." };
        json_object_put( json_file );
        return NULL;
    }
    MPIdenticon identicon = mpw_identicon_encoded( mpw_get_json_string( json_user, "identicon", NULL ) );
    const char *keyID = mpw_get_json_string( json_user, "key_id", NULL );
    MPResultType defaultType = (MPResultType)mpw_get_json_int( json_user, "default_type", MPResultTypeDefault );
    if (!mpw_type_short_name( defaultType )) {
        *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user default type: %u", defaultType ) };
        json_object_put( json_file );
        return NULL;
    }
    const char *str_lastUsed = mpw_get_json_string( json_user, "last_used", NULL );
    time_t lastUsed = mpw_timegm( str_lastUsed );
    if (!lastUsed) {
        *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid user last used: %s", str_lastUsed ) };
        json_object_put( json_file );
        return NULL;
    }

    MPMasterKey masterKey = NULL;
    if (masterKeyProvider && !(masterKey = masterKeyProvider( algorithm, fullName ))) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
        mpw_free( &masterKey, MPMasterKeySize );
        json_object_put( json_file );
        return NULL;
    }
    if (keyID && masterKey && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
        *error = (MPMarshalError){ MPMarshalErrorMasterPassword, "Master key doesn't match key ID." };
        mpw_free( &masterKey, MPMasterKeySize );
        json_object_put( json_file );
        return NULL;
    }

    MPMarshalledUser *user = NULL;
    if (!(user = mpw_marshal_user( fullName, masterKeyProvider, algorithm ))) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new user." };
        mpw_free( &masterKey, MPMasterKeySize );
        mpw_marshal_user_free( &user );
        json_object_put( json_file );
        return NULL;
    }

    user->redacted = fileRedacted;
    user->avatar = avatar;
    user->identicon = identicon;
    user->keyID = mpw_strdup( keyID );
    user->defaultType = defaultType;
    user->lastUsed = lastUsed;

    // Section "sites"
    json_object_iter json_site;
    json_object *json_sites = mpw_get_json_object( json_file, "sites", false );
    json_object_object_foreachC( json_sites, json_site ) {
        const char *siteName = json_site.key;
        value = mpw_get_json_int( json_site.val, "algorithm", (int32_t)user->algorithm );
        if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site algorithm version: %s: %d", siteName, value ) };
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            json_object_put( json_file );
            return NULL;
        }
        MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
        value = mpw_get_json_int( json_site.val, "counter", MPCounterValueDefault );
        if (value < MPCounterValueFirst || value > MPCounterValueLast) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site counter: %s: %d", siteName, value ) };
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            json_object_put( json_file );
            return NULL;
        }
        MPCounterValue siteCounter = (MPCounterValue)value;
        MPResultType siteType = (MPResultType)mpw_get_json_int( json_site.val, "type", (int32_t)user->defaultType );
        if (!mpw_type_short_name( siteType )) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site type: %s: %u", siteName, siteType ) };
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            json_object_put( json_file );
            return NULL;
        }
        const char *siteResultState = mpw_get_json_string( json_site.val, "password", NULL );
        MPResultType siteLoginType = (MPResultType)mpw_get_json_int( json_site.val, "login_type", MPResultTypeTemplateName );
        if (!mpw_type_short_name( siteLoginType )) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site login type: %s: %u", siteName, siteLoginType ) };
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            json_object_put( json_file );
            return NULL;
        }
        const char *siteLoginState = mpw_get_json_string( json_site.val, "login_name", NULL );
        unsigned int siteUses = (unsigned int)mpw_get_json_int( json_site.val, "uses", 0 );
        str_lastUsed = mpw_get_json_string( json_site.val, "last_used", NULL );
        time_t siteLastUsed = mpw_timegm( str_lastUsed );
        if (!siteLastUsed) {
            *error = (MPMarshalError){ MPMarshalErrorIllegal, mpw_str( "Invalid site last used: %s: %s", siteName, str_lastUsed ) };
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            json_object_put( json_file );
            return NULL;
        }

        json_object *json_site_mpw = mpw_get_json_object( json_site.val, "_ext_mpw", false );
        const char *siteURL = mpw_get_json_string( json_site_mpw, "url", NULL );

        MPMarshalledSite *site = mpw_marshal_site( user, siteName, siteType, siteCounter, siteAlgorithm );
        if (!site) {
            *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new site." };
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            json_object_put( json_file );
            return NULL;
        }

        site->loginType = siteLoginType;
        site->url = siteURL? mpw_strdup( siteURL ): NULL;
        site->uses = siteUses;
        site->lastUsed = siteLastUsed;
        if (!user->redacted) {
            // Clear Text
            mpw_free( &masterKey, MPMasterKeySize );
            if (!masterKeyProvider || !(masterKey = masterKeyProvider( site->algorithm, user->fullName ))) {
                *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't derive master key." };
                mpw_free( &masterKey, MPMasterKeySize );
                mpw_marshal_user_free( &user );
                json_object_put( json_file );
                return NULL;
            }

            if (siteResultState && strlen( siteResultState ))
                site->resultState = mpw_site_state( masterKey, site->siteName, site->counter,
                        MPKeyPurposeAuthentication, NULL, site->resultType, siteResultState, site->algorithm );
            if (siteLoginState && strlen( siteLoginState ))
                site->loginState = mpw_site_state( masterKey, site->siteName, MPCounterValueInitial,
                        MPKeyPurposeIdentification, NULL, site->loginType, siteLoginState, site->algorithm );
        }
        else {
            // Redacted
            if (siteResultState && strlen( siteResultState ))
                site->resultState = mpw_strdup( siteResultState );
            if (siteLoginState && strlen( siteLoginState ))
                site->loginState = mpw_strdup( siteLoginState );
        }

        json_object *json_site_questions = mpw_get_json_object( json_site.val, "questions", false );
        if (json_site_questions) {
            json_object_iter json_site_question;
            json_object_object_foreachC( json_site_questions, json_site_question ) {
                MPMarshalledQuestion *question = mpw_marshal_question( site, json_site_question.key );
                const char *answerState = mpw_get_json_string( json_site_question.val, "answer", NULL );
                question->type = (MPResultType)mpw_get_json_int( json_site_question.val, "type", MPResultTypeTemplatePhrase );

                if (!user->redacted) {
                    // Clear Text
                    if (answerState && strlen( answerState ))
                        question->state = mpw_site_state( masterKey, site->siteName, MPCounterValueInitial,
                                MPKeyPurposeRecovery, question->keyword, question->type, answerState, site->algorithm );
                }
                else {
                    // Redacted
                    if (answerState && strlen( answerState ))
                        question->state = mpw_strdup( answerState );
                }
            }
        }
    }
    mpw_free( &masterKey, MPMasterKeySize );

    MPMarshalledData *data = malloc( sizeof( MPMarshalledData ) );
    if (data) {
        *data = (MPMarshalledData){};
        mpw_set_json_data( data, json_file );
    }
    json_object_put( json_file );

    MPMarshalledFile *file = mpw_marshal_file( user, data );
    if (!file) {
        *error = (MPMarshalError){ MPMarshalErrorInternal, "Couldn't allocate a new marshal file." };
        mpw_marshal_user_free( &user );
        return NULL;
    }

    *error = (MPMarshalError){ .type = MPMarshalSuccess };
    return file;
}

#endif

MPMarshalInfo *mpw_marshal_read_info(
        const char *in) {

    MPMarshalInfo *info = malloc( sizeof( MPMarshalInfo ) );
    if (!info)
        return NULL;

    *info = (MPMarshalInfo){ .format = MPMarshalFormatNone, .identicon = MPIdenticonUnset };
    if (in && strlen( in )) {
        if (in[0] == '#') {
            info->format = MPMarshalFormatFlat;
            mpw_marshal_read_flat_info( in, info );
        }
        else if (in[0] == '{') {
            info->format = MPMarshalFormatJSON;
#if MPW_JSON
            mpw_marshal_read_json_info( in, info );
#endif
        }
    }

    if (info->format == MPMarshalFormatNone) {
        mpw_marshal_info_free( &info );
        return NULL;
    }

    return info;
}

MPMarshalledFile *mpw_marshal_read(
        const char *in, MPMasterKeyProvider masterKeyProvider, MPMarshalError *error) {

    MPMarshalInfo *info = mpw_marshal_read_info( in );
    if (!info)
        return NULL;

    MPMarshalledFile *file = NULL;
    switch (info->format) {
        case MPMarshalFormatNone:
            *error = (MPMarshalError){ .type = MPMarshalSuccess };
            break;
        case MPMarshalFormatFlat:
            file = mpw_marshal_read_flat( in, masterKeyProvider, error );
            break;
#if MPW_JSON
        case MPMarshalFormatJSON:
            file = mpw_marshal_read_json( in, masterKeyProvider, error );
            break;
#endif
        default:
            *error = (MPMarshalError){ MPMarshalErrorFormat, mpw_str( "Unsupported input format: %u", info->format ) };
            break;
    }
    if (file) {
        mpw_marshal_info_free( &(file->info) );
        file->info = info;
    }

    return file;
}

const MPMarshalFormat mpw_format_named(
        const char *formatName) {

    if (!formatName || !strlen( formatName ))
        return MPMarshalFormatNone;

    if (mpw_strncasecmp( mpw_format_name( MPMarshalFormatNone ), formatName, strlen( formatName ) ) == OK)
        return MPMarshalFormatNone;
    if (mpw_strncasecmp( mpw_format_name( MPMarshalFormatFlat ), formatName, strlen( formatName ) ) == OK)
        return MPMarshalFormatFlat;
    if (mpw_strncasecmp( mpw_format_name( MPMarshalFormatJSON ), formatName, strlen( formatName ) ) == OK)
        return MPMarshalFormatJSON;

    dbg( "Not a format name: %s", formatName );
    return (MPMarshalFormat)ERR;
}

const char *mpw_format_name(
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
            return "mpjson";
        default: {
            dbg( "Unknown format: %d", format );
            return NULL;
        }
    }
}

const char **mpw_marshal_format_extensions(
        const MPMarshalFormat format, size_t *count) {

    *count = 0;
    switch (format) {
        case MPMarshalFormatNone:
            return NULL;
        case MPMarshalFormatFlat:
            return mpw_strings( count,
                    mpw_marshal_format_extension( format ), "mpsites.txt", "txt" );
        case MPMarshalFormatJSON:
            return mpw_strings( count,
                    mpw_marshal_format_extension( format ), "mpsites.json", "json" );
        default: {
            dbg( "Unknown format: %d", format );
            return NULL;
        }
    }
}
