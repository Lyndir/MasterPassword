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

#ifndef _MPW_MARSHAL_H
#define _MPW_MARSHAL_H

#include "mpw-algorithm.h"

MP_LIBS_BEGIN
#include <time.h>
#include <stdarg.h>
MP_LIBS_END

//// Types.

typedef mpw_enum( unsigned int, MPMarshalFormat ) {
    /** Do not marshal. */
            MPMarshalFormatNone,
    /** Marshal using the line-based plain-text format. */
            MPMarshalFormatFlat,
    /** Marshal using the JSON structured format. */
            MPMarshalFormatJSON,

#if MPW_JSON
    MPMarshalFormatDefault = MPMarshalFormatJSON,
#else
    MPMarshalFormatDefault = MPMarshalFormatFlat,
#endif
    MPMarshalFormatFirst = MPMarshalFormatFlat,
    MPMarshalFormatLast = MPMarshalFormatJSON,
};

typedef mpw_enum( unsigned int, MPMarshalErrorType ) {
    /** The marshalling operation completed successfully. */
            MPMarshalSuccess,
    /** An error in the structure of the marshall file interrupted marshalling. */
            MPMarshalErrorStructure,
    /** The marshall file uses an unsupported format version. */
            MPMarshalErrorFormat,
    /** A required value is missing or not specified. */
            MPMarshalErrorMissing,
    /** The given master password is not valid. */
            MPMarshalErrorMasterPassword,
    /** An illegal value was specified. */
            MPMarshalErrorIllegal,
    /** An internal system error interrupted marshalling. */
            MPMarshalErrorInternal,
};

/** A function that can resolve a master key of the given algorithm for the user with the given name.
 * @return A master key (allocated), or NULL if the key could not be resolved. */
typedef MPMasterKey (*MPMasterKeyProvider)(
        MPAlgorithmVersion algorithm, const char *fullName);
/** A function that updates the currentKey with the masterKey of the given algorithm for the user with the given name.
 * @param currentKey A pointer to where the current masterKey (allocated) can be found and a new one can be placed.  Must be freed if updated.
 * @param currentAlgorithm A pointer to where the algorithm of the current masterKey is found and can be updated.
 * @param algorithm The algorithm of the masterKey that should be placed in currentKey.
 * @param fullName The name of the user whose masterKey should be placed in currentKey.
 * @return false if not able to resolve the requested masterKey. */
typedef bool (*MPMasterKeyProviderProxy)(
        MPMasterKey *currentKey, MPAlgorithmVersion *currentAlgorithm, MPAlgorithmVersion algorithm, const char *fullName);

/** Create a key provider which handles key generation by proxying the given function.
 * The proxy function receives the currently cached key and its algorithm.  If those are NULL, the proxy function should clean up its state. */
MPMasterKeyProvider mpw_masterKeyProvider_proxy(
        const MPMasterKeyProviderProxy proxy);
/** Create a key provider that computes a master key for the given master password. */
MPMasterKeyProvider mpw_masterKeyProvider_str(
        const char *masterPassword);

/** Free the cached keys and proxy state. */
void mpw_masterKeyProvider_free(void);

typedef struct MPMarshalError {
    /** The status of the most recent processing operation. */
    MPMarshalErrorType type;
    /** An explanation of the situation that caused the current status type. */
    const char *message;
} MPMarshalError;

typedef struct MPMarshalledData {
    /** If the parent is an object, this holds the key by which this data value is referenced. */
    const char *obj_key;
    /** If the parent is an array, this holds the index at which this data value is referenced. */
    size_t arr_index;

    /** Whether this data value represents a null value (true). */
    bool is_null;
    /** Whether this data value represents a boolean value (true). */
    bool is_bool;
    /** The textual value of this data if it holds a string. */
    const char *str_value;
    /** The numerical value of this data if it holds a number or a boolean. */
    double num_value;

    /** Amount of data values references under this value if it represents an object or an array. */
    size_t children_count;
    /** Array of data values referenced under this value. */
    struct MPMarshalledData *children;
} MPMarshalledData;

typedef struct MPMarshalledInfo {
    /** The data format used for serializing the file and user data into a byte stream. */
    MPMarshalFormat format;
    /** Date of when the file was previously serialized. */
    time_t exportDate;
    /** Whether secrets and state should be visible in clear-text (false) when serialized. */
    bool redacted;

    /** Algorithm version to use for user operations (eg. key ID operations). */
    MPAlgorithmVersion algorithm;
    /** A number identifying the avatar to display for the user in this file. */
    unsigned int avatar;
    /** Unique name for this file's user, preferably the user's full legal name. */
    const char *fullName;
    /** User metadata: The identicon that was generated to represent this file's user identity. */
    MPIdenticon identicon;
    /** A unique identifier (hex) for the user's master key, primarily for authentication/verification. */
    MPKeyID keyID;
    /** User metadata: Date of the most recent action taken by this user. */
    time_t lastUsed;
} MPMarshalledInfo;

typedef struct MPMarshalledQuestion {
    /** Unique name for the security question, preferably a single key word from the question sentence. */
    const char *keyword;
    /** The result type to use for generating an answer. */
    MPResultType type;
    /** State data (base64), if any, necessary for generating the question's answer. */
    const char *state;
} MPMarshalledQuestion;

typedef struct MPMarshalledSite {
    /** Unique name for this site. */
    const char *siteName;
    /** Algorithm version to use for all site operations (eg. result, login, question operations). */
    MPAlgorithmVersion algorithm;

    /** The counter value of the site result to generate. */
    MPCounterValue counter;
    /** The result type to use for generating a site result. */
    MPResultType resultType;
    /** State data (base64), if any, necessary for generating the site result. */
    const char *resultState;

    /** The result type to use for generating a site login. */
    MPResultType loginType;
    /** State data (base64), if any, necessary for generating the site login. */
    const char *loginState;

    /** Site metadata: URL location where the site can be accessed. */
    const char *url;
    /** Site metadata: Amount of times an action has been taken for this site. */
    unsigned int uses;
    /** Site metadata: Date of the most recent action taken on this site. */
    time_t lastUsed;

    /** Amount of security questions associated with this site. */
    size_t questions_count;
    /** Array of security questions associated with this site. */
    MPMarshalledQuestion *questions;
} MPMarshalledSite;

typedef struct MPMarshalledUser {
    MPMasterKeyProvider masterKeyProvider;
    bool redacted;

    /** A number identifying the avatar to display for this user. */
    unsigned int avatar;
    /** Unique name for this user, preferably the user's full legal name. */
    const char *fullName;
    /** User metadata: The identicon that was generated to represent this user's identity. */
    MPIdenticon identicon;
    /** Algorithm version to use for user operations (eg. key ID operations). */
    MPAlgorithmVersion algorithm;
    /** A unique identifier (hex) for the user's master key, primarily for authentication/verification. */
    MPKeyID keyID;
    /** The initial result type to use for new sites created by the user. */
    MPResultType defaultType;
    /** User metadata: Date of the most recent action taken by this user. */
    time_t lastUsed;

    /** Amount of sites associated to this user. */
    size_t sites_count;
    /** Array of sites associated to this user. */
    MPMarshalledSite *sites;
} MPMarshalledUser;

typedef struct MPMarshalledFile {
    /** Metadata from the file that holds user data, available without the need for user authentication. */
    MPMarshalledInfo *info;
    /** All data in the file, including extensions and other data present, even if not used by this library. */
    MPMarshalledData *data;
    /** Status of parsing the file and any errors that might have occurred during the process. */
    MPMarshalError error;
} MPMarshalledFile;

//// Marshalling.

/** Write the user and all associated data out using the given marshalling format.
 * @param file A pointer to the original file object to update with the user's data or to NULL to make a new.
 *             File object will be updated with state or new (allocated).  May be NULL if not interested in a file object.
 * @return A string (allocated), or NULL if the file is missing, format is unrecognized, does not support marshalling or a format error occurred. */
const char *mpw_marshal_write(
        const MPMarshalFormat outFormat, MPMarshalledFile **file, MPMarshalledUser *user);
/** Parse the user configuration in the input buffer.  Fields that could not be parsed remain at their type's initial value.
 * @return The updated file object or a new one (allocated) if none was provided; NULL if a file object could not be allocated. */
MPMarshalledFile *mpw_marshal_read(
        MPMarshalledFile *file, const char *in);
/** Authenticate as the user identified by the given marshalled file.
 * @note This object stores a reference to the given key provider.
 * @return A user object (allocated), or NULL if the file format provides no marshalling or a format error occurred. */
MPMarshalledUser *mpw_marshal_auth(
        MPMarshalledFile *file, const MPMasterKeyProvider masterKeyProvider);

//// Creating.

/** Create a new user object ready for marshalling.
 * @note This object stores copies of the strings assigned to it and manages their deallocation internally.
 * @return A user object (allocated), or NULL if the fullName is missing or the marshalled user couldn't be allocated. */
MPMarshalledUser *mpw_marshal_user(
        const char *fullName, const MPMasterKeyProvider masterKeyProvider, const MPAlgorithmVersion algorithmVersion);
/** Create a new site attached to the given user object, ready for marshalling.
 * @note This object stores copies of the strings assigned to it and manages their deallocation internally.
 * @return A site object (allocated), or NULL if the siteName is missing or the marshalled site couldn't be allocated. */
MPMarshalledSite *mpw_marshal_site(
        MPMarshalledUser *user,
        const char *siteName, const MPResultType resultType, const MPCounterValue siteCounter, const MPAlgorithmVersion algorithmVersion);
/** Create a new question attached to the given site object, ready for marshalling.
 * @note This object stores copies of the strings assigned to it and manages their deallocation internally.
 * @return A question object (allocated), or NULL if the marshalled question couldn't be allocated. */
MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword);
/** Create or update a marshal file descriptor.
 * @param file If NULL, a new file will be allocated.  Otherwise, the given file will be updated and the updated file returned.
 * @param info If NULL, the file's info will be left as-is, otherwise it will be replaced by the given one.  The file will manage the info's deallocation.
 * @param data If NULL, the file's data will be left as-is, otherwise it will be replaced by the given one.  The file will manage the data's deallocation.
 * @return The given file or new (allocated) if file is NULL; or NULL if the user is missing or the file couldn't be allocated. */
MPMarshalledFile *mpw_marshal_file(
        MPMarshalledFile *file, MPMarshalledInfo *info, MPMarshalledData *data);
/** Record a marshal error.
 * @return The given file or new (allocated) if file is NULL; or NULL if the file couldn't be allocated. */
MPMarshalledFile *mpw_marshal_error(
        MPMarshalledFile *file, MPMarshalErrorType type, const char *format, ...);

//// Disposing.

/** Free the given user object and all associated data. */
void mpw_marshal_info_free(
        MPMarshalledInfo **info);
void mpw_marshal_user_free(
        MPMarshalledUser **user);
void mpw_marshal_data_free(
        MPMarshalledData **data);
void mpw_marshal_file_free(
        MPMarshalledFile **file);

//// Exploring.

/** Create a null value.
 * @return A new data value (allocated), initialized to a null value, or NULL if the value couldn't be allocated. */
MPMarshalledData *mpw_marshal_data_new(void);
/** Get or create a value for the given path in the data store.
 * @return The value at this path (shared), or NULL if the value didn't exist and couldn't be created. */
MPMarshalledData *mpw_marshal_data_get(
        MPMarshalledData *data, ...);
MPMarshalledData *mpw_marshal_data_vget(
        MPMarshalledData *data, va_list nodes);
/** Look up the value at the given path in the data store.
 * @return The value at this path (shared), or NULL if there is no value at this path. */
const MPMarshalledData *mpw_marshal_data_find(
        const MPMarshalledData *data, ...);
const MPMarshalledData *mpw_marshal_data_vfind(
        const MPMarshalledData *data, va_list nodes);
/** Check if the data represents a NULL value.
 * @return true if the value at this path is null or is missing, false if it is a non-null type. */
bool mpw_marshal_data_is_null(
        const MPMarshalledData *data, ...);
bool mpw_marshal_data_vis_null(
        const MPMarshalledData *data, va_list nodes);
/** Set a null value at the given path in the data store.
 * @return true if the object was successfully modified. */
bool mpw_marshal_data_set_null(
        MPMarshalledData *data, ...);
bool mpw_marshal_data_vset_null(
        MPMarshalledData *data, va_list nodes);
/** Look up the boolean value at the given path in the data store.
 * @return true if the value at this path is true, false if it is not or there is no boolean value at this path. */
bool mpw_marshal_data_get_bool(
        const MPMarshalledData *data, ...);
bool mpw_marshal_data_vget_bool(
        const MPMarshalledData *data, va_list nodes);
/** Set a boolean value at the given path in the data store.
 * @return true if the object was successfully modified. */
bool mpw_marshal_data_set_bool(
        const bool value, MPMarshalledData *data, ...);
bool mpw_marshal_data_vset_bool(
        const bool value, MPMarshalledData *data, va_list nodes);
/** Look up the numeric value at the given path in the data store.
 * @return A number or NAN if there is no numeric value at this path. */
double mpw_marshal_data_get_num(
        const MPMarshalledData *data, ...);
double mpw_marshal_data_vget_num(
        const MPMarshalledData *data, va_list nodes);
bool mpw_marshal_data_set_num(
        const double value, MPMarshalledData *data, ...);
bool mpw_marshal_data_vset_num(
        const double value, MPMarshalledData *data, va_list nodes);
/** Look up the string value at the given path in the data store.
 * @return The string value (shared) or string representation of the number at this path; NULL if there is no such value at this path. */
const char *mpw_marshal_data_get_str(
        const MPMarshalledData *data, ...);
const char *mpw_marshal_data_vget_str(
        const MPMarshalledData *data, va_list nodes);
bool mpw_marshal_data_set_str(
        const char *value, MPMarshalledData *data, ...);
bool mpw_marshal_data_vset_str(
        const char *value, MPMarshalledData *data, va_list nodes);
/** Keep only the data children that pass the filter test. */
void mpw_marshal_data_keep(
        MPMarshalledData *data, bool (*filter)(MPMarshalledData *child, void *args), void *args);
bool mpw_marshal_data_keep_none(
        MPMarshalledData *child, void *args);

//// Format.

/**
 * @return The purpose represented by the given name or ERR if the format was not recognized.
 */
const MPMarshalFormat mpw_format_named(
        const char *formatName);
/**
 * @return The standard name (static) for the given purpose or NULL if the format was not recognized.
 */
const char *mpw_format_name(
        const MPMarshalFormat format);
/**
 * @return The file extension (static) that's recommended and currently used for output files,
 *         or NULL if the format was not recognized or does not support marshalling.
 */
const char *mpw_format_extension(
        const MPMarshalFormat format);
/**
 * @return An array (allocated, count) of filename extensions (static) that are used for files of this format,
 *         the first being the currently preferred/output extension.
 *         NULL if the format is unrecognized or does not support marshalling.
 */
const char **mpw_format_extensions(
        const MPMarshalFormat format, size_t *count);

#endif // _MPW_MARSHAL_H
