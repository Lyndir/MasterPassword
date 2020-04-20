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

#ifndef MP_LIBS_BEGIN
#define MP_LIBS_BEGIN
#define MP_LIBS_END
#endif

MP_LIBS_BEGIN
#define __STDC_WANT_LIB_EXT1__ 1
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
MP_LIBS_END

#ifdef NS_ENUM
#define mpw_enum(_type, _name) NS_ENUM(_type, _name)
#else
#define mpw_enum(_type, _name) _type _name; enum
#endif

#ifdef NS_OPTIONS
#define mpw_opts(_type, _name) NS_OPTIONS(_type, _name)
#else
#define mpw_opts(_type, _name) _type _name; enum
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
typedef mpw_opts( uint16_t, MPResultTypeClass ) {
    /** Use the site key to generate a password from a template. */
            MPResultTypeClassTemplate = 1 << 4,
    /** Use the site key to encrypt and decrypt a stateful entity. */
            MPResultTypeClassStateful = 1 << 5,
    /** Use the site key to derive a site-specific object. */
            MPResultTypeClassDerive = 1 << 6,
};

// bit 10 - 15
typedef mpw_opts( uint16_t, MPSiteFeature ) {
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
    MPIdenticonColorUnset,
    MPIdenticonColorRed,
    MPIdenticonColorGreen,
    MPIdenticonColorYellow,
    MPIdenticonColorBlue,
    MPIdenticonColorMagenta,
    MPIdenticonColorCyan,
    MPIdenticonColorMono,

    MPIdenticonColorFirst = MPIdenticonColorRed,
    MPIdenticonColorLast = MPIdenticonColorMono,
};

typedef struct {
    const char *leftArm;
    const char *body;
    const char *rightArm;
    const char *accessory;
    MPIdenticonColor color;
} MPIdenticon;
extern const MPIdenticon MPIdenticonUnset;

//// Type utilities.

/**
 * @return The purpose represented by the given name or ERR if the name does not represent a known purpose.
 */
const MPKeyPurpose mpw_purpose_named(const char *purposeName);
/**
 * @return The standard name (static) for the given purpose or NULL if the purpose is not known.
 */
const char *mpw_purpose_name(const MPKeyPurpose purpose);
/**
 * @return The scope identifier (static) to apply when encoding for the given purpose or NULL if the purpose is not known.
 */
const char *mpw_purpose_scope(const MPKeyPurpose purpose);

/**
 * @return The password type represented by the given name or ERR if the name does not represent a known type.
 */
const MPResultType mpw_type_named(const char *typeName);
/**
 * @return The standard identifying name (static) for the given password type or NULL if the type is not known.
 */
const char *mpw_type_abbreviation(const MPResultType resultType);
/**
 * @return The standard identifying name (static) for the given password type or NULL if the type is not known.
 */
const char *mpw_type_short_name(const MPResultType resultType);
/**
 * @return The descriptive name (static) for the given password type or NULL if the type is not known.
 */
const char *mpw_type_long_name(const MPResultType resultType);

/**
 * @return An array (allocated, count) of strings (static) that express the templates to use for the given type.
 *         NULL if the type is not known or is not a MPResultTypeClassTemplate.
 */
const char **mpw_type_templates(const MPResultType type, size_t *count);
/**
 * @return A string (static) that contains the password encoding template of the given type for a seed that starts with the given byte.
 *         NULL if the type is not known or is not a MPResultTypeClassTemplate.
 */
const char *mpw_type_template(const MPResultType type, const uint8_t templateIndex);

/**
 * @return An string (static) with all the characters in the given character class or NULL if the character class is not known.
 */
const char *mpw_class_characters(const char characterClass);
/**
 * @return A character from given character class that encodes the given byte or NUL if the character class is not known or is empty.
 */
const char mpw_class_character(const char characterClass, const uint8_t seedByte);

#endif // _MPW_TYPES_H
