//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

typedef NS_ENUM(NSUInteger, MPElementContentType) {
    MPElementContentTypePassword,
    MPElementContentTypeNote,
    MPElementContentTypePicture,
};

typedef NS_ENUM(NSUInteger, MPElementTypeClass) {
    /** Generate the password. */
            MPElementTypeClassGenerated = 1 << 4,
    /** Store the password. */
            MPElementTypeClassStored = 1 << 5,
};

typedef NS_ENUM(NSUInteger, MPElementFeature) {
    /** Export the key-protected content data. */
            MPElementFeatureExportContent = 1 << 10,
    /** Never export content. */
            MPElementFeatureDevicePrivate = 1 << 11,
};

typedef NS_ENUM(NSUInteger, MPElementType) {
    MPElementTypeGeneratedMaximum = 0x0 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedLong = 0x1 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedMedium = 0x2 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedBasic = 0x4 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedShort = 0x3 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedPIN = 0x5 | MPElementTypeClassGenerated | 0x0,

    MPElementTypeStoredPersonal = 0x0 | MPElementTypeClassStored | MPElementFeatureExportContent,
    MPElementTypeStoredDevicePrivate = 0x1 | MPElementTypeClassStored | MPElementFeatureDevicePrivate,
};

extern const char *CipherForType(MPElementType type, char seedByte);
extern const char CharacterFromClass(char characterClass, char seedByte);
