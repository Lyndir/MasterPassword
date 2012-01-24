//
//  OPTypes.m
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPTypes.h"
#import "OPElementGeneratedEntity.h"
#import "OPElementStoredEntity.h"


NSString *NSStringFromOPElementType(OPElementType type) {

    if (!type)
        return nil;
    
    switch (type) {
        case OPElementTypeCalculatedLong:
            return @"Long Password";
            
        case OPElementTypeCalculatedMedium:
            return @"Medium Password";
            
        case OPElementTypeCalculatedShort:
            return @"Short Password";
            
        case OPElementTypeCalculatedBasic:
            return @"Basic Password";
            
        case OPElementTypeCalculatedPIN:
            return @"PIN";
            
        case OPElementTypeStoredPersonal:
            return @"Personal Password";
            
        case OPElementTypeStoredDevicePrivate:
            return @"Device Private Password";
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Type not supported: %d", type];
    }
}

Class ClassFromOPElementType(OPElementType type) {
    
    if (!type)
        return nil;
    
    switch (type) {
        case OPElementTypeCalculatedLong:
            return [OPElementGeneratedEntity class];
            
        case OPElementTypeCalculatedMedium:
            return [OPElementGeneratedEntity class];
            
        case OPElementTypeCalculatedShort:
            return [OPElementGeneratedEntity class];
            
        case OPElementTypeCalculatedBasic:
            return [OPElementGeneratedEntity class];
            
        case OPElementTypeCalculatedPIN:
            return [OPElementGeneratedEntity class];
            
        case OPElementTypeStoredPersonal:
            return [OPElementStoredEntity class];
            
        case OPElementTypeStoredDevicePrivate:
            return [OPElementStoredEntity class];
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Type not supported: %d", type];
    }
}

NSString *ClassNameFromOPElementType(OPElementType type) {
    
    return NSStringFromClass(ClassFromOPElementType(type));
}

static NSDictionary *OPTypes_ciphers = nil;
NSString *OPCalculateContent(OPElementType type, NSString *name, NSString *keyPhrase, int counter) {
    
    assert(type & OPElementTypeClassCalculated);
    
    if (OPTypes_ciphers == nil)
        OPTypes_ciphers = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ciphers"
                                                                                            withExtension:@"plist"]];
    
    // Determine the hash whose bytes will be used for calculating a password: md4(name-keyPhrase)
    assert(name && keyPhrase);
    NSData *keyHash = [[NSString stringWithFormat:@"%@-%@-%d", name, keyPhrase, counter] hashWith:PearlDigestMD4];
    const char *keyBytes = keyHash.bytes;
    
    // Determine the cipher from the first hash byte.
    assert([keyHash length]);
    NSArray *typeCiphers = [[OPTypes_ciphers valueForKey:@"OPElementTypeCalculated"] valueForKey:NSStringFromOPElementType(type)];
    NSString *cipher = [typeCiphers objectAtIndex:keyBytes[0] % [typeCiphers count]];

    // Encode the content, character by character, using subsequent hash bytes and the cipher.
    assert([keyHash length] >= [cipher length] + 1);
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        const char keyByte = keyBytes[c + 1];
        NSString *cipherClass = [cipher substringWithRange:NSMakeRange(c, 1)];
        NSString *cipherClassCharacters = [[OPTypes_ciphers valueForKey:@"OPCharacterClasses"] valueForKey:cipherClass];
        
        [content appendString:[cipherClassCharacters substringWithRange:NSMakeRange(keyByte % [cipherClassCharacters length], 1)]];
    }
    
    return content;
}