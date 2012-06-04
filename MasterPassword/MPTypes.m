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


#define MP_salt     nil
#define MP_N        16384
#define MP_r        8
#define MP_p        1
#define MP_dkLen    64
#define MP_hash     PearlDigestSHA256

NSData *keyForPassword(NSString *password) {
    
    NSData *key = [PearlSCrypt deriveKeyWithLength:MP_dkLen fromPassword:[password dataUsingEncoding:NSUTF8StringEncoding]
                                         usingSalt:MP_salt N:MP_N r:MP_r p:MP_p];
    
    trc(@"Password: %@ derives to key ID: %@", password, [keyIDForKey(key) encodeHex]);
    return key;
}
NSData *keyIDForPassword(NSString *password) {
    
    return keyIDForKey(keyForPassword(password));
}
NSData *keyIDForKey(NSData *key) {
    
    return [key hashWith:MP_hash];
}
NSString *NSStringFromMPElementType(MPElementType type) {
    
    if (!type)
        return nil;
    
    switch (type) {
        case MPElementTypeGeneratedLong:
            return @"Long Password";
            
        case MPElementTypeGeneratedMedium:
            return @"Medium Password";
            
        case MPElementTypeGeneratedShort:
            return @"Short Password";
            
        case MPElementTypeGeneratedBasic:
            return @"Basic Password";
            
        case MPElementTypeGeneratedPIN:
            return @"PIN";
            
        case MPElementTypeStoredPersonal:
            return @"Personal Password";
            
        case MPElementTypeStoredDevicePrivate:
            return @"Device Private Password";
            
        default:
            Throw(@"Type not supported: %d", type);
    }
}

Class ClassFromMPElementType(MPElementType type) {
    
    if (!type)
        return nil;
    
    switch (type) {
        case MPElementTypeGeneratedLong:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeGeneratedMedium:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeGeneratedShort:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeGeneratedBasic:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeGeneratedPIN:
            return [MPElementGeneratedEntity class];
            
        case MPElementTypeStoredPersonal:
            return [MPElementStoredEntity class];
            
        case MPElementTypeStoredDevicePrivate:
            return [MPElementStoredEntity class];
            
        default:
            Throw(@"Type not supported: %d", type);
    }
}

NSString *ClassNameFromMPElementType(MPElementType type) {
    
    return NSStringFromClass(ClassFromMPElementType(type));
}

static NSDictionary *MPTypes_ciphers = nil;
NSString *MPCalculateContent(MPElementType type, NSString *name, NSData *key, uint32_t counter) {
    
    if (!(type & MPElementTypeClassGenerated)) {
        err(@"Incorrect type (is not MPElementTypeClassGenerated): %d, for: %@", type, name);
        return nil;
    }
    if (!name) {
        err(@"Missing name.");
        return nil;
    }
    if (!key) {
        err(@"Key not set.");
        return nil;
    }
    uint32_t salt = counter;
    if (!counter)
        // Counter unset, go into OTP mode.
        // Get the UNIX timestamp of the start of the interval of 5 minutes that the current time is in.
        salt = ((uint32_t)([[NSDate date] timeIntervalSince1970] / 300)) * 300;
    
    if (MPTypes_ciphers == nil)
        MPTypes_ciphers = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ciphers"
                                                                                            withExtension:@"plist"]];
    
    // Determine the seed whose bytes will be used for calculating a password: sha1(name . '\0' . key . '\0' . salt)
    uint32_t nsalt = htonl(salt);
    trc(@"seed from: sha1(%@, %@, %u)", name, key, nsalt);
    NSData *seed = [[NSData dataByConcatenatingWithDelimitor:'\0' datas:
                     [name dataUsingEncoding:NSUTF8StringEncoding],
                     key,
                     [NSData dataWithBytes:&nsalt length:sizeof(nsalt)],
                     nil] hashWith:PearlDigestSHA1];
    trc(@"seed is: %@", seed);
    const char *seedBytes = seed.bytes;
    
    // Determine the cipher from the first seed byte.
    assert([seed length]);
    NSArray *typeCiphers = [[MPTypes_ciphers valueForKey:ClassNameFromMPElementType(type)]
                            valueForKey:NSStringFromMPElementType(type)];
    NSString *cipher = [typeCiphers objectAtIndex:htons(seedBytes[0]) % [typeCiphers count]];
    trc(@"type %d, ciphers: %@, selected: %@", type, typeCiphers, cipher);
    
    // Encode the content, character by character, using subsequent seed bytes and the cipher.
    assert([seed length] >= [cipher length] + 1);
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        uint16_t keyByte = htons(seedBytes[c + 1]);
        NSString *cipherClass = [cipher substringWithRange:NSMakeRange(c, 1)];
        NSString *cipherClassCharacters = [[MPTypes_ciphers valueForKey:@"MPCharacterClasses"] valueForKey:cipherClass];
        NSString *character = [cipherClassCharacters substringWithRange:NSMakeRange(keyByte % [cipherClassCharacters length], 1)];
        
        trc(@"class %@ has characters: %@, selected: %@", cipherClass, cipherClassCharacters, character);
        [content appendString:character];
    }
    
    return content;
}
