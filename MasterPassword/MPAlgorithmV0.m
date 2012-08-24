/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  MPAlgorithmV0
//
//  Created by Maarten Billemont on 16/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAlgorithmV0.h"
#import "MPEntities.h"

#define MP_N        32768
#define MP_r        8
#define MP_p        2
#define MP_dkLen    64
#define MP_hash     PearlHashSHA256

@implementation MPAlgorithmV0

- (NSUInteger)version {

    return 0;
}

- (BOOL)migrateElement:(MPElementEntity *)element explicit:(BOOL)explicit {

    if (element.version != [self version] - 1)
     // Only migrate from previous version.
        return NO;

    if (!explicit) {
        // This migration requires explicit permission.
        element.requiresExplicitMigration = YES;
        return NO;
    }

    // Apply migration.
    element.requiresExplicitMigration = NO;
    element.version                   = [self version];
    return YES;
}

- (MPKey *)keyForPassword:(NSString *)password ofUserNamed:(NSString *)userName {

    uint32_t nuserNameLength = htonl(userName.length);
    NSDate *start   = [NSDate date];
    NSData *keyData = [PearlSCrypt deriveKeyWithLength:MP_dkLen fromPassword:[password dataUsingEncoding:NSUTF8StringEncoding]
     usingSalt:[NSData dataByConcatenatingDatas:
                        [@"com.lyndir.masterpassword" dataUsingEncoding:NSUTF8StringEncoding],
                        [NSData dataWithBytes:&nuserNameLength
                                       length:sizeof(nuserNameLength)],
                        [userName dataUsingEncoding:NSUTF8StringEncoding],
                        nil] N:MP_N r:MP_r p:MP_p];

    MPKey *key = [self keyFromKeyData:keyData];
    trc(@"User: %@, password: %@ derives to key ID: %@ (took %0.2fs)", userName, password, [key.keyID encodeHex], -[start timeIntervalSinceNow]);

    return key;
}

- (MPKey *)keyFromKeyData:(NSData *)keyData {

    return [[MPKey alloc] initWithKeyData:keyData algorithm:self];
}

- (NSData *)keyIDForKeyData:(NSData *)keyData {

    return [keyData hashWith:MP_hash];
}

- (NSString *)nameOfType:(MPElementType)type {

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
    }

    Throw(@"Type not supported: %d", type);
}

- (NSString *)shortNameOfType:(MPElementType)type {

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
    }

    Throw(@"Type not supported: %d", type);
}

- (NSString *)classNameOfType:(MPElementType)type {

    return NSStringFromClass([self classOfType:type]);
}

- (Class)classOfType:(MPElementType)type {

    if (!type)
        Throw(@"No type given.");

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
    }

    Throw(@"Type not supported: %d", type);
}

- (NSString *)generateContentForElement:(MPElementGeneratedEntity *)element usingKey:(MPKey *)key {

    static NSDictionary *MPTypes_ciphers = nil;

    if (!element)
        return nil;

    if (!(element.type & MPElementTypeClassGenerated)) {
        err(@"Incorrect type (is not MPElementTypeClassGenerated): %@, for: %@", [self nameOfType:element.type], element.name);
        return nil;
    }
    if (!element.name.length) {
        err(@"Missing name.");
        return nil;
    }
    if (!key.keyData.length) {
        err(@"Missing key.");
        return nil;
    }

    if (MPTypes_ciphers == nil)
        MPTypes_ciphers = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ciphers"
                                                                                            withExtension:@"plist"]];

    // Determine the seed whose bytes will be used for calculating a password
    uint32_t ncounter = htonl(element.counter), nnameLength = htonl(element.name.length);
    NSData *counterBytes    = [NSData dataWithBytes:&ncounter length:sizeof(ncounter)];
    NSData *nameLengthBytes = [NSData dataWithBytes:&nnameLength length:sizeof(nnameLength)];
    trc(@"seed from: hmac-sha256(%@, 'com.lyndir.masterpassword' | %@ | %@ | %@)", [key.keyData encodeBase64], [nameLengthBytes encodeHex], element.name, [counterBytes encodeHex]);
    NSData *seed = [[NSData dataByConcatenatingDatas:
                             [@"com.lyndir.masterpassword" dataUsingEncoding:NSUTF8StringEncoding],
                             nameLengthBytes,
                             [element.name dataUsingEncoding:NSUTF8StringEncoding],
                             counterBytes,
                             nil]
                             hmacWith:PearlHashSHA256 key:key.keyData];
    trc(@"seed is: %@", [seed encodeBase64]);
    const char *seedBytes = seed.bytes;

    // Determine the cipher from the first seed byte.
    assert([seed length]);
    NSArray  *typeCiphers = [[MPTypes_ciphers valueForKey:[self classNameOfType:element.type]]
                                              valueForKey:[self nameOfType:element.type]];
    NSString *cipher      = [typeCiphers objectAtIndex:htons(seedBytes[0]) % [typeCiphers count]];
    trc(@"type %@, ciphers: %@, selected: %@", [self nameOfType:element.type], typeCiphers, cipher);

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

@end
