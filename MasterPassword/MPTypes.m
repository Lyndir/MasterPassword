//
//  MPTypes.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPTypes.h"
#import "MPElementGeneratedEntity.h"
#import "MPElementStoredEntity.h"


NSString *NSStringFromMPElementType(MPElementType type) {

    if (!type)
        return nil;
    
    switch (type) {
        case MPElementTypeCalculatedLong:
            return @"Long Password";
            
        case MPElementTypeCalculatedMedium:
            return @"Medium Password";
            
        case MPElementTypeCalculatedShort:
            return @"Short Password";
            
        case MPElementTypeCalculatedBasic:
            return @"Basic Password";
            
        case MPElementTypeCalculatedPIN:
            return @"PIN";
            
        case MPElementTypeStoredPersonal:
            return @"Personal Password";
            
        case MPElementTypeStoredDevicePrivate:
            return @"Device Private Password";
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Type not supported: %d", type];
    }
}

Class ClassFromMPElementType(MPElementType type) {
    
    if (!type)
        return nil;
    
    switch (type) {
        case MPElementTypeCalculatedLong:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeCalculatedMedium:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeCalculatedShort:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeCalculatedBasic:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeCalculatedPIN:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeStoredPersonal:
            return [MPElementStoredEntity class];
            
        case MPElementTypeStoredDevicePrivate:
            return [MPElementStoredEntity class];
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Type not supported: %d", type];
    }
}

NSString *ClassNameFromMPElementType(MPElementType type) {
    
    return NSStringFromClass(ClassFromMPElementType(type));
}

static NSDictionary *MPTypes_ciphers = nil;
NSString *MPCalculateContent(MPElementType type, NSString *name, NSString *keyPhrase, int counter) {
    
    assert(type & MPElementTypeClassCalculated);
    
    if (MPTypes_ciphers == nil)
        MPTypes_ciphers = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ciphers"
                                                                                            withExtension:@"plist"]];
    
    // Determine the hash whose bytes will be used for calculating a password: md4(name-keyPhrase)
    assert(name && keyPhrase);
    NSData *keyHash = [[NSString stringWithFormat:@"%@-%@-%d", name, keyPhrase, counter] hashWith:PearlDigestSHA1];
    const char *keyBytes = keyHash.bytes;
    
    // Determine the cipher from the first hash byte.
    assert([keyHash length]);
    NSArray *typeCiphers = [[MPTypes_ciphers valueForKey:ClassNameFromMPElementType(type)]
            valueForKey:NSStringFromMPElementType(type)];
    NSString *cipher = [typeCiphers objectAtIndex:keyBytes[0] % [typeCiphers count]];

    // Encode the content, character by character, using subsequent hash bytes and the cipher.
    assert([keyHash length] >= [cipher length] + 1);
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        const char keyByte = keyBytes[c + 1];
        NSString *cipherClass = [cipher substringWithRange:NSMakeRange(c, 1)];
        NSString *cipherClassCharacters = [[MPTypes_ciphers valueForKey:@"MPCharacterClasses"] valueForKey:cipherClass];
        
        [content appendString:[cipherClassCharacters substringWithRange:NSMakeRange(keyByte % [cipherClassCharacters length], 1)]];
    }
    
    return content;
}
