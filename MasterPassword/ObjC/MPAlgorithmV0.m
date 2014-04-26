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

- (NSString *)description {

    return strf( @"<%@: version=%lu>", NSStringFromClass( [self class] ), (unsigned long)self.version );
}

- (BOOL)isEqual:(id)other {

    if (other == self)
        return YES;
    if (!other || ![other conformsToProtocol:@protocol(MPAlgorithm)])
        return NO;

    return [(id<MPAlgorithm>)other version] == [self version];
}

- (BOOL)migrateUser:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc {

    NSError *error = nil;
    NSFetchRequest *migrationRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
    migrationRequest.predicate = [NSPredicate predicateWithFormat:@"version_ < %d AND user == %@", self.version, user];
    NSArray *migrationElements = [moc executeFetchRequest:migrationRequest error:&error];
    if (!migrationElements) {
        err( @"While looking for elements to migrate: %@", error );
        return NO;
    }

    BOOL requiresExplicitMigration = NO;
    for (MPElementEntity *migrationElement in migrationElements)
        if (![migrationElement migrateExplicitly:NO])
            requiresExplicitMigration = YES;

    return requiresExplicitMigration;
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
    element.version = [self version];
    return YES;
}

- (MPKey *)keyForPassword:(NSString *)password ofUserNamed:(NSString *)userName {

    uint32_t nuserNameLength = htonl( userName.length );
    NSDate *start = [NSDate date];
    NSData *keyData = [PearlSCrypt deriveKeyWithLength:MP_dkLen fromPassword:[password dataUsingEncoding:NSUTF8StringEncoding]
                                             usingSalt:[NSData dataByConcatenatingDatas:
                                                     [@"com.lyndir.masterpassword" dataUsingEncoding:NSUTF8StringEncoding],
                                                     [NSData dataWithBytes:&nuserNameLength
                                                                    length:sizeof( nuserNameLength )],
                                                     [userName dataUsingEncoding:NSUTF8StringEncoding],
                                                     nil] N:MP_N r:MP_r p:MP_p];

    MPKey *key = [self keyFromKeyData:keyData];
    trc( @"User: %@, password: %@ derives to key ID: %@ (took %0.2fs)", userName, password, [key.keyID encodeHex],
                    -[start timeIntervalSinceNow] );

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

        case MPElementTypeGeneratedBasic:
            return @"Basic Password";

        case MPElementTypeGeneratedShort:
            return @"Short Password";

        case MPElementTypeGeneratedPIN:
            return @"PIN";

        case MPElementTypeStoredPersonal:
            return @"Personal Password";

        case MPElementTypeStoredDevicePrivate:
            return @"Device Private Password";
    }

    Throw( @"Type not supported: %lu", (long)type );
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

        case MPElementTypeGeneratedBasic:
            return @"Basic";

        case MPElementTypeGeneratedShort:
            return @"Short";

        case MPElementTypeGeneratedPIN:
            return @"PIN";

        case MPElementTypeStoredPersonal:
            return @"Personal";

        case MPElementTypeStoredDevicePrivate:
            return @"Device";
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSString *)classNameOfType:(MPElementType)type {

    return NSStringFromClass( [self classOfType:type] );
}

- (Class)classOfType:(MPElementType)type {

    if (!type)
        Throw( @"No type given." );

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            return [MPElementGeneratedEntity class];

        case MPElementTypeGeneratedLong:
            return [MPElementGeneratedEntity class];

        case MPElementTypeGeneratedMedium:
            return [MPElementGeneratedEntity class];

        case MPElementTypeGeneratedBasic:
            return [MPElementGeneratedEntity class];

        case MPElementTypeGeneratedShort:
            return [MPElementGeneratedEntity class];

        case MPElementTypeGeneratedPIN:
            return [MPElementGeneratedEntity class];

        case MPElementTypeStoredPersonal:
            return [MPElementStoredEntity class];

        case MPElementTypeStoredDevicePrivate:
            return [MPElementStoredEntity class];
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSArray *)allTypes {

    return [self allTypesStartingWith:MPElementTypeGeneratedMaximum];
}

- (NSArray *)allTypesStartingWith:(MPElementType)startingType {

    NSMutableArray *allTypes = [[NSMutableArray alloc] initWithCapacity:8];
    MPElementType currentType = startingType;
    do {
        [allTypes addObject:@(currentType)];
    } while ((currentType = [self nextType:currentType]) != startingType);

    return allTypes;
}

- (MPElementType)nextType:(MPElementType)type {

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            return MPElementTypeStoredDevicePrivate;
        case MPElementTypeGeneratedLong:
            return MPElementTypeGeneratedMaximum;
        case MPElementTypeGeneratedMedium:
            return MPElementTypeGeneratedLong;
        case MPElementTypeGeneratedBasic:
            return MPElementTypeGeneratedMedium;
        case MPElementTypeGeneratedShort:
            return MPElementTypeGeneratedBasic;
        case MPElementTypeGeneratedPIN:
            return MPElementTypeGeneratedShort;
        case MPElementTypeStoredPersonal:
            return MPElementTypeGeneratedPIN;
        case MPElementTypeStoredDevicePrivate:
            return MPElementTypeStoredPersonal;
        default:
            return MPElementTypeGeneratedLong;
    }
}

- (MPElementType)previousType:(MPElementType)type {

    MPElementType previousType = type, nextType = type;
    while ((nextType = [self nextType:nextType]) != type)
        previousType = nextType;

    return previousType;
}

- (NSString *)generateContentNamed:(NSString *)name ofType:(MPElementType)type withCounter:(NSUInteger)counter usingKey:(MPKey *)key {

    static NSDictionary *MPTypes_ciphers = nil;
    if (MPTypes_ciphers == nil)
        MPTypes_ciphers = [NSDictionary dictionaryWithContentsOfURL:
                [[NSBundle mainBundle] URLForResource:@"ciphers" withExtension:@"plist"]];

    // Determine the seed whose bytes will be used for calculating a password
    uint32_t ncounter = htonl( counter ), nnameLength = htonl( name.length );
    NSData *counterBytes = [NSData dataWithBytes:&ncounter length:sizeof( ncounter )];
    NSData *nameLengthBytes = [NSData dataWithBytes:&nnameLength length:sizeof( nnameLength )];
    trc( @"seed from: hmac-sha256(%@, 'com.lyndir.masterpassword' | %@ | %@ | %@)", [key.keyData encodeBase64],
                    [nameLengthBytes encodeHex], name, [counterBytes encodeHex] );
    NSData *seed = [[NSData dataByConcatenatingDatas:
            [@"com.lyndir.masterpassword" dataUsingEncoding:NSUTF8StringEncoding],
            nameLengthBytes, [name dataUsingEncoding:NSUTF8StringEncoding],
            counterBytes, nil]
            hmacWith:PearlHashSHA256 key:key.keyData];
    trc( @"seed is: %@", [seed encodeBase64] );
    const char *seedBytes = seed.bytes;

    // Determine the cipher from the first seed byte.
    NSAssert( [seed length], @"Missing seed." );
    NSString *typeClass = [self classNameOfType:type];
    NSString *typeName = [self nameOfType:type];
    id classCiphers = [MPTypes_ciphers valueForKey:typeClass];
    NSArray *typeCiphers = [classCiphers valueForKey:typeName];
    NSString *cipher = typeCiphers[htons( seedBytes[0] ) % [typeCiphers count]];
    trc( @"type %@, ciphers: %@, selected: %@", typeName, typeCiphers, cipher );

    // Encode the content, character by character, using subsequent seed bytes and the cipher.
    NSAssert( [seed length] >= [cipher length] + 1, @"Insufficient seed bytes to encode cipher." );
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        uint16_t keyByte = htons( seedBytes[c + 1] );
        NSString *cipherClass = [cipher substringWithRange:NSMakeRange( c, 1 )];
        NSString *cipherClassCharacters = [[MPTypes_ciphers valueForKey:@"MPCharacterClasses"] valueForKey:cipherClass];
        NSString *character = [cipherClassCharacters substringWithRange:NSMakeRange( keyByte % [cipherClassCharacters length], 1 )];

        trc( @"class %@ has characters: %@, index: %u, selected: %@", cipherClass, cipherClassCharacters, keyByte, character );
        [content appendString:character];
    }

    return content;
}

- (NSString *)storedContentForElement:(MPElementStoredEntity *)element usingKey:(MPKey *)key {

    return [self decryptContent:element.contentObject usingKey:key];
}

- (void)saveContent:(NSString *)clearContent toElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN: {
            NSAssert( NO, @"Cannot save content to element with generated type %lu.", (long)element.type );
            break;
        }

        case MPElementTypeStoredPersonal: {
            NSAssert( [element isKindOfClass:[MPElementStoredEntity class]],
                            @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.", (long)element.type,
                            [element class] );

            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:[elementKey subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
            ((MPElementStoredEntity *)element).contentObject = encryptedContent;
            break;
        }
        case MPElementTypeStoredDevicePrivate: {
            NSAssert( [element isKindOfClass:[MPElementStoredEntity class]],
                            @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.", (long)element.type,
                            [element class] );

            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:[elementKey subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
            NSDictionary *elementQuery = [self queryForDevicePrivateElementNamed:element.name];
            if (!encryptedContent)
                [PearlKeyChain deleteItemForQuery:elementQuery];
            else
                [PearlKeyChain addOrUpdateItemForQuery:elementQuery withAttributes:@{
                        (__bridge id)kSecValueData      : encryptedContent,
#if TARGET_OS_IPHONE
                        (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
#endif
                }];
            ((MPElementStoredEntity *)element).contentObject = nil;
            break;
        }
    }
}

- (NSString *)resolveContentForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolveContentForElement:element usingKey:elementKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (void)resolveContentForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN: {
            NSAssert( [element isKindOfClass:[MPElementGeneratedEntity class]],
                            @"Element with generated type %lu is not an MPElementGeneratedEntity, but a %@.", (long)element.type,
                            [element class] );

            NSString *name = element.name;
            MPElementType type = element.type;
            NSUInteger counter = ((MPElementGeneratedEntity *)element).counter;
            id<MPAlgorithm> algorithm = nil;
            if (!element.name.length)
                err( @"Missing name." );
            else if (!elementKey.keyData.length)
                err( @"Missing key." );
            else
                algorithm = element.algorithm;

            dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                NSString *result = [algorithm generateContentNamed:name ofType:type withCounter:counter usingKey:elementKey];
                resultBlock( result );
            } );
            break;
        }

        case MPElementTypeStoredPersonal: {
            NSAssert( [element isKindOfClass:[MPElementStoredEntity class]],
                            @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.", (long)element.type,
                            [element class] );

            NSData *encryptedContent = ((MPElementStoredEntity *)element).contentObject;

            dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                NSString *result = [self decryptContent:encryptedContent usingKey:elementKey];
                resultBlock( result );
            } );
            break;
        }
        case MPElementTypeStoredDevicePrivate: {
            NSAssert( [element isKindOfClass:[MPElementStoredEntity class]],
                            @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.", (long)element.type,
                            [element class] );

            NSDictionary *elementQuery = [self queryForDevicePrivateElementNamed:element.name];
            NSData *encryptedContent = [PearlKeyChain dataOfItemForQuery:elementQuery];

            dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                NSString *result = [self decryptContent:encryptedContent usingKey:elementKey];
                resultBlock( result );
            } );
            break;
        }
    }
}

- (void)importProtectedContent:(NSString *)protectedContent protectedByKey:(MPKey *)importKey
                   intoElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN:
            break;

        case MPElementTypeStoredPersonal: {
            NSAssert( [element isKindOfClass:[MPElementStoredEntity class]],
                            @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.", (long)element.type,
                            [element class] );
            if ([importKey.keyID isEqualToData:elementKey.keyID])
                ((MPElementStoredEntity *)element).contentObject = [protectedContent decodeBase64];

            else {
                NSString *clearContent = [self decryptContent:[protectedContent decodeBase64] usingKey:importKey];
                [self importClearTextContent:clearContent intoElement:element usingKey:elementKey];
            }
            break;
        }

        case MPElementTypeStoredDevicePrivate:
            break;
    }
}

- (void)importClearTextContent:(NSString *)clearContent intoElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN:
            break;

        case MPElementTypeStoredPersonal: {
            [self saveContent:clearContent toElement:element usingKey:elementKey];
            break;
        }

        case MPElementTypeStoredDevicePrivate:
            break;
    }
}

- (NSString *)exportContentForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    if (!(element.type & MPElementFeatureExportContent))
        return nil;

    NSString *result = nil;
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN: {
            result = nil;
            break;
        }

        case MPElementTypeStoredPersonal: {
            NSAssert( [element isKindOfClass:[MPElementStoredEntity class]],
                            @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.", (long)element.type,
                            [element class] );
            result = [((MPElementStoredEntity *)element).contentObject encodeBase64];
            break;
        }

        case MPElementTypeStoredDevicePrivate: {
            result = nil;
            break;
        }
    }

    return result;
}

- (BOOL)migrateExplicitly:(BOOL)explicit {

    return NO;
}

- (NSDictionary *)queryForDevicePrivateElementNamed:(NSString *)name {

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:@{
                                           (__bridge id)kSecAttrService : @"DevicePrivate",
                                           (__bridge id)kSecAttrAccount : name
                                   }
                                      matches:nil];
}

- (NSString *)decryptContent:(NSData *)encryptedContent usingKey:(MPKey *)key {

    NSData *decryptedContent = nil;
    if ([encryptedContent length])
        decryptedContent = [encryptedContent decryptWithSymmetricKey:[key subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
    if (!decryptedContent)
        return nil;

    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

@end
