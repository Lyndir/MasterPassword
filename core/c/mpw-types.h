//
//  mpw-types.h
//  MasterPassword
//
//  Created by Maarten Billemont on 2012-02-01.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#ifndef _MPW_TYPES_H
#define _MPW_TYPES_H
#include <stdlib.h>
#include <stdint.h>

#ifdef NS_ENUM
#define enum(_type, _name) NS_ENUM(_type, _name)
#else
#define enum(_type, _name) _type _name; enum
#endif

#define MP_dkLen            64

//// Types.

typedef enum( unsigned int, MPSiteVariant ) {
    /** Generate the password to log in with. */
            MPSiteVariantPassword,
    /** Generate the login name to log in as. */
            MPSiteVariantLogin,
    /** Generate the answer to a security question. */
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

typedef enum( unsigned int, MPSiteType) {
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
