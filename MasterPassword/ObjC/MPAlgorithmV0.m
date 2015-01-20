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
#import "MPAppDelegate_InApp.h"
#import "mpw-util.h"
#import "mpw-types.h"
#include <openssl/bn.h>
#include <openssl/err.h>

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

- (MPAlgorithmVersion)version {

    return MPAlgorithmVersion0;
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

- (BOOL)tryMigrateUser:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc {

    NSError *error = nil;
    NSFetchRequest *migrationRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
    migrationRequest.predicate = [NSPredicate predicateWithFormat:@"version_ < %d AND user == %@", self.version, user];
    NSArray *migrationSites = [moc executeFetchRequest:migrationRequest error:&error];
    if (!migrationSites) {
        err( @"While looking for sites to migrate: %@", [error fullDescription] );
        return NO;
    }

    BOOL success = YES;
    for (MPSiteEntity *migrationSite in migrationSites)
        if (![migrationSite tryMigrateExplicitly:NO])
            success = NO;

    return success;
}

- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit {

    if (site.version != [self version] - 1)
        // Only migrate from previous version.
        return NO;

    if (!explicit) {
        // This migration requires explicit permission.
        site.requiresExplicitMigration = YES;
        return NO;
    }

    // Apply migration.
    site.requiresExplicitMigration = NO;
    site.version = [self version];
    return YES;
}

- (MPKey *)keyForPassword:(NSString *)password ofUserNamed:(NSString *)userName {

    NSDate *start = [NSDate date];
    uint8_t const *masterKeyBytes = mpw_masterKeyForUser( userName.UTF8String, password.UTF8String, [self version] );
    MPKey *masterKey = [self keyFromKeyData:[NSData dataWithBytes:masterKeyBytes length:MP_dkLen]];
    mpw_free( masterKeyBytes, MP_dkLen );
    trc( @"User: %@, password: %@ derives to key ID: %@ (took %0.2fs)", userName, password, [masterKey.keyID encodeHex],
            -[start timeIntervalSinceNow] );
    return masterKey;
}

- (MPKey *)keyFromKeyData:(NSData *)keyData {

    return [[MPKey alloc] initWithKeyData:keyData algorithm:self];
}

- (NSData *)keyIDForKeyData:(NSData *)keyData {

    return [keyData hashWith:PearlHashSHA256];
}

- (NSString *)nameOfType:(MPSiteType)type {

    if (!type)
        return nil;

    switch (type) {
        case MPSiteTypeGeneratedMaximum:
            return @"Maximum Security Password";

        case MPSiteTypeGeneratedLong:
            return @"Long Password";

        case MPSiteTypeGeneratedMedium:
            return @"Medium Password";

        case MPSiteTypeGeneratedBasic:
            return @"Basic Password";

        case MPSiteTypeGeneratedShort:
            return @"Short Password";

        case MPSiteTypeGeneratedPIN:
            return @"PIN";

        case MPSiteTypeGeneratedName:
            return @"Login Name";

        case MPSiteTypeGeneratedPhrase:
            return @"Phrase";

        case MPSiteTypeStoredPersonal:
            return @"Personal Password";

        case MPSiteTypeStoredDevicePrivate:
            return @"Device Private Password";
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSString *)shortNameOfType:(MPSiteType)type {

    if (!type)
        return nil;

    switch (type) {
        case MPSiteTypeGeneratedMaximum:
            return @"Maximum";

        case MPSiteTypeGeneratedLong:
            return @"Long";

        case MPSiteTypeGeneratedMedium:
            return @"Medium";

        case MPSiteTypeGeneratedBasic:
            return @"Basic";

        case MPSiteTypeGeneratedShort:
            return @"Short";

        case MPSiteTypeGeneratedPIN:
            return @"PIN";

        case MPSiteTypeGeneratedName:
            return @"Name";

        case MPSiteTypeGeneratedPhrase:
            return @"Phrase";

        case MPSiteTypeStoredPersonal:
            return @"Personal";

        case MPSiteTypeStoredDevicePrivate:
            return @"Device";
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSString *)classNameOfType:(MPSiteType)type {

    return NSStringFromClass( [self classOfType:type] );
}

- (Class)classOfType:(MPSiteType)type {

    if (!type)
        Throw( @"No type given." );

    switch (type) {
        case MPSiteTypeGeneratedMaximum:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedLong:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedMedium:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedBasic:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedShort:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedPIN:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedName:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeGeneratedPhrase:
            return [MPGeneratedSiteEntity class];

        case MPSiteTypeStoredPersonal:
            return [MPStoredSiteEntity class];

        case MPSiteTypeStoredDevicePrivate:
            return [MPStoredSiteEntity class];
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSArray *)allTypes {

    return [self allTypesStartingWith:MPSiteTypeGeneratedMaximum];
}

- (NSArray *)allTypesStartingWith:(MPSiteType)startingType {

    NSMutableArray *allTypes = [[NSMutableArray alloc] initWithCapacity:8];
    MPSiteType currentType = startingType;
    do {
        [allTypes addObject:@(currentType)];
    } while ((currentType = [self nextType:currentType]) != startingType);

    return allTypes;
}

- (MPSiteType)nextType:(MPSiteType)type {

    switch (type) {
        case MPSiteTypeGeneratedMaximum:
            return MPSiteTypeGeneratedLong;
        case MPSiteTypeGeneratedLong:
            return MPSiteTypeGeneratedMedium;
        case MPSiteTypeGeneratedMedium:
            return MPSiteTypeGeneratedBasic;
        case MPSiteTypeGeneratedBasic:
            return MPSiteTypeGeneratedShort;
        case MPSiteTypeGeneratedShort:
            return MPSiteTypeGeneratedPIN;
        case MPSiteTypeGeneratedPIN:
            return MPSiteTypeStoredPersonal;
        case MPSiteTypeStoredPersonal:
            return MPSiteTypeStoredDevicePrivate;
        case MPSiteTypeStoredDevicePrivate:
            return MPSiteTypeGeneratedMaximum;
        default:
            return MPSiteTypeGeneratedLong;
    }
}

- (MPSiteType)previousType:(MPSiteType)type {

    MPSiteType previousType = type, nextType = type;
    while ((nextType = [self nextType:nextType]) != type)
        previousType = nextType;

    return previousType;
}

- (NSString *)generateLoginForSiteNamed:(NSString *)name usingKey:(MPKey *)key {

    return [self generateContentForSiteNamed:name ofType:MPSiteTypeGeneratedName withCounter:1
                                     variant:MPSiteVariantLogin context:nil usingKey:key];
}

- (NSString *)generatePasswordForSiteNamed:(NSString *)name ofType:(MPSiteType)type withCounter:(NSUInteger)counter
                                  usingKey:(MPKey *)key {

    return [self generateContentForSiteNamed:name ofType:type withCounter:counter
                                     variant:MPSiteVariantPassword context:nil usingKey:key];
}

- (NSString *)generateAnswerForSiteNamed:(NSString *)name onQuestion:(NSString *)question usingKey:(MPKey *)key {

    return [self generateContentForSiteNamed:name ofType:MPSiteTypeGeneratedPhrase withCounter:1
                                     variant:MPSiteVariantAnswer context:question usingKey:key];
}

- (NSString *)generateContentForSiteNamed:(NSString *)name ofType:(MPSiteType)type withCounter:(NSUInteger)counter
                                  variant:(MPSiteVariant)variant context:(NSString *)context usingKey:(MPKey *)key {

    char const *contentBytes = mpw_passwordForSite( key.keyData.bytes, name.UTF8String, type, (uint32_t)counter,
            variant, context.UTF8String, [self version] );
    NSString *content = [NSString stringWithCString:contentBytes encoding:NSUTF8StringEncoding];
    mpw_freeString( contentBytes );

    return content;
}

- (NSString *)storedLoginForSite:(MPStoredSiteEntity *)site usingKey:(MPKey *)key {

    return nil;
}

- (NSString *)storedPasswordForSite:(MPStoredSiteEntity *)site usingKey:(MPKey *)key {

    return [self decryptContent:site.contentObject usingKey:key];
}

- (BOOL)savePassword:(NSString *)clearContent toSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    switch (site.type) {
        case MPSiteTypeGeneratedMaximum:
        case MPSiteTypeGeneratedLong:
        case MPSiteTypeGeneratedMedium:
        case MPSiteTypeGeneratedBasic:
        case MPSiteTypeGeneratedShort:
        case MPSiteTypeGeneratedPIN:
        case MPSiteTypeGeneratedName:
        case MPSiteTypeGeneratedPhrase: {
            wrn( @"Cannot save content to site with generated type %lu.", (long)site.type );
            return NO;
        }

        case MPSiteTypeStoredPersonal: {
            if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
                wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                return NO;
            }

            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:[siteKey subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
            if ([((MPStoredSiteEntity *)site).contentObject isEqualToData:encryptedContent])
                return NO;

            ((MPStoredSiteEntity *)site).contentObject = encryptedContent;
            return YES;
        }
        case MPSiteTypeStoredDevicePrivate: {
            if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
                wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                return NO;
            }

            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:[siteKey subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
            NSDictionary *siteQuery = [self queryForDevicePrivateSiteNamed:site.name];
            if (!encryptedContent)
                [PearlKeyChain deleteItemForQuery:siteQuery];
            else
                [PearlKeyChain addOrUpdateItemForQuery:siteQuery withAttributes:@{
                        (__bridge id)kSecValueData      : encryptedContent,
#if TARGET_OS_IPHONE
                        (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
#endif
                }];
            ((MPStoredSiteEntity *)site).contentObject = nil;
            return YES;
        }
    }

    Throw( @"Unsupported type: %ld", (long)site.type );
}

- (NSString *)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolveLoginForSite:site usingKey:siteKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (NSString *)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolvePasswordForSite:site usingKey:siteKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (NSString *)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolveAnswerForSite:site usingKey:siteKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (NSString *)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)siteKey {

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter( group );
    __block NSString *result = nil;
    [self resolveAnswerForQuestion:question usingKey:siteKey result:^(NSString *result_) {
        result = result_;
        dispatch_group_leave( group );
    }];
    dispatch_group_wait( group, DISPATCH_TIME_FOREVER );

    return result;
}

- (void)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    BOOL loginGenerated = site.loginGenerated && [[MPAppDelegate_Shared get] isFeatureUnlocked:MPProductGenerateLogins];
    NSString *loginName = loginGenerated? nil: site.loginName;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!siteKey.keyData.length)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        if (loginGenerated)
            resultBlock( [algorithm generateLoginForSiteNamed:name usingKey:siteKey] );
        else
            resultBlock( loginName );
    } );
}

- (void)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    switch (site.type) {
        case MPSiteTypeGeneratedMaximum:
        case MPSiteTypeGeneratedLong:
        case MPSiteTypeGeneratedMedium:
        case MPSiteTypeGeneratedBasic:
        case MPSiteTypeGeneratedShort:
        case MPSiteTypeGeneratedPIN:
        case MPSiteTypeGeneratedName:
        case MPSiteTypeGeneratedPhrase: {
            if (![site isKindOfClass:[MPGeneratedSiteEntity class]]) {
                wrn( @"Site with generated type %lu is not an MPGeneratedSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                break;
            }

            NSString *name = site.name;
            MPSiteType type = site.type;
            NSUInteger counter = ((MPGeneratedSiteEntity *)site).counter;
            id<MPAlgorithm> algorithm = nil;
            if (!site.name.length)
                err( @"Missing name." );
            else if (!siteKey.keyData.length)
                err( @"Missing key." );
            else
                algorithm = site.algorithm;

            dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                NSString *result = [algorithm generatePasswordForSiteNamed:name ofType:type withCounter:counter usingKey:siteKey];
                resultBlock( result );
            } );
            break;
        }

        case MPSiteTypeStoredPersonal: {
            if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
                wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                break;
            }

            NSData *encryptedContent = ((MPStoredSiteEntity *)site).contentObject;

            dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                NSString *result = [self decryptContent:encryptedContent usingKey:siteKey];
                resultBlock( result );
            } );
            break;
        }
        case MPSiteTypeStoredDevicePrivate: {
            NSAssert( [site isKindOfClass:[MPStoredSiteEntity class]],
                    @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.", (long)site.type,
                    [site class] );

            NSDictionary *siteQuery = [self queryForDevicePrivateSiteNamed:site.name];
            NSData *encryptedContent = [PearlKeyChain dataOfItemForQuery:siteQuery];

            dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
                NSString *result = [self decryptContent:encryptedContent usingKey:siteKey];
                resultBlock( result );
            } );
            break;
        }
    }
}

- (void)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    id<MPAlgorithm> algorithm = nil;
    if (!site.name.length)
        err( @"Missing name." );
    else if (!siteKey.keyData.length)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        NSString *result = [algorithm generateAnswerForSiteNamed:name onQuestion:nil usingKey:siteKey];
        resultBlock( result );
    } );
}

- (void)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)siteKey
                          result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [siteKey.keyID isEqualToData:question.site.user.keyID], @"Site does not belong to current user." );
    NSString *name = question.site.name;
    NSString *keyword = question.keyword;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!siteKey.keyData.length)
        err( @"Missing key." );
    else
        algorithm = question.site.algorithm;

    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        NSString *result = [algorithm generateAnswerForSiteNamed:name onQuestion:keyword usingKey:siteKey];
        resultBlock( result );
    } );
}

- (void)importProtectedPassword:(NSString *)protectedContent protectedByKey:(MPKey *)importKey
                       intoSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    switch (site.type) {
        case MPSiteTypeGeneratedMaximum:
        case MPSiteTypeGeneratedLong:
        case MPSiteTypeGeneratedMedium:
        case MPSiteTypeGeneratedBasic:
        case MPSiteTypeGeneratedShort:
        case MPSiteTypeGeneratedPIN:
        case MPSiteTypeGeneratedName:
        case MPSiteTypeGeneratedPhrase:
            break;

        case MPSiteTypeStoredPersonal: {
            if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
                wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                break;
            }
            if ([importKey.keyID isEqualToData:siteKey.keyID])
                ((MPStoredSiteEntity *)site).contentObject = [protectedContent decodeBase64];

            else {
                NSString *clearContent = [self decryptContent:[protectedContent decodeBase64] usingKey:importKey];
                [self importClearTextPassword:clearContent intoSite:site usingKey:siteKey];
            }
            break;
        }

        case MPSiteTypeStoredDevicePrivate:
            break;
    }
}

- (void)importClearTextPassword:(NSString *)clearContent intoSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    switch (site.type) {
        case MPSiteTypeGeneratedMaximum:
        case MPSiteTypeGeneratedLong:
        case MPSiteTypeGeneratedMedium:
        case MPSiteTypeGeneratedBasic:
        case MPSiteTypeGeneratedShort:
        case MPSiteTypeGeneratedPIN:
        case MPSiteTypeGeneratedName:
        case MPSiteTypeGeneratedPhrase:
            break;

        case MPSiteTypeStoredPersonal: {
            [self savePassword:clearContent toSite:site usingKey:siteKey];
            break;
        }

        case MPSiteTypeStoredDevicePrivate:
            break;
    }
}

- (NSString *)exportPasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    NSAssert( [siteKey.keyID isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    if (!(site.type & MPSiteFeatureExportContent))
        return nil;

    NSString *result = nil;
    switch (site.type) {
        case MPSiteTypeGeneratedMaximum:
        case MPSiteTypeGeneratedLong:
        case MPSiteTypeGeneratedMedium:
        case MPSiteTypeGeneratedBasic:
        case MPSiteTypeGeneratedShort:
        case MPSiteTypeGeneratedPIN:
        case MPSiteTypeGeneratedName:
        case MPSiteTypeGeneratedPhrase: {
            result = nil;
            break;
        }

        case MPSiteTypeStoredPersonal: {
            if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
                wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                break;
            }
            result = [((MPStoredSiteEntity *)site).contentObject encodeBase64];
            break;
        }

        case MPSiteTypeStoredDevicePrivate: {
            result = nil;
            break;
        }
    }

    return result;
}

- (BOOL)migrateExplicitly:(BOOL)explicit {

    return NO;
}

- (NSDictionary *)queryForDevicePrivateSiteNamed:(NSString *)name {

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:@{
                                           (__bridge id)kSecAttrService : @"DevicePrivate",
                                           (__bridge id)kSecAttrAccount : name
                                   }
                                      matches:nil];
}

- (NSString *)decryptContent:(NSData *)encryptedContent usingKey:(MPKey *)key {

    if (!key)
        return nil;
    NSData *decryptedContent = nil;
    if ([encryptedContent length])
        decryptedContent = [encryptedContent decryptWithSymmetricKey:[key subKeyOfLength:PearlCryptKeySize].keyData padding:YES];
    if (!decryptedContent)
        return nil;

    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPSiteType)type byAttacker:(MPAttacker)attacker {

    if (!type)
        return NO;
    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    if (!templates)
        return NO;

    BIGNUM *permutations = BN_new(), *templatePermutations = BN_new();
    for (size_t t = 0; t < count; ++t) {
        const char *template = templates[t];
        BN_one( templatePermutations );

        for (NSUInteger c = 0; c < strlen( template ); ++c)
            BN_mul_word( templatePermutations,
                    (BN_ULONG)strlen( mpw_charactersInClass( template[c] ) ) );

        BN_add( permutations, permutations, templatePermutations );
    }
    BN_free( templatePermutations );

    return [self timeToCrack:timeToCrack permutations:permutations forAttacker:attacker];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordString:(NSString *)password byAttacker:(MPAttacker)attacker {

    BIGNUM *permutations = BN_new();
    BN_one( permutations );

    for (NSUInteger c = 0; c < [password length]; ++c) {
        const char passwordCharacter = [password substringWithRange:NSMakeRange( c, 1 )].UTF8String[0];

        unsigned int characterEntropy = 0;
        for (NSString *characterClass in @[ @"v", @"c", @"a", @"x" ]) {
            char const *charactersForClass = mpw_charactersInClass( characterClass.UTF8String[0] );

            if (strchr( charactersForClass, passwordCharacter )) {
                // Found class for password character.
                characterEntropy = (BN_ULONG)strlen(charactersForClass);
                break;
            }
        }
        if (!characterEntropy)
            characterEntropy = 256 /* a byte */;

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
