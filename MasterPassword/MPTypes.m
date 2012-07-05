//
//  MPTypes.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPEntities.h"


#define MP_N        32768
#define MP_r        8
#define MP_p        2
#define MP_dkLen    64
#define MP_hash     PearlHashSHA256

NSData *keyForPassword(NSString *password, NSString *username) {

    uint32_t nusernameLength = htonl(username.length);
    NSDate *start = [NSDate date];
    NSData *key = [PearlSCrypt deriveKeyWithLength:MP_dkLen fromPassword:[password dataUsingEncoding:NSUTF8StringEncoding]
                                                            usingSalt:[NSData dataByConcatenatingDatas:
                                                                               [@"com.lyndir.masterpassword" dataUsingEncoding:NSUTF8StringEncoding],
                                                                               [NSData dataWithBytes:&nusernameLength
                                                                                              length:sizeof(nusernameLength)],
                                                                               [username dataUsingEncoding:NSUTF8StringEncoding],
                                                                               nil] N:MP_N r:MP_r p:MP_p];

    trc(@"User: %@, password: %@ derives to key ID: %@ (took %0.2fs)", username, password, [keyIDForKey(key) encodeHex], -[start timeIntervalSinceNow]);
    return key;
}


NSData *subkeyForKey(NSData *key, NSUInteger subkeyLength) {

    return [key subdataWithRange:NSMakeRange(0, MIN(subkeyLength, key.length))];
}


NSData *keyIDForPassword(NSString *password, NSString *username) {

    return keyIDForKey(keyForPassword(password, username));
}

NSData *keyIDForKey(NSData *key) {

    return [key hashWith:MP_hash];
}

NSString *NSStringFromMPElementType(MPElementType type) {

    if (!type)
        return nil;

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            return @"Maximum Security Password";

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

NSString *NSStringShortFromMPElementType(MPElementType type) {

    if (!type)
        return nil;

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            return @"Maximum";

        case MPElementTypeGeneratedLong:
            return @"Long";

        case MPElementTypeGeneratedMedium:
            return @"Medium";

        case MPElementTypeGeneratedShort:
            return @"Short";

        case MPElementTypeGeneratedBasic:
            return @"Basic";

        case MPElementTypeGeneratedPIN:
            return @"PIN";

        case MPElementTypeStoredPersonal:
            return @"Personal";

        case MPElementTypeStoredDevicePrivate:
            return @"Device";

        default:
            Throw(@"Type not supported: %d", type);
    }
}

Class ClassFromMPElementType(MPElementType type) {

    if (!type)
        return nil;

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            return [MPElementGeneratedEntity class];

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
    if (!name.length) {
        err(@"Missing name.");
        return nil;
    }
    if (!key.length) {
        err(@"Missing key.");
        return nil;
    }
    if (!counter)
     // Counter unset, go into OTP mode.
     // Get the UNIX timestamp of the start of the interval of 5 minutes that the current time is in.
        counter = ((uint32_t)([[NSDate date] timeIntervalSince1970] / 300)) * 300;

    if (MPTypes_ciphers == nil)
        MPTypes_ciphers = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ciphers"
                                                                                            withExtension:@"plist"]];

    // Determine the seed whose bytes will be used for calculating a password
    uint32_t ncounter = htonl(counter), nnameLength = htonl(name.length);
    NSData *counterBytes = [NSData dataWithBytes:&ncounter length:sizeof(ncounter)];
    NSData *nameLengthBytes = [NSData dataWithBytes:&nnameLength length:sizeof(nnameLength)];
    trc(@"seed from: hmac-sha256(%@, 'com.lyndir.masterpassword' | %@ | %@ | %@)", [key encodeBase64], [nameLengthBytes encodeHex], name, [counterBytes encodeHex]);
    NSData *seed = [[NSData dataByConcatenatingDatas:
                             [@"com.lyndir.masterpassword" dataUsingEncoding:NSUTF8StringEncoding],
                             nameLengthBytes,
                             [name dataUsingEncoding:NSUTF8StringEncoding],
                             counterBytes,
                             nil]
                             hmacWith:PearlHashSHA256 key:key];
    trc(@"seed is: %@", [seed encodeBase64]);
    const char *seedBytes = seed.bytes;

    // Determine the cipher from the first seed byte.
    assert([seed length]);
    NSArray  *typeCiphers = [[MPTypes_ciphers valueForKey:ClassNameFromMPElementType(type)]
                                              valueForKey:NSStringFromMPElementType(type)];
    NSString *cipher      = [typeCiphers objectAtIndex:htons(seedBytes[0]) % [typeCiphers count]];
    trc(@"type %d, ciphers: %@, selected: %@", type, typeCiphers, cipher);

    // Encode the content, character by character, using subsequent seed bytes and the cipher.
    assert([seed length] >= [cipher length] + 1);
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        uint16_t keyByte = htons(seedBytes[c + 1]);
        NSString *cipherClass           = [cipher substringWithRange:NSMakeRange(c, 1)];
        NSString *cipherClassCharacters = [[MPTypes_ciphers valueForKey:@"MPCharacterClasses"] valueForKey:cipherClass];
        NSString *character             = [cipherClassCharacters substringWithRange:NSMakeRange(keyByte % [cipherClassCharacters length],
                                                                                                1)];

        trc(@"class %@ has characters: %@, index: %u, selected: %@", cipherClass, cipherClassCharacters, keyByte, character);
        [content appendString:character];
    }

    return content;
}
