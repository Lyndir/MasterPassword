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

typedef enum( unsigned int, MPMarshallFormat ) {
    /** Generate a key for authentication. */
            MPMarshallFormatFlat,
    /** Generate a name for identification. */
            MPMarshallFormatJSON,

    MPMarshallFormatDefault = MPMarshallFormatJSON,
};

typedef enum( unsigned int, MPMarshallErrorType ) {
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
} MPMarshalledQuestion;

typedef struct MPMarshalledSite {
    const char *name;
    const char *content;
    MPPasswordType type;
    uint32_t counter;
    MPAlgorithmVersion algorithm;

    const char *loginName;
    bool loginGenerated;

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
    MPPasswordType defaultType;
    time_t lastUsed;

    size_t sites_count;
    MPMarshalledSite *sites;
} MPMarshalledUser;

//// Marshalling.

bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, const MPMarshalledUser *user, MPMarshallError *error);
MPMarshalledUser *mpw_marshall_read(
        char *in, const MPMarshallFormat inFormat, const char *masterPassword, MPMarshallError *error);

//// Utilities.

MPMarshalledUser *mpw_marshall_user(
        const char *fullName, const char *masterPassword, const MPAlgorithmVersion algorithmVersion);
MPMarshalledSite *mpw_marshall_site(
        MPMarshalledUser *user,
        const char *siteName, const MPPasswordType passwordType, const uint32_t siteCounter, const MPAlgorithmVersion algorithmVersion);
MPMarshalledQuestion *mpw_marshal_question(
        MPMarshalledSite *site, const char *keyword);
bool mpw_marshal_free(
        MPMarshalledUser *user);

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
const char *mpw_marshall_format_extension(
        const MPMarshallFormat format);

#endif // _MPW_MARSHALL_H
