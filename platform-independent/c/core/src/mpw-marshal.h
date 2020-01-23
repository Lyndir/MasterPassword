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

#include <time.h>

#include "mpw-algorithm.h"

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
    const char *description;
} MPMarshalError;

typedef struct MPMarshalledQuestion {
    const char *keyword;
    const char *state;
    MPResultType type;
} MPMarshalledQuestion;

typedef struct MPMarshalledSite {
    const char *name;
    MPAlgorithmVersion algorithm;

    const char *resultState;
    MPResultType resultType;
    MPCounterValue counter;

    const char *loginState;
    MPResultType loginType;

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
    MPResultType defaultType;
    time_t lastUsed;

    size_t sites_count;
    MPMarshalledSite *sites;
} MPMarshalledUser;

typedef struct MPMarshalInfo {
    MPMarshalFormat format;
    time_t exportDate;
    bool redacted;

    MPAlgorithmVersion algorithm;
    unsigned int avatar;
    const char *fullName;
    const char *keyID;
    time_t lastUsed;
} MPMarshalInfo;

//// Marshalling.

/** Write the user and all associated data out to the given output buffer using the given marshalling format. */
bool mpw_marshal_write(
        char **out, const MPMarshalFormat outFormat, const MPMarshalledUser *user, MPMarshalError *error);
/** Try to read metadata on the sites in the input buffer. */
MPMarshalInfo *mpw_marshal_read_info(
        const char *in);
/** Unmarshall sites in the given input buffer by parsing it using the given marshalling format. */
MPMarshalledUser *mpw_marshal_read(
        const char *in, const MPMarshalFormat inFormat, MPMasterKeyProvider masterKeyProvider, MPMarshalError *error);

//// Utilities.

/** Create a new user object ready for marshalling. */
MPMarshalledUser *mpw_marshal_user(
        const char *fullName, MPMasterKeyProvider masterKeyProvider, const MPAlgorithmVersion algorithmVersion);
/** Create a new site attached to the given user object, ready for marshalling. */
MPMarshalledSite *mpw_marshal_site(
        MPMarshalledUser *user,
        const char *siteName, const MPResultType resultType, const MPCounterValue siteCounter, const MPAlgorithmVersion algorithmVersion);
/** Create a new question attached to the given site object, ready for marshalling. */
MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword);
/** Free the given user object and all associated data. */
bool mpw_marshal_info_free(
        MPMarshalInfo **info);
bool mpw_marshal_free(
        MPMarshalledUser **user);

//// Format.

/**
 * @return The purpose represented by the given name.
 */
const MPMarshalFormat mpw_formatWithName(
        const char *formatName);
/**
 * @return The standard name for the given purpose.
 */
const char *mpw_nameForFormat(
        const MPMarshalFormat format);
/**
 * @return The file extension that's recommended for files that use the given marshalling format.
 */
const char *mpw_marshal_format_extension(
        const MPMarshalFormat format);
/**
 * @param extensions An array of filename extensions that are used for files of this format,
 *        the first being the currently preferred/output extension.  Free after use.
 * @return The amount of filename extensions returned in the array.
 */
int mpw_marshal_format_extensions(
        const MPMarshalFormat format, const char ***extensions);

#endif // _MPW_MARSHAL_H
