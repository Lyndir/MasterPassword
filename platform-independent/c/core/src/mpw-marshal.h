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

typedef MPMasterKey (*MPMasterKeyProvider)(MPAlgorithmVersion algorithm, const char *fullName);

typedef struct MPMarshalError {
    MPMarshalErrorType type;
    const char *message;
} MPMarshalError;

typedef struct MPMarshalInfo {
    MPMarshalFormat format;
    time_t exportDate;
    bool redacted;

    MPAlgorithmVersion algorithm;
    unsigned int avatar;
    const char *fullName;
    MPIdenticon identicon;
    const char *keyID;
    time_t lastUsed;
} MPMarshalInfo;

typedef struct MPMarshalledQuestion {
    const char *keyword;
    MPResultType type;
    const char *state;
} MPMarshalledQuestion;

typedef struct MPMarshalledSite {
    const char *siteName;
    MPAlgorithmVersion algorithm;
    MPCounterValue counter;

    MPResultType resultType;
    const char *resultState;

    MPResultType loginType;
    const char *loginState;

    const char *url;
    unsigned int uses;
    time_t lastUsed;

    size_t questions_count;
    MPMarshalledQuestion *questions;
} MPMarshalledSite;

typedef struct MPMarshalledUser {
    MPMasterKeyProvider masterKeyProvider;
    MPAlgorithmVersion algorithm;
    bool redacted;

    unsigned int avatar;
    const char *fullName;
    MPIdenticon identicon;
    const char *keyID;
    MPResultType defaultType;
    time_t lastUsed;

    size_t sites_count;
    MPMarshalledSite *sites;
} MPMarshalledUser;

typedef struct MPMarshalledData {
    // If data is held in a parent object.
    const char *key;
    // If data is held in a parent array.
    unsigned int index;

    // If data is a string.
    const char *str_value;
    // If data is a boolean.
    bool bool_value;
    // If data is a number.
    double num_value;

    // If data is an object or array.
    struct MPMarshalledData **obj_children;
    size_t obj_children_count;
} MPMarshalledData;

typedef struct MPMarshalledFile {
    MPMarshalInfo *info;
    MPMarshalledUser *user;
    MPMarshalledData *data;
} MPMarshalledFile;

//// Marshalling.

/** Write the user and all associated data out using the given marshalling format.
 * @return A string (allocated), or NULL if the format is unrecognized, does not support marshalling or a format error occurred. */
const char *mpw_marshal_write(
        const MPMarshalFormat outFormat, const MPMarshalledFile *file, MPMarshalError *error);
/** Best effort parse of metadata on the sites in the input buffer.  Fields that could not be parsed remain at their type's initial value.
 * @return A metadata object (allocated); NULL if the object could not be allocated or the format was not understood. */
MPMarshalInfo *mpw_marshal_read_info(
        const char *in);
/** Unmarshall sites in the given input buffer by parsing it using the given marshalling format.
 * @return A user object (allocated), or NULL if the format provides no marshalling or a format error occurred. */
MPMarshalledFile *mpw_marshal_read(
        const char *in, MPMasterKeyProvider masterKeyProvider, MPMarshalError *error);

//// Utilities.

/** Create a new user object ready for marshalling.
 * @return A user object (allocated), or NULL if the fullName is missing or the marshalled user couldn't be allocated. */
MPMarshalledUser *mpw_marshal_user(
        const char *fullName, MPMasterKeyProvider masterKeyProvider, const MPAlgorithmVersion algorithmVersion);
/** Create a new site attached to the given user object, ready for marshalling.
 * @return A site object (allocated), or NULL if the siteName is missing or the marshalled site couldn't be allocated. */
MPMarshalledSite *mpw_marshal_site(
        MPMarshalledUser *user,
        const char *siteName, const MPResultType resultType, const MPCounterValue siteCounter, const MPAlgorithmVersion algorithmVersion);
/** Create a new question attached to the given site object, ready for marshalling.
 * @return A question object (allocated), or NULL if the marshalled question couldn't be allocated. */
MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword);
/** Create a new file to marshal a user into.
 * @return A file object (allocated), or NULL if the user is missing or the marshalled file couldn't be allocated. */
MPMarshalledFile *mpw_marshal_file(
        MPMarshalledUser *user);

/** Free the given user object and all associated data. */
bool mpw_marshal_info_free(
        MPMarshalInfo **info);
bool mpw_marshal_free(
        MPMarshalledFile **user);

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
const char *mpw_marshal_format_extension(
        const MPMarshalFormat format);
/**
 * @return An array (allocated, count) of filename extensions (static) that are used for files of this format,
 *         the first being the currently preferred/output extension.
 *         NULL if the format is unrecognized or does not support marshalling.
 */
const char **mpw_marshal_format_extensions(
        const MPMarshalFormat format, size_t *count);

#endif // _MPW_MARSHAL_H
