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

#include <time.h>
#if MPW_JSON
#include "json-c/json.h"
#endif

#include "mpw-algorithm.h"

/// Type parsing.

/** Get a token from a string by searching until the first character in delim, no farther than eol.
  * The input string reference is advanced beyond the token delimitor if one is found.
  * @return A new string containing the token or NULL if the delim wasn't found before eol. */
char *mpw_get_token(
        const char **in, const char *eol, char *delim);
/** Convert an RFC 3339 time string into epoch time. */
time_t mpw_mktime(
        const char *time);

/// JSON parsing.

#if MPW_JSON
/** Search for a JSON child object in a JSON object tree.
  * @param section A dot-delimited list of JSON object keys to walk toward the child object.
  * @return A new JSON object or NULL if one of the section's object keys was not found in the source object's tree. */
json_object *mpw_get_json_section(
        json_object *obj, const char *section);
/** Search for a string in a JSON object tree.
  * @param section A dot-delimited list of JSON object keys to walk toward the child object.
  * @return A new string or defaultValue if one of the section's object keys was not found in the source object's tree. */
const char *mpw_get_json_string(
        json_object *obj, const char *section, const char *defaultValue);
/** Search for an integer in a JSON object tree.
  * @param section A dot-delimited list of JSON object keys to walk toward the child object.
  * @return The integer value or defaultValue if one of the section's object keys was not found in the source object's tree. */
int64_t mpw_get_json_int(
        json_object *obj, const char *section, int64_t defaultValue);
/** Search for a boolean in a JSON object tree.
  * @param section A dot-delimited list of JSON object keys to walk toward the child object.
  * @return The boolean value or defaultValue if one of the section's object keys was not found in the source object's tree. */
bool mpw_get_json_boolean(
        json_object *obj, const char *section, bool defaultValue);
#endif

/// mpw.

/** Calculate a master key if the target master key algorithm is different from the given master key algorithm.
  * @return false if an error occurred during the derivation of the master key. */
bool mpw_update_masterKey(
        MPMasterKey *masterKey, MPAlgorithmVersion *masterKeyAlgorithm, MPAlgorithmVersion targetKeyAlgorithm,
        const char *fullName, const char *masterPassword);

#endif // _MPW_MARSHAL_UTIL_H
