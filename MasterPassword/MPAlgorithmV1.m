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
//  MPAlgorithmV1
//
//  Created by Maarten Billemont on 17/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAlgorithmV1.h"
#import "MPEntities.h"


@implementation MPAlgorithmV1

- (NSUInteger)version {

    return 1;
}

- (BOOL)migrateElement:(MPElementEntity *)element explicit:(BOOL)explicit {

    if (element.version != [self version] - 1)
     // Only migrate from previous version.
        return NO;

    if (!explicit) {
        if (element.type & MPElementTypeClassGenerated) {
            // This migration requires explicit permission for types of the generated class.
            element.requiresExplicitMigration = YES;
            return NO;
        }
    }

    // Apply migration.
    element.requiresExplicitMigration = NO;
    element.version                   = [self version];
    return YES;
}

- (NSString *)generateContentForElement:(MPElementGeneratedEntity *)element usingKey:(MPKey *)key {

    static NSDictionary *MPTypes_ciphers = nil;

    if (!element)
        return nil;

    if (!(element.type & MPElementTypeClassGenerated)) {
        err(@"Incorrect type (is not MPElementTypeClassGenerated): %d, for: %@", [self nameOfType:element.type], element.name);
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
    const unsigned char *seedBytes = seed.bytes;

    // Determine the cipher from the first seed byte.
    assert([seed length]);
    NSArray  *typeCiphers = [[MPTypes_ciphers valueForKey:[self classNameOfType:element.type]]
                                              valueForKey:[self nameOfType:element.type]];
    NSString *cipher      = [typeCiphers objectAtIndex:seedBytes[0] % [typeCiphers count]];
    trc(@"type %@, ciphers: %@, selected: %@", [self nameOfType:element.type], typeCiphers, cipher);

    // Encode the content, character by character, using subsequent seed bytes and the cipher.
    assert([seed length] >= [cipher length] + 1);
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        uint16_t keyByte = seedBytes[c + 1];
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
