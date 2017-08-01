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
#define MPSiteKeySize 256 / 8 // Bytes in HMAC-SHA-256
typedef const uint8_t *MPSiteKey;
typedef const char *MPKeyID;

typedef enum( unsigned int, MPKeyPurpose ) {
    /** Generate a key for authentication. */
            MPKeyPurposeAuthentication,
    /** Generate a name for identification. */
            MPKeyPurposeIdentification,
    /** Generate a recovery token. */
            MPKeyPurposeRecovery,
};

typedef enum( unsigned int, MPPasswordTypeClass ) {
    /** Generate the password. */
            MPPasswordTypeClassGenerated = 1 << 4,
    /** Store the password. */
            MPPasswordTypeClassStored = 1 << 5,
};

typedef enum( unsigned int, MPSiteFeature ) {
    /** Export the key-protected content data. */
            MPSiteFeatureExportContent = 1 << 10,
    /** Never export content. */
            MPSiteFeatureDevicePrivate = 1 << 11,
};

typedef enum( unsigned int, MPPasswordType ) {
    /** pg^VMAUBk5x3p%HP%i4= */
    MPPasswordTypeGeneratedMaximum = 0x0 | MPPasswordTypeClassGenerated | 0x0,
    /** BiroYena8:Kixa */
    MPPasswordTypeGeneratedLong = 0x1 | MPPasswordTypeClassGenerated | 0x0,
    /** BirSuj0- */
    MPPasswordTypeGeneratedMedium = 0x2 | MPPasswordTypeClassGenerated | 0x0,
    /** pO98MoD0 */
    MPPasswordTypeGeneratedBasic = 0x4 | MPPasswordTypeClassGenerated | 0x0,
    /** Bir8 */
    MPPasswordTypeGeneratedShort = 0x3 | MPPasswordTypeClassGenerated | 0x0,
    /** 2798 */
    MPPasswordTypeGeneratedPIN = 0x5 | MPPasswordTypeClassGenerated | 0x0,
    /** birsujano */
    MPPasswordTypeGeneratedName = 0xE | MPPasswordTypeClassGenerated | 0x0,
    /** bir yennoquce fefi */
    MPPasswordTypeGeneratedPhrase = 0xF | MPPasswordTypeClassGenerated | 0x0,

    /** Custom saved password. */
    MPPasswordTypeStoredPersonal = 0x0 | MPPasswordTypeClassStored | MPSiteFeatureExportContent,
    /** Custom saved password that should not be exported from the device. */
    MPPasswordTypeStoredDevice = 0x1 | MPPasswordTypeClassStored | MPSiteFeatureDevicePrivate,

    MPPasswordTypeDefault = MPPasswordTypeGeneratedLong,
};

//// Type utilities.

/**
 * @return The purpose represented by the given name.
 */
const MPKeyPurpose mpw_purposeWithName(const char *purposeName);
/**
 * @return The standard name for the given purpose.
 */
const char *mpw_nameForPurpose(MPKeyPurpose purpose);
/**
 * @return An internal string containing the scope identifier to apply when encoding for the given purpose.
 */
const char *mpw_scopeForPurpose(MPKeyPurpose purpose);

/**
 * @return The password type represented by the given name.
 */
const MPPasswordType mpw_typeWithName(const char *typeName);
/**
 * @return The standard name for the given password type.
 */
const char *mpw_nameForType(MPPasswordType passwordType);

/**
 * @return A newly allocated array of internal strings that express the templates to use for the given type.
 *         The amount of elements in the array is stored in count.
 *         If an unsupported type is given, count will be 0 and will return NULL.
*          The array needs to be free'ed, the strings themselves must not be free'ed or modified.
 */
const char **mpw_templatesForType(MPPasswordType type, size_t *count);
/**
 * @return An internal string that contains the password encoding template of the given type
 *         for a seed that starts with the given byte.
 */
const char *mpw_templateForType(MPPasswordType type, uint8_t seedByte);

/**
 * @return An internal string that contains all the characters that occur in the given character class.
 */
const char *mpw_charactersInClass(char characterClass);
/**
 * @return A character from given character class that encodes the given byte.
 */
const char mpw_characterFromClass(char characterClass, uint8_t seedByte);

#endif // _MPW_TYPES_H
