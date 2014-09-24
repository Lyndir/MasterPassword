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

#import <objc/runtime.h>
#import "MPAlgorithmV2.h"
#import "MPEntities.h"

@implementation MPAlgorithmV2

- (NSUInteger)version {

    return 2;
}

- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit {

    if (site.version != [self version] - 1)
        // Only migrate from previous version.
        return NO;

    if (!explicit) {
        if (site.type & MPSiteTypeClassGenerated && site.name.length != [site.name dataUsingEncoding:NSUTF8StringEncoding].length) {
            // This migration requires explicit permission for types of the generated class.
            site.requiresExplicitMigration = YES;
            return NO;
        }
    }

    // Apply migration.
    site.requiresExplicitMigration = NO;
    site.version = [self version];
    return YES;
}

- (NSString *)generateContentForSiteNamed:(NSString *)name ofType:(MPSiteType)type withCounter:(NSUInteger)counter
                                  variant:(MPSiteVariant)variant context:(NSString *)context usingKey:(MPKey *)key {

    // Determine the seed whose bytes will be used for calculating a password
    NSData *nameBytes = [name dataUsingEncoding:NSUTF8StringEncoding];
    NSData *contextBytes = [context dataUsingEncoding:NSUTF8StringEncoding];
    uint32_t ncounter = htonl( counter ), nnameLength = htonl( nameBytes.length ), ncontextLength = htonl( contextBytes.length );
    NSData *counterBytes = [NSData dataWithBytes:&ncounter length:sizeof( ncounter )];
    NSData *nameLengthBytes = [NSData dataWithBytes:&nnameLength length:sizeof( nnameLength )];
    NSData *contextLengthBytes = [NSData dataWithBytes:&ncontextLength length:sizeof( ncontextLength )];
    NSString *scope = [self scopeForVariant:variant];
    NSData *scopeBytes = [scope dataUsingEncoding:NSUTF8StringEncoding];
    trc( @"seed from: hmac-sha256(%@, %@ | %@ | %@ | %@)",
            [[key keyID] encodeHex], scope, [nameLengthBytes encodeHex], name, [counterBytes encodeHex] );
    NSData *seed = [[NSData dataByConcatenatingDatas:
            scopeBytes,
            nameLengthBytes,
            nameBytes,
            counterBytes,
                    context? contextLengthBytes: nil,
            contextBytes,
                    nil]
            hmacWith:PearlHashSHA256 key:key.keyData];
    trc( @"seed is: %@", [seed encodeHex] );
    const unsigned char *seedBytes = seed.bytes;

    // Determine the cipher from the first seed byte.
    NSAssert( [seed length], @"Missing seed." );
    NSArray *typeCiphers = [self ciphersForType:type];
    NSString *cipher = typeCiphers[seedBytes[0] % [typeCiphers count]];
    trc( @"type %@ (%lu), ciphers: %@, selected: %@", [self nameOfType:type], (unsigned long)type, typeCiphers, cipher );

    // Encode the content, character by character, using subsequent seed bytes and the cipher.
    NSAssert( [seed length] >= [cipher length] + 1, @"Insufficient seed bytes to encode cipher." );
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        uint16_t keyByte = seedBytes[c + 1];
        NSString *cipherClass = [cipher substringWithRange:NSMakeRange( c, 1 )];
        NSString *cipherClassCharacters = [self charactersForCipherClass:cipherClass];
        NSString *character = [cipherClassCharacters substringWithRange:NSMakeRange( keyByte % [cipherClassCharacters length], 1 )];

        trc( @"class %@ has characters: %@, index: %u, selected: %@", cipherClass, cipherClassCharacters, keyByte, character );
        [content appendString:character];
    }

    return content;
}

@end
