//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

typedef enum {
    /** Generate the password to log in with. */
    MPElementVariantPassword,
    /** Generate the login name to log in as. */
    MPElementVariantLogin,
    /** Generate the answer to a security question. */
    MPElementVariantAnswer,
} MPElementVariant;

typedef enum {
    /** Generate the password. */
    MPElementTypeClassGenerated = 1 << 4,
    /** Store the password. */
    MPElementTypeClassStored = 1 << 5,
} MPElementTypeClass;

typedef enum {
    /** Export the key-protected content data. */
    MPElementFeatureExportContent = 1 << 10,
    /** Never export content. */
    MPElementFeatureDevicePrivate = 1 << 11,
} MPElementFeature;

typedef enum {
    MPElementTypeGeneratedMaximum = 0x0 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedLong = 0x1 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedMedium = 0x2 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedBasic = 0x4 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedShort = 0x3 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedPIN = 0x5 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedName = 0xE | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedPhrase = 0xF | MPElementTypeClassGenerated | 0x0,

    MPElementTypeStoredPersonal = 0x0 | MPElementTypeClassStored | MPElementFeatureExportContent,
    MPElementTypeStoredDevicePrivate = 0x1 | MPElementTypeClassStored | MPElementFeatureDevicePrivate,
} MPElementType;

#ifdef DEBUG
#define trc(...) fprintf(stderr, __VA_ARGS__)
#else
#define trc(...) do {} while (0)
#endif

const MPElementVariant VariantWithName(const char *variantName);
const char *ScopeForVariant(MPElementVariant variant);
const MPElementType TypeWithName(const char *typeName);
const char *CipherForType(MPElementType type, uint8_t seedByte);
const char CharacterFromClass(char characterClass, uint8_t seedByte);
const char *IDForBuf(const void *buf, size_t length);
const char *Hex(const void *buf, size_t length);

