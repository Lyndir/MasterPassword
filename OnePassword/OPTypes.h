//
//  OPTypes.h
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OPElementContentTypePassword,
    OPElementContentTypeNote,
    OPElementContentTypePicture,
} OPElementContentType;

typedef enum {
    OPElementTypeCalculated = 2 << 7,
    OPElementTypeStored     = 2 << 8,
} OPElementTypeClass;

typedef enum {
    OPElementTypeCalculatedLong         = OPElementTypeCalculated   | 0x01,
    OPElementTypeCalculatedMedium       = OPElementTypeCalculated   | 0x02,
    OPElementTypeCalculatedShort        = OPElementTypeCalculated   | 0x03,
    OPElementTypeCalculatedBasic        = OPElementTypeCalculated   | 0x04,
    OPElementTypeCalculatedPIN          = OPElementTypeCalculated   | 0x05,
    
    OPElementTypeStoredPersonal         = OPElementTypeStored       | 0x01,
    OPElementTypeStoredDevicePrivate    = OPElementTypeStored       | 0x02,
} OPElementType;

NSString *NSStringFromOPElementType(OPElementType type);
Class ClassForOPElementType(OPElementType type);
NSString *OPCalculateContent(OPElementType type, NSString *name, NSString *keyPhrase, int counter);