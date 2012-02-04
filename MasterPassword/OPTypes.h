//
//  OPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>

#define OPPersistentStoreDidChangeNotification @"OPPersistentStoreDidChange"

typedef enum {
    OPElementContentTypePassword,
    OPElementContentTypeNote,
    OPElementContentTypePicture,
} OPElementContentType;

typedef enum {
    OPElementTypeClassCalculated = 2 << 7,
    OPElementTypeClassStored     = 2 << 8,
} OPElementTypeClass;

typedef enum {
    OPElementTypeCalculatedLong         = OPElementTypeClassCalculated  | 0x01,
    OPElementTypeCalculatedMedium       = OPElementTypeClassCalculated  | 0x02,
    OPElementTypeCalculatedShort        = OPElementTypeClassCalculated  | 0x03,
    OPElementTypeCalculatedBasic        = OPElementTypeClassCalculated  | 0x04,
    OPElementTypeCalculatedPIN          = OPElementTypeClassCalculated  | 0x05,
    
    OPElementTypeStoredPersonal         = OPElementTypeClassStored      | 0x01,
    OPElementTypeStoredDevicePrivate    = OPElementTypeClassStored      | 0x02,
} OPElementType;

NSString *NSStringFromOPElementType(OPElementType type);
NSString *ClassNameFromOPElementType(OPElementType type);
Class ClassFromOPElementType(OPElementType type);
NSString *OPCalculateContent(OPElementType type, NSString *name, NSString *keyPhrase, int counter);
