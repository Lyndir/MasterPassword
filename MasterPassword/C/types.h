//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

typedef enum {
    /** Generate the password to log in with. */
    MPSiteVariantPassword,
    /** Generate the login name to log in as. */
    MPSiteVariantLogin,
    /** Generate the answer to a security question. */
    MPSiteVariantAnswer,
} MPSiteVariant;

typedef enum {
    /** Generate the password. */
    MPSiteTypeClassGenerated = 1 << 4,
    /** Store the password. */
    MPSiteTypeClassStored = 1 << 5,
} MPSiteTypeClass;

typedef enum {
    /** Export the key-protected content data. */
    MPSiteFeatureExportContent = 1 << 10,
    /** Never export content. */
    MPSiteFeatureDevicePrivate = 1 << 11,
} MPSiteFeature;

typedef enum {
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
} MPSiteType;

#ifdef DEBUG
#define trc(...) fprintf(stderr, __VA_ARGS__)
#else
#define trc(...) do {} while (0)
#endif

const MPSiteVariant VariantWithName(const char *variantName);
const char *ScopeForVariant(MPSiteVariant variant);
const MPSiteType TypeWithName(const char *typeName);
const char *TemplateForType(MPSiteType type, uint8_t seedByte);
const char CharacterFromClass(char characterClass, uint8_t seedByte);
const char *IDForBuf(const void *buf, size_t length);
const char *Hex(const void *buf, size_t length);
const char *Identicon(const char *fullName, const char *masterPassword);

