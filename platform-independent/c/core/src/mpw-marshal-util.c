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

#include "mpw-marshal-util.h"
#include "mpw-util.h"

MP_LIBS_BEGIN
#include <string.h>
#include <math.h>
MP_LIBS_END

char *mpw_get_token(const char **in, const char *eol, const char *delim) {

    // Skip leading spaces.
    for (; **in == ' '; ++*in);

    // Find characters up to the first delim.
    size_t len = strcspn( *in, delim );
    char *token = len <= (size_t)(eol - *in)? mpw_strndup( *in, len ): NULL;

    // Advance past the delimitor.
    *in = min( eol, *in + len + 1 );
    return token;
}

bool mpw_get_bool(const char *in) {

    return in && (in[0] == 'y' || in[0] == 't' || strtol( in, NULL, 10 ) > 0);
}

time_t mpw_timegm(const char *time) {

    // TODO: Support for parsing non-UTC time strings
    // Parse time as a UTC timestamp, into a tm.
    struct tm tm = { .tm_isdst = -1 };
    if (time && sscanf( time, "%4d-%2d-%2dT%2d:%2d:%2dZ",
            &tm.tm_year, &tm.tm_mon, &tm.tm_mday,
            &tm.tm_hour, &tm.tm_min, &tm.tm_sec ) == 6) {
        tm.tm_year -= 1900; // tm_year 0 = rfc3339 year  1900
        tm.tm_mon -= 1;     // tm_mon  0 = rfc3339 month 1

        // mktime interprets tm as being local, we need to offset back to UTC (timegm/tm_gmtoff are non-standard).
        time_t local_time = mktime( &tm ), local_dst = tm.tm_isdst > 0? 3600: 0;
        time_t gmtoff = local_time + local_dst - mktime( gmtime( &local_time ) );
        return local_time + gmtoff;
    }

    return ERR;
}

bool mpw_update_master_key(MPMasterKey *masterKey, MPAlgorithmVersion *masterKeyAlgorithm, const MPAlgorithmVersion targetKeyAlgorithm,
        const char *fullName, const char *masterPassword) {

    if (masterKey && (!*masterKey || *masterKeyAlgorithm != targetKeyAlgorithm)) {
        mpw_free( masterKey, MPMasterKeySize );
        *masterKeyAlgorithm = targetKeyAlgorithm;
        *masterKey = mpw_master_key( fullName, masterPassword, *masterKeyAlgorithm );
    }

    return masterKey && *masterKey != NULL;
}

#if MPW_JSON

json_object *mpw_get_json_object(
        json_object *obj, const char *key, const bool create) {

    if (!obj)
        return NULL;

    json_object *json_value = NULL;
    if (!json_object_object_get_ex( obj, key, &json_value ) || !json_value)
        if (!create || json_object_object_add( obj, key, json_value = json_object_new_object() ) != OK) {
            trc( "Missing value for: %s", key );
            json_value = NULL;
        }

    return json_value;
}

const char *mpw_get_json_string(
        json_object *obj, const char *key, const char *defaultValue) {

    json_object *json_value = mpw_get_json_object( obj, key, false );
    if (!json_value)
        return defaultValue;

    return json_object_get_string( json_value );
}

int64_t mpw_get_json_int(
        json_object *obj, const char *key, const int64_t defaultValue) {

    json_object *json_value = mpw_get_json_object( obj, key, false );
    if (!json_value)
        return defaultValue;

    return json_object_get_int64( json_value );
}

bool mpw_get_json_boolean(
        json_object *obj, const char *key, const bool defaultValue) {

    json_object *json_value = mpw_get_json_object( obj, key, false );
    if (!json_value)
        return defaultValue;

    return json_object_get_boolean( json_value ) == true;
}

static bool mpw_marshal_data_keep_keyed(MPMarshalledData *child, void *args) {
    return child->obj_key != NULL;
}

static bool mpw_marshal_data_keep_unkeyed(MPMarshalledData *child, void *args) {
    return child->obj_key == NULL;
}

void mpw_set_json_data(
        MPMarshalledData *data, json_object *obj) {

    if (!data)
        return;

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
    if (type != json_type_object && type != json_type_array) {
        mpw_marshal_data_keep( data, mpw_marshal_data_keep_none, NULL );
    } else if (type == json_type_array) {
        mpw_marshal_data_keep( data, mpw_marshal_data_keep_unkeyed, NULL );
    } else /* type == json_type_object */ {
        mpw_marshal_data_keep( data, mpw_marshal_data_keep_keyed, NULL );
    }

    // Object
    if (type == json_type_object) {
        json_object_iter entry;
        json_object_object_foreachC( obj, entry ) {
            MPMarshalledData *child = NULL;

            // Find existing child.
            for (size_t c = 0; c < data->children_count; ++c)
                if (data->children[c].obj_key == entry.key ||
                    (data->children[c].obj_key && entry.key && strcmp( data->children[c].obj_key, entry.key ) == OK)) {
                    child = &data->children[c];
                    break;
                }

            // Create new child.
            if (!child) {
                if (!mpw_realloc( &data->children, NULL, sizeof( MPMarshalledData ) * ++data->children_count )) {
                    --data->children_count;
                    continue;
                }
                *(child = &data->children[data->children_count - 1]) = (MPMarshalledData){ .obj_key = mpw_strdup( entry.key ) };
                mpw_marshal_data_set_null( child, NULL );
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
                *(child = &data->children[data->children_count - 1]) = (MPMarshalledData){ .arr_index = index };
                mpw_marshal_data_set_null( child, NULL );
            }

            mpw_set_json_data( child, json_object_array_get_idx( obj, index ) );
        }
    }
}

#endif
