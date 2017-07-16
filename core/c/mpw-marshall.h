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
#include "mpw-algorithm.h"

#ifdef NS_ENUM
#define enum(_type, _name) NS_ENUM(_type, _name)
#else
#define enum(_type, _name) _type _name; enum
#endif

//// Types.

typedef enum( unsigned int, MPMarshallFormat ) {
    /** Generate a key for authentication. */
            MPMarshallFormatFlat,
    /** Generate a name for identification. */
            MPMarshallFormatJSON,
};

typedef struct MPMarshalledQuestion {
    const char *keyword;
} MPMarshalledQuestion;

typedef struct MPMarshalledSite {
    const char *name;
    const char *content;
    MPSiteType type;
    uint32_t counter;
    MPAlgorithmVersion version;

    const char *loginName;
    bool loginGenerated;

    const char *url;
    unsigned int uses;
    time_t lastUsed;

    size_t questions_count;
    MPMarshalledQuestion *questions;
} MPMarshalledSite;

typedef struct MPMarshalledUser {
    const char *name;
    MPMasterKey key;
    MPAlgorithmVersion version;

    unsigned int avatar;
    MPSiteType defaultType;
    time_t lastUsed;

    size_t sites_count;
    MPMarshalledSite *sites;
} MPMarshalledUser;

//// Marshalling.

bool mpw_marshall_write(
        char **out, const MPMarshallFormat outFormat, bool redacted,
        const MPMarshalledUser *marshalledUser);

//// Unmarshalling.

MPMarshalledUser mpw_marshall_read(
        char *in, const MPMarshallFormat outFormat);

//// Utilities.

MPMarshalledUser mpw_marshall_user(
        const char *fullName, MPMasterKey masterKey, const MPAlgorithmVersion algorithmVersion);
MPMarshalledSite mpw_marshall_site(
        MPMarshalledUser *marshalledUser,
        const char *siteName, const MPSiteType siteType, const uint32_t siteCounter, const MPAlgorithmVersion algorithmVersion);
MPMarshalledQuestion mpw_marshal_question(
        MPMarshalledSite *marshalledSite, const char *keyword);

#endif // _MPW_MARSHALL_H
