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

static MPMasterKey __mpw_masterKeyProvider_currentKey = NULL;
static MPAlgorithmVersion __mpw_masterKeyProvider_currentAlgorithm = (MPAlgorithmVersion)-1;
static MPMasterKeyProviderProxy __mpw_masterKeyProvider_currentProxy = NULL;
static const char *__mpw_masterKeyProvider_currentPassword = NULL;

static bool __mpw_masterKeyProvider_str(MPMasterKey *currentKey, MPAlgorithmVersion *currentAlgorithm,
        MPAlgorithmVersion algorithm, const char *fullName) {

    if (!currentKey)
        return mpw_free_string( &__mpw_masterKeyProvider_currentPassword );

    return mpw_update_master_key( currentKey, currentAlgorithm, algorithm, fullName, __mpw_masterKeyProvider_currentPassword );
}

static MPMasterKey __mpw_masterKeyProvider_proxy(MPAlgorithmVersion algorithm, const char *fullName) {

    if (!__mpw_masterKeyProvider_currentProxy)
        return NULL;
    if (!__mpw_masterKeyProvider_currentProxy(
            &__mpw_masterKeyProvider_currentKey, &__mpw_masterKeyProvider_currentAlgorithm, algorithm, fullName ))
        return NULL;

    return mpw_memdup( __mpw_masterKeyProvider_currentKey, MPMasterKeySize );
}

MPMasterKeyProvider mpw_masterKeyProvider_str(const char *masterPassword) {

    mpw_masterKeyProvider_free();
    __mpw_masterKeyProvider_currentPassword = mpw_strdup( masterPassword );
    return mpw_masterKeyProvider_proxy( __mpw_masterKeyProvider_str );
}

MPMasterKeyProvider mpw_masterKeyProvider_proxy(const MPMasterKeyProviderProxy proxy) {

    mpw_masterKeyProvider_free();
    __mpw_masterKeyProvider_currentProxy = proxy;
    return __mpw_masterKeyProvider_proxy;
}

void mpw_masterKeyProvider_free() {

    mpw_free( &__mpw_masterKeyProvider_currentKey, MPMasterKeySize );
    __mpw_masterKeyProvider_currentAlgorithm = (MPAlgorithmVersion)-1;
    if (__mpw_masterKeyProvider_currentProxy) {
        __mpw_masterKeyProvider_currentProxy( NULL, NULL, MPAlgorithmVersionCurrent, NULL );
        __mpw_masterKeyProvider_currentProxy = NULL;
    }
}

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
        MPMarshalledFile *file, MPMarshalledInfo *info, MPMarshalledData *data) {

    if (!file) {
        if (!(file = malloc( sizeof( MPMarshalledFile ) )))
            return NULL;

        *file = (MPMarshalledFile){ .info = NULL, .data = NULL, .error = (MPMarshalError){ .type = MPMarshalSuccess, .message = NULL } };
    }

    if (data && data != file->data) {
        mpw_marshal_data_free( &file->data );
        file->data = data;
    }
    if (info && info != file->info) {
        mpw_marshal_info_free( &file->info );
        file->info = info;
    }

    return file;
}

MPMarshalledFile *mpw_marshal_error(
        MPMarshalledFile *file, MPMarshalErrorType type, const char *format, ...) {

    file = mpw_marshal_file( file, NULL, NULL );
    if (!file)
        return NULL;

    va_list args;
    va_start( args, format );
    file->error = (MPMarshalError){ type, mpw_strdup( mpw_vstr( format, args ) ) };
    va_end( args );

    return file;
}

void mpw_marshal_info_free(
        MPMarshalledInfo **info) {

    if (!info || !*info)
        return;

    mpw_free_strings( &(*info)->fullName, &(*info)->keyID, NULL );
    mpw_free( info, sizeof( MPMarshalledInfo ) );
}

void mpw_marshal_user_free(
        MPMarshalledUser **user) {

    if (!user || !*user)
        return;

    mpw_free_strings( &(*user)->fullName, &(*user)->keyID, NULL );

    for (size_t s = 0; s < (*user)->sites_count; ++s) {
        MPMarshalledSite *site = &(*user)->sites[s];
        mpw_free_strings( &site->siteName, &site->resultState, &site->loginState, &site->url, NULL );

        for (size_t q = 0; q < site->questions_count; ++q) {
            MPMarshalledQuestion *question = &site->questions[q];
            mpw_free_strings( &question->keyword, &question->state, NULL );
        }
        mpw_free( &site->questions, sizeof( MPMarshalledQuestion ) * site->questions_count );
    }

    mpw_free( &(*user)->sites, sizeof( MPMarshalledSite ) * (*user)->sites_count );
    mpw_free( user, sizeof( MPMarshalledUser ) );
}

void mpw_marshal_data_free(
        MPMarshalledData **data) {

    if (!data || !*data)
        return;

    mpw_marshal_data_set_null( *data, NULL );
    mpw_free_string( &(*data)->obj_key );
    mpw_free( data, sizeof( MPMarshalledData ) );
}

void mpw_marshal_file_free(
        MPMarshalledFile **file) {

    if (!file || !*file)
        return;

    mpw_marshal_info_free( &(*file)->info );
    mpw_marshal_data_free( &(*file)->data );
    mpw_free_string( &(*file)->error.message );
    mpw_free( file, sizeof( MPMarshalledFile ) );
}

MPMarshalledData *mpw_marshal_data_new() {

    MPMarshalledData *data = malloc( sizeof( MPMarshalledData ) );
    *data = (MPMarshalledData){ 0 };
    mpw_marshal_data_set_null( data, NULL );
    data->is_null = false;
    return data;
}

MPMarshalledData *mpw_marshal_data_vget(
        MPMarshalledData *data, va_list nodes) {

    MPMarshalledData *parent = data, *child = parent;
    for (const char *node; parent && (node = va_arg( nodes, const char * )); parent = child) {
        child = NULL;

        for (size_t c = 0; c < parent->children_count; ++c) {
            const char *key = parent->children[c].obj_key;
            if (key && strcmp( node, key ) == OK) {
                child = &parent->children[c];
                break;
            }
        }

        if (!child) {
            if (!mpw_realloc( &parent->children, NULL, sizeof( MPMarshalledData ) * ++parent->children_count )) {
                --parent->children_count;
                break;
            }
            *(child = &parent->children[parent->children_count - 1]) = (MPMarshalledData){ .obj_key = mpw_strdup( node ) };
            mpw_marshal_data_set_null( child, NULL );
            child->is_null = false;
        }
    }

    return child;
}

MPMarshalledData *mpw_marshal_data_get(
        MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    MPMarshalledData *child = mpw_marshal_data_vget( data, nodes );
    va_end( nodes );

    return child;
}

const MPMarshalledData *mpw_marshal_data_vfind(
        const MPMarshalledData *data, va_list nodes) {

    const MPMarshalledData *parent = data, *child = parent;
    for (const char *node; parent && (node = va_arg( nodes, const char * )); parent = child) {
        child = NULL;

        for (size_t c = 0; c < parent->children_count; ++c) {
            const char *key = parent->children[c].obj_key;
            if (key && strcmp( node, key ) == OK) {
                child = &parent->children[c];
                break;
            }
        }

        if (!child)
            break;
    }

    return child;
}

const MPMarshalledData *mpw_marshal_data_find(
        const MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    const MPMarshalledData *child = mpw_marshal_data_vfind( data, nodes );
    va_end( nodes );

    return child;
}

bool mpw_marshal_data_vis_null(
        const MPMarshalledData *data, va_list nodes) {

    const MPMarshalledData *child = mpw_marshal_data_vfind( data, nodes );
    return !child || child->is_null;
}

bool mpw_marshal_data_is_null(
        const MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    bool value = mpw_marshal_data_vis_null( data, nodes );
    va_end( nodes );

    return value;
}

bool mpw_marshal_data_vset_null(
        MPMarshalledData *data, va_list nodes) {

    MPMarshalledData *child = mpw_marshal_data_vget( data, nodes );
    if (!child)
        return false;

    mpw_free_string( &child->str_value );
    for (unsigned int c = 0; c < child->children_count; ++c) {
        mpw_marshal_data_set_null( &child->children[c], NULL );
        mpw_free_string( &child->children[c].obj_key );
    }
    mpw_free( &child->children, sizeof( MPMarshalledData ) * child->children_count );
    child->children_count = 0;
    child->num_value = NAN;
    child->is_bool = false;
    child->is_null = true;
    return true;
}

bool mpw_marshal_data_set_null(
        MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    bool success = mpw_marshal_data_vset_null( data, nodes );
    va_end( nodes );

    return success;
}

bool mpw_marshal_data_vget_bool(
        const MPMarshalledData *data, va_list nodes) {

    const MPMarshalledData *child = mpw_marshal_data_vfind( data, nodes );
    return child && child->is_bool && child->num_value != false;
}

bool mpw_marshal_data_get_bool(
        const MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    bool value = mpw_marshal_data_vget_bool( data, nodes );
    va_end( nodes );

    return value;
}

bool mpw_marshal_data_vset_bool(
        const bool value, MPMarshalledData *data, va_list nodes) {

    MPMarshalledData *child = mpw_marshal_data_vget( data, nodes );
    if (!child || !mpw_marshal_data_set_null( child, NULL ))
        return false;

    child->is_null = false;
    child->is_bool = true;
    child->num_value = value != false;
    return true;
}

bool mpw_marshal_data_set_bool(
        const bool value, MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    bool success = mpw_marshal_data_vset_bool( value, data, nodes );
    va_end( nodes );

    return success;
}

double mpw_marshal_data_vget_num(
        const MPMarshalledData *data, va_list nodes) {

    const MPMarshalledData *child = mpw_marshal_data_vfind( data, nodes );
    return child == NULL? NAN: child->num_value;
}

double mpw_marshal_data_get_num(
        const MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    double value = mpw_marshal_data_vget_num( data, nodes );
    va_end( nodes );

    return value;
}

bool mpw_marshal_data_vset_num(
        const double value, MPMarshalledData *data, va_list nodes) {

    MPMarshalledData *child = mpw_marshal_data_vget( data, nodes );
    if (!child || !mpw_marshal_data_set_null( child, NULL ))
        return false;

    child->is_null = false;
    child->num_value = value;
    child->str_value = mpw_strdup( mpw_str( "%g", value ) );
    return true;
}

bool mpw_marshal_data_set_num(
        const double value, MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    bool success = mpw_marshal_data_vset_num( value, data, nodes );
    va_end( nodes );

    return success;
}

const char *mpw_marshal_data_vget_str(
        const MPMarshalledData *data, va_list nodes) {

    const MPMarshalledData *child = mpw_marshal_data_vfind( data, nodes );
    return child == NULL? NULL: child->str_value;
}

const char *mpw_marshal_data_get_str(
        const MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    const char *value = mpw_marshal_data_vget_str( data, nodes );
    va_end( nodes );

    return value;
}

bool mpw_marshal_data_vset_str(
        const char *value, MPMarshalledData *data, va_list nodes) {

    MPMarshalledData *child = mpw_marshal_data_vget( data, nodes );
    if (!child || !mpw_marshal_data_set_null( child, NULL ))
        return false;

    if (value) {
        child->is_null = false;
        child->str_value = mpw_strdup( value );
    }

    return true;
}

bool mpw_marshal_data_set_str(
        const char *value, MPMarshalledData *data, ...) {

    va_list nodes;
    va_start( nodes, data );
    bool success = mpw_marshal_data_vset_str( value, data, nodes );
    va_end( nodes );

    return success;
}

void mpw_marshal_data_keep(
        MPMarshalledData *data, bool (*filter)(MPMarshalledData *, void *), void *args) {

    size_t children_count = 0;
    MPMarshalledData *children = NULL;

    for (size_t c = 0; c < data->children_count; ++c) {
        MPMarshalledData *child = &data->children[c];
        if (filter( child, args )) {
            // Valid child in this object, keep it.
            ++children_count;

            if (children) {
                if (!mpw_realloc( &children, NULL, sizeof( MPMarshalledData ) * children_count )) {
                    --children_count;
                    continue;
                }
                child->arr_index = children_count - 1;
                children[child->arr_index] = *child;
            }
        }
        else {
            // Not a valid child in this object, remove it.
            mpw_marshal_data_set_null( child, NULL );
            mpw_free_string( &child->obj_key );

            if (!children)
                children = mpw_memdup( data->children, sizeof( MPMarshalledData ) * children_count );
        }
    }

    if (children) {
        mpw_free( &data->children, sizeof( MPMarshalledData ) * data->children_count );
        data->children = children;
        data->children_count = children_count;
    }
}

bool mpw_marshal_data_keep_none(
        MPMarshalledData *child, void *args) {

    return false;
}

static const char *mpw_marshal_write_flat(
        MPMarshalledFile *file) {

    const MPMarshalledData *data = file->data;
    if (!data) {
        mpw_marshal_error( file, MPMarshalErrorMissing, "Missing data." );
        return NULL;
    }

    char *out = NULL;
    mpw_string_pushf( &out, "# Master Password site export\n" );
    mpw_string_pushf( &out, mpw_marshal_data_get_bool( data, "export", "redacted", NULL )?
                            "#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n":
                            "#     Export of site names and passwords in clear-text.\n" );
    mpw_string_pushf( &out, "# \n" );
    mpw_string_pushf( &out, "##\n" );
    mpw_string_pushf( &out, "# Format: %d\n", 1 );

    mpw_string_pushf( &out, "# Date: %s\n", mpw_default( "", mpw_marshal_data_get_str( data, "export", "date", NULL ) ) );
    mpw_string_pushf( &out, "# User Name: %s\n", mpw_default( "", mpw_marshal_data_get_str( data, "user", "full_name", NULL ) ) );
    mpw_string_pushf( &out, "# Full Name: %s\n", mpw_default( "", mpw_marshal_data_get_str( data, "user", "full_name", NULL ) ) );
    mpw_string_pushf( &out, "# Avatar: %u\n", (unsigned int)mpw_marshal_data_get_num( data, "user", "avatar", NULL ) );
    mpw_string_pushf( &out, "# Identicon: %s\n", mpw_default( "", mpw_marshal_data_get_str( data, "user", "identicon", NULL ) ) );
    mpw_string_pushf( &out, "# Key ID: %s\n", mpw_default( "", mpw_marshal_data_get_str( data, "user", "key_id", NULL ) ) );
    mpw_string_pushf( &out, "# Algorithm: %d\n", (MPAlgorithmVersion)mpw_marshal_data_get_num( data, "user", "algorithm", NULL ) );
    mpw_string_pushf( &out, "# Default Type: %d\n", (MPResultType)mpw_marshal_data_get_num( data, "user", "default_type", NULL ) );
    mpw_string_pushf( &out, "# Passwords: %s\n", mpw_marshal_data_get_bool( data, "export", "redacted", NULL )? "PROTECTED": "VISIBLE" );
    mpw_string_pushf( &out, "##\n" );
    mpw_string_pushf( &out, "#\n" );
    mpw_string_pushf( &out, "#               Last     Times  Password                      Login\t                     Site\tSite\n" );
    mpw_string_pushf( &out, "#               used      used      type                       name\t                     name\tpassword\n" );

    // Sites.
    const MPMarshalledData *sites = mpw_marshal_data_find( data, "sites", NULL );
    for (size_t s = 0; s < (sites? sites->children_count: 0); ++s) {
        const MPMarshalledData *site = &sites->children[s];
        mpw_string_pushf( &out, "%s  %8ld  %8s  %25s\t%25s\t%s\n",
                mpw_default( "", mpw_marshal_data_get_str( site, "last_used", NULL ) ),
                (long)mpw_marshal_data_get_num( site, "uses", NULL ),
                mpw_str( "%lu:%lu:%lu",
                        (long)mpw_marshal_data_get_num( site, "type", NULL ),
                        (long)mpw_marshal_data_get_num( site, "algorithm", NULL ),
                        (long)mpw_marshal_data_get_num( site, "counter", NULL ) ),
                mpw_default( "", mpw_marshal_data_get_str( site, "login_name", NULL ) ),
                site->obj_key,
                mpw_default( "", mpw_marshal_data_get_str( site, "password", NULL ) ) );
    }

    if (!out)
        mpw_marshal_error( file, MPMarshalErrorFormat, "Couldn't encode JSON." );
    else
        mpw_marshal_error( file, MPMarshalSuccess, NULL );

    return out;
}

#if MPW_JSON

static json_object *mpw_get_json_data(
        const MPMarshalledData *data) {

    if (!data || data->is_null)
        return NULL;
    if (data->is_bool)
        return json_object_new_boolean( data->num_value != false );
    if (!isnan( data->num_value )) {
        if (data->str_value)
            return json_object_new_double_s( data->num_value, data->str_value );
        else
            return json_object_new_double( data->num_value );
    }
    if (data->str_value)
        return json_object_new_string( data->str_value );

    json_object *obj = NULL;
    for (size_t c = 0; c < data->children_count; ++c) {
        MPMarshalledData *child = &data->children[c];
        if (!obj) {
            if (child->obj_key)
                obj = json_object_new_object();
            else
                obj = json_object_new_array();
        }

        json_object *child_obj = mpw_get_json_data( child );
        if (json_object_is_type( obj, json_type_array ))
            json_object_array_add( obj, child_obj );
        else if (child_obj && !(json_object_is_type( child_obj, json_type_object ) && json_object_object_length( child_obj ) == 0))
            // We omit keys that map to null or empty object values.
            json_object_object_add( obj, child->obj_key, child_obj );
        else
            json_object_put( child_obj );
    }

    return obj;
}

static const char *mpw_marshal_write_json(
        MPMarshalledFile *file) {

    // Section: "export"
    json_object *json_file = mpw_get_json_data( file->data );
    if (!json_file) {
        mpw_marshal_error( file, MPMarshalErrorFormat, "Couldn't serialize export data." );
        return NULL;
    }

    json_object *json_export = mpw_get_json_object( json_file, "export", true );
    json_object_object_add( json_export, "format", json_object_new_int( 1 ) );

    // Section "sites"
    const char *out = mpw_strdup( json_object_to_json_string_ext( json_file,
            JSON_C_TO_STRING_PRETTY | JSON_C_TO_STRING_SPACED | JSON_C_TO_STRING_NOSLASHESCAPE ) );
    json_object_put( json_file );

    if (!out)
        mpw_marshal_error( file, MPMarshalErrorFormat, "Couldn't encode JSON." );
    else
        mpw_marshal_error( file, MPMarshalSuccess, NULL );

    return out;
}

#endif

static bool mpw_marshal_data_keep_site_exists(
        MPMarshalledData *child, void *args) {

    MPMarshalledUser *user = args;

    for (size_t s = 0; s < user->sites_count; ++s) {
        if (strcmp( (&user->sites[s])->siteName, child->obj_key ) == OK)
            return true;
    }

    return false;
}

static bool mpw_marshal_data_keep_question_exists(
        MPMarshalledData *child, void *args) {

    MPMarshalledSite *site = args;

    for (size_t s = 0; s < site->questions_count; ++s) {
        if (strcmp( (&site->questions[s])->keyword, child->obj_key ) == OK)
            return true;
    }

    return false;
}

const char *mpw_marshal_write(
        const MPMarshalFormat outFormat, MPMarshalledFile **file_, MPMarshalledUser *user) {

    MPMarshalledFile *file = file_? *file_: NULL;
    file = mpw_marshal_file( file, NULL, file && file->data? file->data: mpw_marshal_data_new() );
    if (file_)
        *file_ = file;
    if (!file)
        return NULL;
    if (!file->data) {
        if (!file_)
            mpw_marshal_file_free( &file );
        else
            mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't allocate data." );
        return NULL;
    }
    if (!user->fullName || !strlen( user->fullName )) {
        if (!file_)
            mpw_marshal_file_free( &file );
        else
            mpw_marshal_error( file, MPMarshalErrorMissing, "Missing full name." );
        return NULL;
    }
    mpw_marshal_error( file, MPMarshalSuccess, NULL );

    MPMasterKey masterKey = NULL;
    if (user->masterKeyProvider)
        masterKey = user->masterKeyProvider( user->algorithm, user->fullName );

    // Section: "export"
    MPMarshalledData *data_export = mpw_marshal_data_get( file->data, "export", NULL );
    char dateString[21];
    time_t now = time( NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &now ) ))
        mpw_marshal_data_set_str( dateString, data_export, "date", NULL );
    mpw_marshal_data_set_bool( user->redacted, data_export, "redacted", NULL );

    // Section: "user"
    MPMarshalledData *data_user = mpw_marshal_data_get( file->data, "user", NULL );
    mpw_marshal_data_set_num( user->avatar, data_user, "avatar", NULL );
    mpw_marshal_data_set_str( user->fullName, data_user, "full_name", NULL );
    mpw_marshal_data_set_str( mpw_identicon_encode( user->identicon ), data_user, "identicon", NULL );
    mpw_marshal_data_set_num( user->algorithm, data_user, "algorithm", NULL );
    mpw_marshal_data_set_str( user->keyID, data_user, "key_id", NULL );
    mpw_marshal_data_set_num( user->defaultType, data_user, "default_type", NULL );
    if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &user->lastUsed ) ))
        mpw_marshal_data_set_str( dateString, data_user, "last_used", NULL );

    // Section "sites"
    MPMarshalledData *data_sites = mpw_marshal_data_get( file->data, "sites", NULL );
    mpw_marshal_data_keep( data_sites, mpw_marshal_data_keep_site_exists, user );
    for (size_t s = 0; s < user->sites_count; ++s) {
        MPMarshalledSite *site = &user->sites[s];
        if (!site->siteName || !strlen( site->siteName ))
            continue;

        const char *resultState = NULL, *loginState = NULL;
        if (!user->redacted) {
            // Clear Text
            mpw_free( &masterKey, MPMasterKeySize );
            if (!user->masterKeyProvider || !(masterKey = user->masterKeyProvider( site->algorithm, user->fullName ))) {
                if (!file_)
                    mpw_marshal_file_free( &file );
                else
                    mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't derive master key." );
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

        mpw_marshal_data_set_num( site->counter, data_sites, site->siteName, "counter", NULL );
        mpw_marshal_data_set_num( site->algorithm, data_sites, site->siteName, "algorithm", NULL );
        mpw_marshal_data_set_num( site->resultType, data_sites, site->siteName, "type", NULL );
        mpw_marshal_data_set_str( resultState, data_sites, site->siteName, "password", NULL );
        mpw_marshal_data_set_num( site->loginType, data_sites, site->siteName, "login_type", NULL );
        mpw_marshal_data_set_str( loginState, data_sites, site->siteName, "login_name", NULL );
        mpw_marshal_data_set_num( site->uses, data_sites, site->siteName, "uses", NULL );
        if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &site->lastUsed ) ))
            mpw_marshal_data_set_str( dateString, data_sites, site->siteName, "last_used", NULL );

        MPMarshalledData *data_questions = mpw_marshal_data_get( file->data, "sites", site->siteName, "questions", NULL );
        mpw_marshal_data_keep( data_questions, mpw_marshal_data_keep_question_exists, site );
        for (size_t q = 0; q < site->questions_count; ++q) {
            MPMarshalledQuestion *question = &site->questions[q];
            if (!question->keyword)
                continue;

            const char *answer = NULL;
            if (user->redacted) {
                // Redacted
                if (question->state && strlen( question->state ) && site->resultType & MPSiteFeatureExportContent)
                    answer = mpw_strdup( question->state );
            }
            else {
                // Clear Text
                answer = mpw_site_result( masterKey, site->siteName, MPCounterValueInitial,
                        MPKeyPurposeRecovery, question->keyword, question->type, question->state, site->algorithm );
            }

            mpw_marshal_data_set_num( question->type, data_questions, question->keyword, "type", NULL );
            mpw_marshal_data_set_str( answer, data_questions, question->keyword, "answer", NULL );
            mpw_free_strings( &answer, NULL );
        }

        mpw_marshal_data_set_str( site->url, data_sites, site->siteName, "_ext_mpw", "url", NULL );
        mpw_free_strings( &resultState, &loginState, NULL );
    }

    const char *out = NULL;
    switch (outFormat) {
        case MPMarshalFormatNone:
            mpw_marshal_error( file, MPMarshalSuccess, NULL );
            break;
        case MPMarshalFormatFlat:
            out = mpw_marshal_write_flat( file );
            break;
#if MPW_JSON
        case MPMarshalFormatJSON:
            out = mpw_marshal_write_json( file );
            break;
#endif
        default:
            mpw_marshal_error( file, MPMarshalErrorFormat, "Unsupported output format: %u", outFormat );
            break;
    }
    if (out && file->error.type == MPMarshalSuccess)
        file = mpw_marshal_read( file, out );
    if (file_)
        *file_ = file;
    else
        mpw_marshal_file_free( &file );

    return out;
}

static void mpw_marshal_read_flat(
        MPMarshalledFile *file, const char *in) {

    if (!file)
        return;

    mpw_marshal_file( file, NULL, mpw_marshal_data_new() );
    if (!file->data) {
        mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't allocate data." );
        return;
    }

    // Parse import data.
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

                char dateString[21];
                if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &exportDate ) )) {
                    mpw_marshal_data_set_str( dateString, file->data, "export", "date", NULL );
                    mpw_marshal_data_set_str( dateString, file->data, "user", "last_used", NULL );
                }
                mpw_marshal_data_set_num( algorithm, file->data, "user", "algorithm", NULL );
                mpw_marshal_data_set_bool( importRedacted, file->data, "export", "redacted", NULL );
                mpw_marshal_data_set_num( avatar, file->data, "user", "avatar", NULL );
                mpw_marshal_data_set_str( fullName, file->data, "user", "full_name", NULL );
                mpw_marshal_data_set_str( mpw_identicon_encode( identicon ), file->data, "user", "identicon", NULL );
                mpw_marshal_data_set_str( keyID, file->data, "user", "key_id", NULL );
                mpw_marshal_data_set_num( defaultType, file->data, "user", "default_type", NULL );
                continue;
            }

            // Header
            const char *line = positionInLine;
            const char *headerName = mpw_get_token( &positionInLine, endOfLine, ":\n" );
            const char *headerValue = mpw_get_token( &positionInLine, endOfLine, "\n" );
            if (!headerName || !headerValue) {
                mpw_marshal_error( file, MPMarshalErrorStructure, "Invalid header: %s", mpw_strndup( line, (size_t)(endOfLine - line) ) );
                mpw_free_strings( &headerName, &headerValue, NULL );
                continue;
            }

            if (mpw_strcasecmp( headerName, "Format" ) == OK)
                format = (unsigned int)strtoul( headerValue, NULL, 10 );
            if (mpw_strcasecmp( headerName, "Date" ) == OK)
                exportDate = mpw_timegm( headerValue );
            if (mpw_strcasecmp( headerName, "Passwords" ) == OK)
                importRedacted = mpw_strcasecmp( headerValue, "VISIBLE" ) != OK;
            if (mpw_strcasecmp( headerName, "Algorithm" ) == OK) {
                unsigned long value = strtoul( headerValue, NULL, 10 );
                if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast)
                    mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid user algorithm version: %s", headerValue );
                else
                    algorithm = (MPAlgorithmVersion)value;
            }
            if (mpw_strcasecmp( headerName, "Avatar" ) == OK)
                avatar = (unsigned int)strtoul( headerValue, NULL, 10 );
            if (mpw_strcasecmp( headerName, "Full Name" ) == OK || mpw_strcasecmp( headerName, "User Name" ) == OK)
                fullName = mpw_strdup( headerValue );
            if (mpw_strcasecmp( headerName, "Identicon" ) == OK)
                identicon = mpw_identicon_encoded( headerValue );
            if (mpw_strcasecmp( headerName, "Key ID" ) == OK)
                keyID = mpw_strdup( headerValue );
            if (mpw_strcasecmp( headerName, "Default Type" ) == OK) {
                unsigned long value = strtoul( headerValue, NULL, 10 );
                if (!mpw_type_short_name( (MPResultType)value ))
                    mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid user default type: %s", headerValue );
                else
                    defaultType = (MPResultType)value;
            }

            mpw_free_strings( &headerName, &headerValue, NULL );
            continue;
        }
        if (!headerEnded)
            continue;
        if (!fullName)
            mpw_marshal_error( file, MPMarshalErrorMissing, "Missing header: Full Name" );
        if (positionInLine >= endOfLine)
            continue;

        // Site
        const char *siteName = NULL, *siteResultState = NULL, *siteLoginState = NULL;
        const char *str_lastUsed = NULL, *str_uses = NULL, *str_type = NULL, *str_algorithm = NULL, *str_counter = NULL;
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
                mpw_marshal_error( file, MPMarshalErrorFormat, "Unexpected import format: %u", format );
                continue;
            }
        }

        if (siteName && str_type && str_counter && str_algorithm && str_uses && str_lastUsed) {
            MPResultType siteType = (MPResultType)strtoul( str_type, NULL, 10 );
            if (!mpw_type_short_name( siteType )) {
                mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site type: %s: %s", siteName, str_type );
                continue;
            }
            long long int value = strtoll( str_counter, NULL, 10 );
            if (value < MPCounterValueFirst || value > MPCounterValueLast) {
                mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site counter: %s: %s", siteName, str_counter );
                continue;
            }
            MPCounterValue siteCounter = (MPCounterValue)value;
            value = strtoll( str_algorithm, NULL, 0 );
            if (value < MPAlgorithmVersionFirst || value > MPAlgorithmVersionLast) {
                mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site algorithm: %s: %s", siteName, str_algorithm );
                continue;
            }
            MPAlgorithmVersion siteAlgorithm = (MPAlgorithmVersion)value;
            time_t siteLastUsed = mpw_timegm( str_lastUsed );
            if (!siteLastUsed) {
                mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site last used: %s: %s", siteName, str_lastUsed );
                continue;
            }

            char dateString[21];
            mpw_marshal_data_set_num( siteCounter, file->data, "sites", siteName, "counter", NULL );
            mpw_marshal_data_set_num( siteAlgorithm, file->data, "sites", siteName, "algorithm", NULL );
            mpw_marshal_data_set_num( siteType, file->data, "sites", siteName, "type", NULL );
            mpw_marshal_data_set_str( siteResultState, file->data, "sites", siteName, "password", NULL );
            mpw_marshal_data_set_num( MPResultTypeDefault, file->data, "sites", siteName, "login_type", NULL );
            mpw_marshal_data_set_str( siteLoginState, file->data, "sites", siteName, "login_name", NULL );
            mpw_marshal_data_set_num( strtol( str_uses, NULL, 10 ), file->data, "sites", siteName, "uses", NULL );
            if (strftime( dateString, sizeof( dateString ), "%FT%TZ", gmtime( &siteLastUsed ) ))
                mpw_marshal_data_set_str( dateString, file->data, "sites", siteName, "last_used", NULL );
        }
        else {
            mpw_marshal_error( file, MPMarshalErrorMissing,
                    "Missing one of: lastUsed=%s, uses=%s, type=%s, version=%s, counter=%s, loginName=%s, siteName=%s",
                    str_lastUsed, str_uses, str_type, str_algorithm, str_counter, siteLoginState, siteName );
            continue;
        }

        mpw_free_strings( &str_lastUsed, &str_uses, &str_type, &str_algorithm, &str_counter, NULL );
        mpw_free_strings( &siteLoginState, &siteName, &siteResultState, NULL );
    }
    mpw_free_strings( &fullName, &keyID, NULL );
}

#if MPW_JSON

static void mpw_marshal_read_json(
        MPMarshalledFile *file, const char *in) {

    if (!file)
        return;

    mpw_marshal_file( file, NULL, mpw_marshal_data_new() );
    if (!file->data) {
        mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't allocate data." );
        return;
    }

    // Parse import data.
    enum json_tokener_error json_error = json_tokener_success;
    json_object *json_file = json_tokener_parse_verbose( in, &json_error );
    if (!json_file || json_error != json_tokener_success) {
        mpw_marshal_error( file, MPMarshalErrorFormat, "Couldn't parse JSON: %s", json_tokener_error_desc( json_error ) );
        return;
    }

    mpw_set_json_data( file->data, json_file );
    json_object_put( json_file );

    // mpw_marshal_data_get_num( data, "export", "format", NULL ) == 1

    return;
}

#endif

MPMarshalledFile *mpw_marshal_read(
        MPMarshalledFile *file, const char *in) {

    MPMarshalledInfo *info = malloc( sizeof( MPMarshalledInfo ) );
    file = mpw_marshal_file( file, info, NULL );
    if (!file)
        return NULL;

    mpw_marshal_error( file, MPMarshalSuccess, NULL );
    if (!info) {
        mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't allocate info." );
        return file;
    }

    *info = (MPMarshalledInfo){ .format = MPMarshalFormatNone, .identicon = MPIdenticonUnset };
    if (in && strlen( in )) {
        if (in[0] == '#') {
            info->format = MPMarshalFormatFlat;
            mpw_marshal_read_flat( file, in );
        }
        else if (in[0] == '{') {
            info->format = MPMarshalFormatJSON;
#if MPW_JSON
            mpw_marshal_read_json( file, in );
#else
            mpw_marshal_error( file, MPMarshalErrorFormat, "JSON support is not enabled." );
#endif
        }
    }

    // Section: "export"
    info->exportDate = mpw_timegm( mpw_strdup( mpw_marshal_data_get_str( file->data, "export", "date", NULL ) ) );
    info->redacted = mpw_marshal_data_get_bool( file->data, "export", "redacted", NULL )
                     || mpw_marshal_data_is_null( file->data, "export", "redacted", NULL );

    // Section: "user"
    info->algorithm = mpw_default_n( MPAlgorithmVersionCurrent, mpw_marshal_data_get_num( file->data, "user", "algorithm", NULL ) );
    info->avatar = mpw_default_n( 0U, mpw_marshal_data_get_num( file->data, "user", "avatar", NULL ) );
    info->fullName = mpw_strdup( mpw_marshal_data_get_str( file->data, "user", "full_name", NULL ) );
    info->identicon = mpw_identicon_encoded( mpw_marshal_data_get_str( file->data, "user", "identicon", NULL ) );
    info->keyID = mpw_strdup( mpw_marshal_data_get_str( file->data, "user", "key_id", NULL ) );
    info->lastUsed = mpw_timegm( mpw_marshal_data_get_str( file->data, "user", "last_used", NULL ) );

    return file;
}

MPMarshalledUser *mpw_marshal_auth(
        MPMarshalledFile *file, const MPMasterKeyProvider masterKeyProvider) {

    if (!file)
        return NULL;

    mpw_marshal_error( file, MPMarshalSuccess, NULL );
    if (!file->info) {
        mpw_marshal_error( file, MPMarshalErrorMissing, "File wasn't parsed yet." );
        return NULL;
    }
    if (!file->data) {
        mpw_marshal_error( file, MPMarshalErrorMissing, "No input data." );
        return NULL;
    }

    // Section: "user"
    bool fileRedacted = mpw_marshal_data_get_bool( file->data, "export", "redacted", NULL )
                        || mpw_marshal_data_is_null( file->data, "export", "redacted", NULL );
    MPAlgorithmVersion algorithm =
            mpw_default_n( MPAlgorithmVersionCurrent, mpw_marshal_data_get_num( file->data, "user", "algorithm", NULL ) );
    if (algorithm < MPAlgorithmVersionFirst || algorithm > MPAlgorithmVersionLast) {
        mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid user algorithm: %u", algorithm );
        return NULL;
    }
    unsigned int avatar = mpw_default_n( 0U, mpw_marshal_data_get_num( file->data, "user", "avatar", NULL ) );
    const char *fullName = mpw_marshal_data_get_str( file->data, "user", "full_name", NULL );
    if (!fullName || !strlen( fullName )) {
        mpw_marshal_error( file, MPMarshalErrorMissing, "Missing value for full name." );
        return NULL;
    }
    MPIdenticon identicon = mpw_identicon_encoded( mpw_marshal_data_get_str( file->data, "user", "identicon", NULL ) );
    const char *keyID = mpw_marshal_data_get_str( file->data, "user", "key_id", NULL );
    MPResultType defaultType = mpw_default_n( MPResultTypeDefault, mpw_marshal_data_get_num( file->data, "user", "default_type", NULL ) );
    if (!mpw_type_short_name( defaultType )) {
        mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid user default type: %u", defaultType );
        return NULL;
    }
    const char *str_lastUsed = mpw_marshal_data_get_str( file->data, "user", "last_used", NULL );
    time_t lastUsed = mpw_timegm( str_lastUsed );
    if (!lastUsed) {
        mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid user last used: %s", str_lastUsed );
        return NULL;
    }

    MPMasterKey masterKey = NULL;
    if (masterKeyProvider && !(masterKey = masterKeyProvider( algorithm, fullName ))) {
        mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't derive master key." );
        return NULL;
    }
    if (keyID && masterKey && !mpw_id_buf_equals( keyID, mpw_id_buf( masterKey, MPMasterKeySize ) )) {
        mpw_marshal_error( file, MPMarshalErrorMasterPassword, "Master key doesn't match key ID." );
        mpw_free( &masterKey, MPMasterKeySize );
        return NULL;
    }

    MPMarshalledUser *user = NULL;
    if (!(user = mpw_marshal_user( fullName, masterKeyProvider, algorithm ))) {
        mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't allocate a new user." );
        mpw_free( &masterKey, MPMasterKeySize );
        mpw_marshal_user_free( &user );
        return NULL;
    }

    user->redacted = fileRedacted;
    user->avatar = avatar;
    user->identicon = identicon;
    user->keyID = mpw_strdup( keyID );
    user->defaultType = defaultType;
    user->lastUsed = lastUsed;

    // Section "sites"
    const MPMarshalledData *sites = mpw_marshal_data_find( file->data, "sites", NULL );
    for (size_t s = 0; s < (sites? sites->children_count: 0); ++s) {
        const MPMarshalledData *siteData = &sites->children[s];
        const char *siteName = siteData->obj_key;

        algorithm = mpw_default_n( user->algorithm, mpw_marshal_data_get_num( siteData, "algorithm", NULL ) );
        if (algorithm < MPAlgorithmVersionFirst || algorithm > MPAlgorithmVersionLast) {
            mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site algorithm: %s: %u", siteName, algorithm );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }
        MPCounterValue siteCounter = mpw_default_n( MPCounterValueDefault, mpw_marshal_data_get_num( siteData, "counter", NULL ) );
        if (siteCounter < MPCounterValueFirst || siteCounter > MPCounterValueLast) {
            mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site counter: %s: %d", siteName, siteCounter );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }
        MPResultType siteType = mpw_default_n( user->defaultType, mpw_marshal_data_get_num( siteData, "type", NULL ) );
        if (!mpw_type_short_name( siteType )) {
            mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site type: %s: %u", siteName, siteType );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }
        const char *siteResultState = mpw_marshal_data_get_str( siteData, "password", NULL );
        MPResultType siteLoginType = mpw_default_n( MPResultTypeTemplateName, mpw_marshal_data_get_num( siteData, "login_type", NULL ) );
        if (!mpw_type_short_name( siteLoginType )) {
            mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site login type: %s: %u", siteName, siteLoginType );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }
        const char *siteLoginState = mpw_marshal_data_get_str( siteData, "login_name", NULL );
        unsigned int siteUses = mpw_default_n( 0U, mpw_marshal_data_get_num( siteData, "uses", NULL ) );
        str_lastUsed = mpw_marshal_data_get_str( siteData, "last_used", NULL );
        time_t siteLastUsed = mpw_timegm( str_lastUsed );
        if (!siteLastUsed) {
            mpw_marshal_error( file, MPMarshalErrorIllegal, "Invalid site last used: %s: %s", siteName, str_lastUsed );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
            return NULL;
        }

        const char *siteURL = mpw_marshal_data_get_str( siteData, "_ext_mpw", "url", NULL );

        MPMarshalledSite *site = mpw_marshal_site( user, siteName, siteType, siteCounter, algorithm );
        if (!site) {
            mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't allocate a new site." );
            mpw_free( &masterKey, MPMasterKeySize );
            mpw_marshal_user_free( &user );
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
                mpw_marshal_error( file, MPMarshalErrorInternal, "Couldn't derive master key." );
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

        const MPMarshalledData *questions = mpw_marshal_data_find( siteData, "questions", NULL );
        for (size_t q = 0; q < (questions? questions->children_count: 0); ++q) {
            const MPMarshalledData *questionData = &questions->children[q];
            MPMarshalledQuestion *question = mpw_marshal_question( site, questionData->obj_key );
            const char *answerState = mpw_marshal_data_get_str( questionData, "answer", NULL );
            question->type = mpw_default_n( MPResultTypeTemplatePhrase, mpw_marshal_data_get_num( questionData, "type", NULL ) );

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
    mpw_free( &masterKey, MPMasterKeySize );

    return user;
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

const char *mpw_format_extension(
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

const char **mpw_format_extensions(
        const MPMarshalFormat format, size_t *count) {

    *count = 0;
    switch (format) {
        case MPMarshalFormatNone:
            return NULL;
        case MPMarshalFormatFlat:
            return mpw_strings( count,
                    mpw_format_extension( format ), "mpsites.txt", "txt", NULL );
        case MPMarshalFormatJSON:
            return mpw_strings( count,
                    mpw_format_extension( format ), "mpsites.json", "json", NULL );
        default: {
            dbg( "Unknown format: %d", format );
            return NULL;
        }
    }
}
