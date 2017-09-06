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

#ifndef _MPW_MARSHALL_H
#define _MPW_MARSHALL_H

#include <time.h>

#include "mpw-algorithm.h"

//// Types.

typedef mpw_enum( unsigned int, MPMarshallFormat ) {
    /** Generate a key for authentication. */
            MPMarshallFormatNone,
    /** Generate a key for authentication. */
            MPMarshallFormatFlat,
    /** Generate a name for identification. */
            MPMarshallFormatJSON,

#if MPW_JSON
    MPMarshallFormatDefault = MPMarshallFormatJSON,
#else
    MPMarshallFormatDefault = MPMarshallFormatFlat,
#endif
};

typedef mpw_enum( unsigned int, MPMarshallErrorType ) {
    /** The marshalling operation completed successfully. */
            MPMarshallSuccess,
    /** An error in the structure of the marshall file interrupted marshalling. */
            MPMarshallErrorStructure,
    /** The marshall file uses an unsupported format version. */
            MPMarshallErrorFormat,
    /** A required value is missing or not specified. */
            MPMarshallErrorMissing,
    /** The given master password is not valid. */
            MPMarshallErrorMasterPassword,
    /** An illegal value was specified. */
            MPMarshallErrorIllegal,
    /** An internal system error interrupted marshalling. */
            MPMarshallErrorInternal,
};
typedef struct MPMarshallError {
    MPMarshallErrorType type;
    const char *description;
} MPMarshallError;

typedef struct MPMarshalledQuestion {
    const char *keyword;
    const char *content;
    MPResultType type;
} MPMarshalledQuestion;

typedef struct MPMarshalledSite {
    const char *name;
    const char *content;
    MPResultType type;
    MPCounterValue counter;
    MPAlgorithmVersion algorithm;

    const char *loginContent;
    MPResultType loginType;

    const char *url;
    unsigned int uses;
    time_t lastUsed;

    size_t questions_count;
    MPMarshalledQuestion *questions;
} MPMarshalledSite;

typedef struct MPMarshalledUser {
    const char *fullName;
    const char *masterPassword;
    MPAlgorithmVersion algorithm;
    bool redacted;

    unsigned int avatar;
    MPResultType defaultType;
    time_t lastUsed;

    size_t sites_count;
    MPMarshalledSite *sites;
} MPMarshalledUser;

typedef struct MPMarshallInfo {
    MPMarshallFormat format;
    MPAlgorithmVersion algorithm;
    const char *fullName;
    const char *keyID;
    bool redacted;
    time_t date;
} MPMarshallInfo;

//// Marshalling.

/** Write the user and all associated data out to the given output buffer using the given marshalling format. */
bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, const MPMarshalledUser *user, MPMarshallError *error);
/** Try to read metadata on the sites in the input buffer. */
MPMarshallInfo *mpw_marshall_read_info(
        const char *in);
/** Unmarshall sites in the given input buffer by parsing it using the given marshalling format. */
MPMarshalledUser *mpw_marshall_read(
        const char *in, const MPMarshallFormat inFormat, const char *masterPassword, MPMarshallError *error);

//// Utilities.

/** Create a new user object ready for marshalling. */
MPMarshalledUser *mpw_marshall_user(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion);
/** Create a new site attached to the given user object, ready for marshalling. */
MPMarshalledSite *mpw_marshall_site(
        MPMarshalledUser *user,
        const char *siteName, const MPResultType resultType, const MPCounterValue siteCounter, const MPAlgorithmVersion algorithmVersion);
/** Create a new question attached to the given site object, ready for marshalling. */
MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword);
/** Free the given user object and all associated data. */
bool mpw_marshal_info_free(
        MPMarshallInfo **info);
bool mpw_marshal_free(
        MPMarshalledUser **user);

//// Format.

/**
 * @return The purpose represented by the given name.
 */
const MPMarshallFormat mpw_formatWithName(
        const char *formatName);
/**
 * @return The standard name for the given purpose.
 */
const char *mpw_nameForFormat(
        const MPMarshallFormat format);
/**
 * @return The file extension that's recommended for files that use the given marshalling format.
 */
const char *mpw_marshall_format_extension(
        const MPMarshallFormat format);

#endif // _MPW_MARSHALL_H
