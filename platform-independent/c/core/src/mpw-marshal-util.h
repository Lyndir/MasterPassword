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

#ifndef _MPW_MARSHAL_UTIL_H
#define _MPW_MARSHAL_UTIL_H

#include "mpw-algorithm.h"
#include "mpw-marshal.h"

MP_LIBS_BEGIN
#include <time.h>
#if MPW_JSON
#include <json-c/json.h>
#endif
MP_LIBS_END

/// Type parsing.

/** Get a token from a string by searching until the first character in delim, no farther than eol.
 * The input string reference is advanced beyond the token delimitor if one is found.
 * @return A string (allocated) containing the token or NULL if the delim wasn't found before eol. */
char *mpw_get_token(
        const char **in, const char *eol, const char *delim);
/** Get a boolean value as expressed by the given string.
 * @return true if the string is not NULL and holds a number larger than 0, or starts with a t (for true) or y (for yes). */
bool mpw_get_bool(
        const char *in);
/** Convert an RFC 3339 time string into epoch time.
 * @return ERR if the string could not be parsed. */
time_t mpw_timegm(
        const char *time);


/// mpw.

/** Calculate a master key if the target master key algorithm is different from the given master key algorithm.
 * @param masterKey A buffer (allocated, MPMasterKeySize).
 * @return false if an error occurred during the derivation of the master key. */
bool mpw_update_master_key(
        MPMasterKey *masterKey, MPAlgorithmVersion *masterKeyAlgorithm, const MPAlgorithmVersion targetKeyAlgorithm,
        const char *fullName, const char *masterPassword);


/// JSON parsing.

#if MPW_JSON
/** Search for an object in a JSON object tree.
 * @param key A JSON object key for the child in this object.
 * @param create If true, create and insert new objects for any missing path components.
 * @return An object (shared) or a new object (shared) installed in the tree if the path's object path was not found. */
json_object *mpw_get_json_object(
        json_object *obj, const char *key, const bool create);
/** Search for a string in a JSON object tree.
 * @param key A dot-delimited list of JSON object keys to walk toward the child object.
 * @return A string (shared) or defaultValue if one of the path's object keys was not found in the source object's tree. */
const char *mpw_get_json_string(
        json_object *obj, const char *key, const char *defaultValue);
/** Search for an integer in a JSON object tree.
 * @param key A dot-delimited list of JSON object keys to walk toward the child object.
 * @return The integer value or defaultValue if one of the path's object keys was not found in the source object's tree. */
int64_t mpw_get_json_int(
        json_object *obj, const char *key, const int64_t defaultValue);
/** Search for a boolean in a JSON object tree.
 * @param key A dot-delimited list of JSON object keys to walk toward the child object.
 * @return The boolean value or defaultValue if one of the path's object keys was not found in the source object's tree. */
bool mpw_get_json_boolean(
        json_object *obj, const char *key, const bool defaultValue);
/** Translate a JSON object tree into a source-agnostic data object.
 * @param data A Master Password data object or NULL.
 * @param obj A JSON object tree or NULL. */
void mpw_set_json_data(
        MPMarshalledData *data, json_object *obj);
#endif

#endif // _MPW_MARSHAL_UTIL_H
