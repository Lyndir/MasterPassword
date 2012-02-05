//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MPPersistentStoreDidChangeNotification @"MPPersistentStoreDidChange"

typedef enum {
    MPElementContentTypePassword,
    MPElementContentTypeNote,
    MPElementContentTypePicture,
} MPElementContentType;

typedef enum {
    MPElementTypeClassCalculated = 2 << 7,
    MPElementTypeClassStored     = 2 << 8,
} MPElementTypeClass;

typedef enum {
    MPElementTypeCalculatedLong         = MPElementTypeClassCalculated  | 0x01,
    MPElementTypeCalculatedMedium       = MPElementTypeClassCalculated  | 0x02,
    MPElementTypeCalculatedShort        = MPElementTypeClassCalculated  | 0x03,
    MPElementTypeCalculatedBasic        = MPElementTypeClassCalculated  | 0x04,
    MPElementTypeCalculatedPIN          = MPElementTypeClassCalculated  | 0x05,
    
    MPElementTypeStoredPersonal         = MPElementTypeClassStored      | 0x01,
    MPElementTypeStoredDevicePrivate    = MPElementTypeClassStored      | 0x02,
} MPElementType;

NSString *NSStringFromMPElementType(MPElementType type);
NSString *ClassNameFromMPElementType(MPElementType type);
Class ClassFromMPElementType(MPElementType type);
NSString *MPCalculateContent(MPElementType type, NSString *name, NSString *keyPhrase, int counter);
