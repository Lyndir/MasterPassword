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

#ifndef _MPW_TYPES_H
#define _MPW_TYPES_H

#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef NS_ENUM
#define enum(_type, _name) NS_ENUM(_type, _name)
#else
#define enum(_type, _name) _type _name; enum
#endif

//// Types.

#define MPMasterKeySize 64
typedef const uint8_t *MPMasterKey;
typedef const char *MPMasterKeyID;

typedef enum( unsigned int, MPSiteVariant ) {
    /** Generate a key for authentication. */
            MPSiteVariantPassword,
    /** Generate a name for identification. */
            MPSiteVariantLogin,
    /** Generate an answer to a security question. */
            MPSiteVariantAnswer,
};

typedef enum( unsigned int, MPSiteTypeClass ) {
    /** Generate the password. */
            MPSiteTypeClassGenerated = 1 << 4,
    /** Store the password. */
            MPSiteTypeClassStored = 1 << 5,
};

typedef enum( unsigned int, MPSiteFeature ) {
    /** Export the key-protected content data. */
            MPSiteFeatureExportContent = 1 << 10,
    /** Never export content. */
            MPSiteFeatureDevicePrivate = 1 << 11,
};

typedef enum( unsigned int, MPSiteType ) {
    MPSiteTypeGeneratedMaximum = 0x0 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedLong = 0x1 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedMedium = 0x2 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedBasic = 0x4 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedShort = 0x3 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedPIN = 0x5 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedName = 0xE | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedPhrase = 0xF | MPSiteTypeClassGenerated | 0x0,

    MPSiteTypeStoredPersonal = 0x0 | MPSiteTypeClassStored | MPSiteFeatureExportContent,
    MPSiteTypeStoredDevicePrivate = 0x1 | MPSiteTypeClassStored | MPSiteFeatureDevicePrivate,

    MPSiteTypeDefault = MPSiteTypeGeneratedLong,
};

//// Type utilities.

/**
 * @return The variant represented by the given name.
 */
const MPSiteVariant mpw_variantWithName(const char *variantName);
/**
 * @return An internal string containing the scope identifier to apply when encoding for the given variant.
 */
const char *mpw_scopeForVariant(MPSiteVariant variant);

/**
 * @return The type represented by the given name.
 */
const MPSiteType mpw_typeWithName(const char *typeName);

/**
 * @return A newly allocated array of internal strings that express the templates to use for the given type.
 *         The amount of elements in the array is stored in count.
 *         If an unsupported type is given, count will be 0 and will return NULL.
*          The array needs to be free'ed, the strings themselves must not be free'ed or modified.
 */
const char **mpw_templatesForType(MPSiteType type, size_t *count);
/**
 * @return An internal string that contains the password encoding template of the given type
 *         for a seed that starts with the given byte.
 */
const char *mpw_templateForType(MPSiteType type, uint8_t seedByte);

/**
 * @return An internal string that contains all the characters that occur in the given character class.
 */
const char *mpw_charactersInClass(char characterClass);
/**
 * @return A character from given character class that encodes the given byte.
 */
const char mpw_characterFromClass(char characterClass, uint8_t seedByte);

#endif // _MPW_TYPES_H
