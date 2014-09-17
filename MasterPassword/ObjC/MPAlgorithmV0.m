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
#import "MPAppDelegate_Shared.h"
#include <openssl/bn.h>
#include <openssl/err.h>

#define MP_N        32768
#define MP_r        8
#define MP_p        2
#define MP_dkLen    64
#define MP_hash     PearlHashSHA256

/* An AMD HD 7970 calculates 2495M SHA-1 hashes per second at a cost of ~350$ per GPU */
#define CRACKING_PER_SECOND 2495000000UL
#define CRACKING_PRICE      350

@implementation MPAlgorithmV0 {
    BN_CTX *ctx;
}

- (id)init {

    if (!(self = [super init]))
        return nil;

    ctx = BN_CTX_new();

    return self;
}

- (void)dealloc {

    BN_CTX_free( ctx );
    ctx = NULL;
}

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

- (NSString *)scopeForVariant:(MPElementVariant)variant {

    switch (variant) {
        case MPElementVariantPassword:
            return @"com.lyndir.masterpassword";
        case MPElementVariantLogin:
            return @"com.lyndir.masterpassword.login";
    }

    Throw( @"Unsupported variant: %ld", (long)variant );
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

        case MPElementTypeGeneratedName:
            return @"Login Name";

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

        case MPElementTypeGeneratedName:
            return @"Name";

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

        case MPElementTypeGeneratedName:
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
            return MPElementTypeGeneratedLong;
        case MPElementTypeGeneratedLong:
            return MPElementTypeGeneratedMedium;
        case MPElementTypeGeneratedMedium:
            return MPElementTypeGeneratedBasic;
        case MPElementTypeGeneratedBasic:
            return MPElementTypeGeneratedShort;
        case MPElementTypeGeneratedShort:
            return MPElementTypeGeneratedPIN;
        case MPElementTypeGeneratedPIN:
            return MPElementTypeStoredPersonal;
        case MPElementTypeStoredPersonal:
            return MPElementTypeStoredDevicePrivate;
        case MPElementTypeStoredDevicePrivate:
            return MPElementTypeGeneratedMaximum;
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

- (NSDictionary *)allCiphers {

    static NSDictionary *ciphers = nil;
    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        ciphers = [NSDictionary dictionaryWithContentsOfURL:
                [[NSBundle mainBundle] URLForResource:@"ciphers" withExtension:@"plist"]];
    } );

    return ciphers;
}

- (NSArray *)ciphersForType:(MPElementType)type {

    NSString *typeClass = [self classNameOfType:type];
    NSString *typeName = [self nameOfType:type];
    return [[[self allCiphers] valueForKey:typeClass] valueForKey:typeName];
}

- (NSArray *)cipherClasses {

    return [[[self allCiphers] valueForKey:@"MPCharacterClasses"] allKeys];
}

- (NSArray *)cipherClassCharacters {

    return [[[self allCiphers] valueForKey:@"MPCharacterClasses"] allValues];
}

- (NSString *)charactersForCipherClass:(NSString *)cipherClass {

    return [NSNullToNil( [NSNullToNil( [[self allCiphers] valueForKey:@"MPCharacterClasses"] ) valueForKey:cipherClass] ) copy];
}

- (NSString *)generateLoginForSiteNamed:(NSString *)name usingKey:(MPKey *)key {

    return [self generateContentForSiteNamed:name ofType:MPElementTypeGeneratedName withCounter:1
                                     variant:MPElementVariantLogin usingKey:key];
}

- (NSString *)generatePasswordForSiteNamed:(NSString *)name ofType:(MPElementType)type withCounter:(NSUInteger)counter
                                  usingKey:(MPKey *)key {

    return [self generateContentForSiteNamed:name ofType:type withCounter:counter
                                     variant:MPElementVariantPassword usingKey:key];
}

- (NSString *)generateContentForSiteNamed:(NSString *)name ofType:(MPElementType)type withCounter:(NSUInteger)counter
                                  variant:(MPElementVariant)variant usingKey:(MPKey *)key {

    // Determine the seed whose bytes will be used for calculating a password
    uint32_t ncounter = htonl( counter ), nnameLength = htonl( name.length );
    NSData *counterBytes = [NSData dataWithBytes:&ncounter length:sizeof( ncounter )];
    NSData *nameLengthBytes = [NSData dataWithBytes:&nnameLength length:sizeof( nnameLength )];
    NSString *scope = [self scopeForVariant:variant];
    trc( @"seed from: hmac-sha256(%@, %@ | %@ | %@ | %@)",
            [[key keyID] encodeHex], scope, [nameLengthBytes encodeHex], name, [counterBytes encodeHex] );
    NSData *seed = [[NSData dataByConcatenatingDatas:
            [scope dataUsingEncoding:NSUTF8StringEncoding],
            nameLengthBytes,
            [name dataUsingEncoding:NSUTF8StringEncoding],
            counterBytes,
                    nil]
            hmacWith:PearlHashSHA256 key:key.keyData];
    trc( @"seed is: %@", [seed encodeHex] );
    const char *seedBytes = seed.bytes;

    // Determine the cipher from the first seed byte.
    NSAssert( [seed length], @"Missing seed." );
    NSArray *typeCiphers = [self ciphersForType:type];
    NSString *cipher = typeCiphers[htons( seedBytes[0] ) % [typeCiphers count]];
    trc( @"type %@ (%lu), ciphers: %@, selected: %@", [self nameOfType:type], (unsigned long)type, typeCiphers, cipher );

    // Encode the content, character by character, using subsequent seed bytes and the cipher.
    NSAssert( [seed length] >= [cipher length] + 1, @"Insufficient seed bytes to encode cipher." );
    NSMutableString *content = [NSMutableString stringWithCapacity:[cipher length]];
    for (NSUInteger c = 0; c < [cipher length]; ++c) {
        uint16_t keyByte = htons( seedBytes[c + 1] );
        NSString *cipherClass = [cipher substringWithRange:NSMakeRange( c, 1 )];
        NSString *cipherClassCharacters = [self charactersForCipherClass:cipherClass];
        NSString *character = [cipherClassCharacters substringWithRange:NSMakeRange( keyByte % [cipherClassCharacters length], 1 )];

        trc( @"class %@ has characters: %@, index: %u, selected: %@", cipherClass, cipherClassCharacters, keyByte, character );
        [content appendString:character];
    }

    return content;
}

- (NSString *)storedLoginForElement:(MPElementStoredEntity *)element usingKey:(MPKey *)key {

    return nil;
}

- (NSString *)storedPasswordForElement:(MPElementStoredEntity *)element usingKey:(MPKey *)key {

    return [self decryptContent:element.contentObject usingKey:key];
}

- (BOOL)savePassword:(NSString *)clearContent toElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN:
        case MPElementTypeGeneratedName: {
            wrn( @"Cannot save content to element with generated type %lu.", (long)element.type );
            return NO;
        }

        case MPElementTypeStoredPersonal: {
            if (![element isKindOfClass:[MPElementStoredEntity class]]) {
                wrn( @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.",
                        (long)element.type, [element class] );
                return NO;
            }

            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:[elementKey subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
            if ([((MPElementStoredEntity *)element).contentObject isEqualToData:encryptedContent])
                return NO;

            ((MPElementStoredEntity *)element).contentObject = encryptedContent;
            return YES;
        }
        case MPElementTypeStoredDevicePrivate: {
            if (![element isKindOfClass:[MPElementStoredEntity class]]) {
                wrn( @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.",
                        (long)element.type, [element class] );
                return NO;
            }

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
            return YES;
        }
    }

    Throw( @"Unsupported type: %ld", (long)element.type );
}

- (NSString *)resolveLoginForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolveLoginForElement:element usingKey:elementKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (NSString *)resolvePasswordForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolvePasswordForElement:element usingKey:elementKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (void)resolveLoginForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    NSString *name = element.name;
    BOOL loginGenerated = element.loginGenerated && [[MPAppDelegate_Shared get] isPurchased:MPProductGenerateLogins];
    NSString *loginName = loginGenerated? nil: element.loginName;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!elementKey.keyData.length)
        err( @"Missing key." );
    else
        algorithm = element.algorithm;

    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        if (loginGenerated)
            resultBlock( [algorithm generateLoginForSiteNamed:name usingKey:elementKey] );
        else
            resultBlock( loginName );
    } );
}

- (void)resolvePasswordForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN:
        case MPElementTypeGeneratedName: {
            if (![element isKindOfClass:[MPElementGeneratedEntity class]]) {
                wrn( @"Element with generated type %lu is not an MPElementGeneratedEntity, but a %@.",
                        (long)element.type, [element class] );
                break;
            }

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
                NSString *result = [algorithm generatePasswordForSiteNamed:name ofType:type withCounter:counter usingKey:elementKey];
                resultBlock( result );
            } );
            break;
        }

        case MPElementTypeStoredPersonal: {
            if (![element isKindOfClass:[MPElementStoredEntity class]]) {
                wrn( @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.",
                        (long)element.type, [element class] );
                break;
            }

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

- (void)importProtectedPassword:(NSString *)protectedContent protectedByKey:(MPKey *)importKey
                    intoElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN:
        case MPElementTypeGeneratedName:
            break;

        case MPElementTypeStoredPersonal: {
            if (![element isKindOfClass:[MPElementStoredEntity class]]) {
                wrn( @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.",
                        (long)element.type, [element class] );
                break;
            }
            if ([importKey.keyID isEqualToData:elementKey.keyID])
                ((MPElementStoredEntity *)element).contentObject = [protectedContent decodeBase64];

            else {
                NSString *clearContent = [self decryptContent:[protectedContent decodeBase64] usingKey:importKey];
                [self importClearTextPassword:clearContent intoElement:element usingKey:elementKey];
            }
            break;
        }

        case MPElementTypeStoredDevicePrivate:
            break;
    }
}

- (void)importClearTextPassword:(NSString *)clearContent intoElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

    NSAssert( [elementKey.keyID isEqualToData:element.user.keyID], @"Element does not belong to current user." );
    switch (element.type) {
        case MPElementTypeGeneratedMaximum:
        case MPElementTypeGeneratedLong:
        case MPElementTypeGeneratedMedium:
        case MPElementTypeGeneratedBasic:
        case MPElementTypeGeneratedShort:
        case MPElementTypeGeneratedPIN:
        case MPElementTypeGeneratedName:
            break;

        case MPElementTypeStoredPersonal: {
            [self savePassword:clearContent toElement:element usingKey:elementKey];
            break;
        }

        case MPElementTypeStoredDevicePrivate:
            break;
    }
}

- (NSString *)exportPasswordForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey {

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
        case MPElementTypeGeneratedPIN:
        case MPElementTypeGeneratedName: {
            result = nil;
            break;
        }

        case MPElementTypeStoredPersonal: {
            if (![element isKindOfClass:[MPElementStoredEntity class]]) {
                wrn( @"Element with stored type %lu is not an MPElementStoredEntity, but a %@.",
                        (long)element.type, [element class] );
                break;
            }
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

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPElementType)type byAttacker:(MPAttacker)attacker {

    if (!type)
        return NO;
    NSArray *ciphers = [self ciphersForType:type];
    if (!ciphers)
        return NO;

    BIGNUM *permutations = BN_new(), *cipherPermutations = BN_new();
    for (NSString *cipher in ciphers) {
        BN_one( cipherPermutations );

        for (NSUInteger c = 0; c < [cipher length]; ++c)
            BN_mul_word( cipherPermutations,
                    (BN_ULONG)[[self charactersForCipherClass:[cipher substringWithRange:NSMakeRange( c, 1 )]] length] );

        BN_add( permutations, permutations, cipherPermutations );
    }
    BN_free( cipherPermutations );

    return [self timeToCrack:timeToCrack permutations:permutations forAttacker:attacker];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordString:(NSString *)password byAttacker:(MPAttacker)attacker {

    BIGNUM *permutations = BN_new();
    BN_one( permutations );

    NSMutableString *cipher = [NSMutableString new];
    for (NSUInteger c = 0; c < [password length]; ++c) {
        NSString *passwordCharacter = [password substringWithRange:NSMakeRange( c, 1 )];

        unsigned int characterEntropy = 0;
        for (NSString *cipherClass in @[ @"v", @"c", @"a", @"x" ]) {
            NSString *charactersForClass = [self charactersForCipherClass:cipherClass];

            if ([charactersForClass rangeOfString:passwordCharacter].location != NSNotFound) {
                // Found class for password character.
                characterEntropy = (BN_ULONG)[charactersForClass length];
                [cipher appendString:cipherClass];
                break;
            }
        }
        if (!characterEntropy) {
            [cipher appendString:@"b"];
            characterEntropy = 256 /* a byte */;
        }

        BN_mul_word( permutations, characterEntropy );
    }

    return [self timeToCrack:timeToCrack permutations:permutations forAttacker:attacker];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack permutations:(BIGNUM *)permutations forAttacker:(MPAttacker)attacker {

    // Determine base seconds needed to calculate the permutations.
    BIGNUM *secondsToCrack = BN_dup( permutations );
    BN_div_word( secondsToCrack, CRACKING_PER_SECOND );

    // Modify seconds needed by applying our hardware budget.
    switch (attacker) {
        case MPAttacker1:
            break;
        case MPAttacker5K:
            BN_mul_word( secondsToCrack, CRACKING_PRICE );
            BN_div_word( secondsToCrack, 5000 );
            break;
        case MPAttacker20M:
            BN_mul_word( secondsToCrack, CRACKING_PRICE );
            BN_div_word( secondsToCrack, 20000000 );
            break;
        case MPAttacker5B:
            BN_mul_word( secondsToCrack, CRACKING_PRICE );
            BN_div_word( secondsToCrack, 5000 );
            BN_div_word( secondsToCrack, 1000000 );
            break;
    }

    BIGNUM *max = BN_new();
    BN_set_word( max, (BN_ULONG)-1 );

    BIGNUM *hoursToCrack = BN_dup( secondsToCrack );
    BN_div_word( hoursToCrack, 3600 );
    if (BN_cmp( hoursToCrack, max ) < 0)
        timeToCrack->hours = BN_get_word( hoursToCrack );
    else
        timeToCrack->hours = (BN_ULONG)-1;

    BIGNUM *daysToCrack = BN_dup( hoursToCrack );
    BN_div_word( daysToCrack, 24 );
    if (BN_cmp( daysToCrack, max ) < 0)
        timeToCrack->days = BN_get_word( daysToCrack );
    else
        timeToCrack->days = (BN_ULONG)-1;

    BIGNUM *weeksToCrack = BN_dup( daysToCrack );
    BN_div_word( weeksToCrack, 7 );
    if (BN_cmp( weeksToCrack, max ) < 0)
        timeToCrack->weeks = BN_get_word( weeksToCrack );
    else
        timeToCrack->weeks = (BN_ULONG)-1;

    BIGNUM *monthsToCrack = BN_dup( daysToCrack );
    BN_div_word( monthsToCrack, 31 );
    if (BN_cmp( monthsToCrack, max ) < 0)
        timeToCrack->months = BN_get_word( monthsToCrack );
    else
        timeToCrack->months = (BN_ULONG)-1;

    BIGNUM *yearsToCrack = BN_dup( daysToCrack );
    BN_div_word( yearsToCrack, 356 );
    if (BN_cmp( yearsToCrack, max ) < 0)
        timeToCrack->years = BN_get_word( yearsToCrack );
    else
        timeToCrack->years = (BN_ULONG)-1;

    BIGNUM *universesToCrack = BN_dup( yearsToCrack );
    BN_div_word( universesToCrack, 14000 );
    BN_div_word( universesToCrack, 1000000 );
    if (BN_cmp( universesToCrack, max ) < 0)
        timeToCrack->universes = BN_get_word( universesToCrack );
    else
        timeToCrack->universes = (BN_ULONG)-1;

    for (unsigned long error = ERR_get_error(); error; error = ERR_get_error())
        err( @"bignum error: %lu", error );

    BN_free( max );
    BN_free( permutations );
    BN_free( secondsToCrack );
    BN_free( hoursToCrack );
    BN_free( daysToCrack );
    BN_free( weeksToCrack );
    BN_free( monthsToCrack );
    BN_free( yearsToCrack );
    BN_free( universesToCrack );

    return YES;
}

@end
