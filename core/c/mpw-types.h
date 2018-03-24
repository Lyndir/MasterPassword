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
#define mpw_enum(_type, _name) NS_ENUM(_type, _name)
#else
#define mpw_enum(_type, _name) _type _name; enum
#endif

#ifndef __unused
#define __unused __attribute__((unused))
#endif

//// Types.

extern const size_t MPMasterKeySize, MPSiteKeySize; /* bytes */
typedef const uint8_t *MPMasterKey, *MPSiteKey;
typedef const char *MPKeyID;

typedef mpw_enum( uint8_t, MPKeyPurpose ) {
    /** Generate a key for authentication. */
            MPKeyPurposeAuthentication,
    /** Generate a name for identification. */
            MPKeyPurposeIdentification,
    /** Generate a recovery token. */
            MPKeyPurposeRecovery,
};

// bit 4 - 9
typedef mpw_enum( uint16_t, MPResultTypeClass ) {
    /** Use the site key to generate a password from a template. */
            MPResultTypeClassTemplate = 1 << 4,
    /** Use the site key to encrypt and decrypt a stateful entity. */
            MPResultTypeClassStateful = 1 << 5,
    /** Use the site key to derive a site-specific object. */
            MPResultTypeClassDerive = 1 << 6,
};

// bit 10 - 15
typedef mpw_enum( uint16_t, MPSiteFeature ) {
    /** Export the key-protected content data. */
            MPSiteFeatureExportContent = 1 << 10,
    /** Never export content. */
            MPSiteFeatureDevicePrivate = 1 << 11,
    /** Don't use this as the primary authentication result type. */
            MPSiteFeatureAlternative = 1 << 12,
};

// bit 0-3 | MPResultTypeClass | MPSiteFeature
typedef mpw_enum( uint32_t, MPResultType ) {
    /** 16: pg^VMAUBk5x3p%HP%i4= */
            MPResultTypeTemplateMaximum = 0x0 | MPResultTypeClassTemplate | 0x0,
    /** 17: BiroYena8:Kixa */
            MPResultTypeTemplateLong = 0x1 | MPResultTypeClassTemplate | 0x0,
    /** 18: BirSuj0- */
            MPResultTypeTemplateMedium = 0x2 | MPResultTypeClassTemplate | 0x0,
    /** 19: Bir8 */
            MPResultTypeTemplateShort = 0x3 | MPResultTypeClassTemplate | 0x0,
    /** 20: pO98MoD0 */
            MPResultTypeTemplateBasic = 0x4 | MPResultTypeClassTemplate | 0x0,
    /** 21: 2798 */
            MPResultTypeTemplatePIN = 0x5 | MPResultTypeClassTemplate | 0x0,
    /** 30: birsujano */
            MPResultTypeTemplateName = 0xE | MPResultTypeClassTemplate | 0x0,
    /** 31: bir yennoquce fefi */
            MPResultTypeTemplatePhrase = 0xF | MPResultTypeClassTemplate | 0x0,

    /** 1056: Custom saved password. */
    MPResultTypeStatefulPersonal = 0x0 | MPResultTypeClassStateful | MPSiteFeatureExportContent,
    /** 2081: Custom saved password that should not be exported from the device. */
    MPResultTypeStatefulDevice = 0x1 | MPResultTypeClassStateful | MPSiteFeatureDevicePrivate,

    /** 4160: Derive a unique binary key. */
    MPResultTypeDeriveKey = 0x0 | MPResultTypeClassDerive | MPSiteFeatureAlternative,

    MPResultTypeDefault = MPResultTypeTemplateLong,
};

typedef mpw_enum ( uint32_t, MPCounterValue ) {
    /** Use a time-based counter value, resulting in a TOTP generator. */
            MPCounterValueTOTP = 0,
    /** The initial value for a site's counter. */
            MPCounterValueInitial = 1,

    MPCounterValueDefault = MPCounterValueInitial,
    MPCounterValueFirst = MPCounterValueTOTP,
    MPCounterValueLast = UINT32_MAX,
};

/** These colours are compatible with the original ANSI SGR. */
typedef mpw_enum( uint8_t, MPIdenticonColor ) {
    MPIdenticonColorRed = 1,
    MPIdenticonColorGreen,
    MPIdenticonColorYellow,
    MPIdenticonColorBlue,
    MPIdenticonColorMagenta,
    MPIdenticonColorCyan,
    MPIdenticonColorWhite,

    MPIdenticonColorFirst = MPIdenticonColorRed,
    MPIdenticonColorLast = MPIdenticonColorWhite,
};

typedef struct {
    const char *leftArm;
    const char *body;
    const char *rightArm;
    const char *accessory;
    MPIdenticonColor color;
} MPIdenticon;

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
const MPResultType mpw_typeWithName(const char *typeName);
/**
 * @return The standard name for the given password type.
 */
const char *mpw_nameForType(MPResultType resultType);

/**
 * @return A newly allocated array of internal strings that express the templates to use for the given type.
 *         The amount of elements in the array is stored in count.
 *         If an unsupported type is given, count will be 0 and will return NULL.
*          The array needs to be free'ed, the strings themselves must not be free'ed or modified.
 */
const char **mpw_templatesForType(MPResultType type, size_t *count);
/**
 * @return An internal string that contains the password encoding template of the given type
 *         for a seed that starts with the given byte.
 */
const char *mpw_templateForType(MPResultType type, uint8_t templateIndex);

/**
 * @return An internal string that contains all the characters that occur in the given character class.
 */
const char *mpw_charactersInClass(char characterClass);
/**
 * @return A character from given character class that encodes the given byte.
 */
const char mpw_characterFromClass(char characterClass, uint8_t seedByte);

#endif // _MPW_TYPES_H
