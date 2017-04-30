//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#ifndef trc
#error error
#endif
#import "MPAlgorithmV0.h"
#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_InApp.h"
#import "mpw-util.h"

/* An AMD HD 7970 calculates 2495M SHA-1 hashes per second at a cost of ~350$ per GPU */
#define CRACKING_PER_SECOND 2495000000UL
#define CRACKING_PRICE      350

NSOperationQueue *_mpwQueue = nil;

@implementation MPAlgorithmV0

- (id)init {

    if (!(self = [super init]))
        return nil;

    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        _mpwQueue = [NSOperationQueue new];
        _mpwQueue.maxConcurrentOperationCount = 1;
        _mpwQueue.name = @"mpw queue";
    } );

    return self;
}

- (MPAlgorithmVersion)version {

    return MPAlgorithmVersion0;
}

- (NSString *)description {

    return strf( @"V%lu", (unsigned long)self.version );
}

- (NSString *)debugDescription {

    return strf( @"<%@: version=%lu>", NSStringFromClass( [self class] ), (unsigned long)self.version );
}

- (BOOL)isEqual:(id)other {

    if (other == self)
        return YES;
    if (!other || ![other conformsToProtocol:@protocol(MPAlgorithm)])
        return NO;

    return [(id<MPAlgorithm>)other version] == [self version];
}

- (void)mpw_perform:(void ( ^ )(void))operationBlock {

    if ([NSOperationQueue currentQueue] == _mpwQueue) {
        operationBlock();
        return;
    }

    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:operationBlock];
    if ([operation respondsToSelector:@selector( qualityOfService )])
        operation.qualityOfService = NSQualityOfServiceUserInitiated;
    [_mpwQueue addOperations:@[ operation ] waitUntilFinished:YES];
}

- (BOOL)tryMigrateUser:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc {

    NSError *error = nil;
    NSFetchRequest *migrationRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
    migrationRequest.predicate = [NSPredicate predicateWithFormat:@"version_ < %d AND user == %@", self.version, user];
    NSArray *migrationSites = [moc executeFetchRequest:migrationRequest error:&error];
    if (!migrationSites) {
        MPError( error, @"While looking for sites to migrate." );
        return NO;
    }

    BOOL success = YES;
    for (MPSiteEntity *migrationSite in migrationSites)
        if (![migrationSite tryMigrateExplicitly:NO])
            success = NO;

    return success;
}

- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit {

    if ([site.algorithm version] != [self version] - 1)
        // Only migrate from previous version.
        return NO;

    if (!explicit) {
        // This migration requires explicit permission.
        site.requiresExplicitMigration = YES;
        return NO;
    }

    // Apply migration.
    site.requiresExplicitMigration = NO;
    site.algorithm = self;
    return YES;
}

- (NSData *)keyDataForFullName:(NSString *)fullName withMasterPassword:(NSString *)masterPassword {

    __block NSData *keyData;
    [self mpw_perform:^{
        NSDate *start = [NSDate date];
        uint8_t const *masterKeyBytes = mpw_masterKeyForUser( fullName.UTF8String, masterPassword.UTF8String, [self version] );
        if (masterKeyBytes) {
            keyData = [NSData dataWithBytes:masterKeyBytes length:MP_dkLen];
            trc( @"User: %@, password: %@ derives to key ID: %@ (took %0.2fs)", //
                    fullName, masterPassword, [self keyIDForKeyData:keyData], -[start timeIntervalSinceNow] );
            mpw_free( masterKeyBytes, MP_dkLen );
        }
    }];

    return keyData;
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
            return @"Name";

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

    return [self allTypesStartingWith:MPSiteTypeGeneratedPhrase];
}

- (NSArray *)allTypesStartingWith:(MPSiteType)startingType {

    NSMutableArray *allTypes = [[NSMutableArray alloc] initWithCapacity:8];
    MPSiteType currentType = startingType;
    do {
        [allTypes addObject:@(currentType)];
    } while ((currentType = [self nextType:currentType]) != startingType);

    return allTypes;
}

- (MPSiteType)defaultType {

    return MPSiteTypeGeneratedLong;
}

- (MPSiteType)nextType:(MPSiteType)type {

    switch (type) {
        case MPSiteTypeGeneratedPhrase:
            return MPSiteTypeGeneratedName;
        case MPSiteTypeGeneratedName:
            return MPSiteTypeGeneratedMaximum;
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
            return MPSiteTypeGeneratedPhrase;
    }

    return [self defaultType];
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

    __block NSString *content;
    [self mpw_perform:^{
        char const *contentBytes = mpw_passwordForSite( [key keyDataForAlgorithm:self].bytes,
                name.UTF8String, type, (uint32_t)counter, variant, context.UTF8String, [self version] );
        if (contentBytes) {
            content = [NSString stringWithCString:contentBytes encoding:NSUTF8StringEncoding];
            mpw_free_string( contentBytes );
        }
    }];

    return content;
}

- (NSString *)storedLoginForSite:(MPStoredSiteEntity *)site usingKey:(MPKey *)key {

    return nil;
}

- (NSString *)storedPasswordForSite:(MPStoredSiteEntity *)site usingKey:(MPKey *)key {

    return [self decryptContent:site.contentObject usingKey:key];
}

- (BOOL)savePassword:(NSString *)clearContent toSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
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

            NSData *encryptionKey = [siteKey keyDataForAlgorithm:self trimmedLength:PearlCryptKeySize];
            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:encryptionKey padding:YES];
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

            NSData *encryptionKey = [siteKey keyDataForAlgorithm:self trimmedLength:PearlCryptKeySize];
            NSData *encryptedContent = [[clearContent dataUsingEncoding:NSUTF8StringEncoding]
                    encryptWithSymmetricKey:encryptionKey padding:YES];
            NSDictionary *siteQuery = [self queryForDevicePrivateSiteNamed:site.name];
            if (!encryptedContent)
                [PearlKeyChain deleteItemForQuery:siteQuery];
            else
                [PearlKeyChain addOrUpdateItemForQuery:siteQuery withAttributes:@{
                        (__bridge id)kSecValueData     : encryptedContent,
#if TARGET_OS_IPHONE
                        (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
#endif
                }];
            ((MPStoredSiteEntity *)site).contentObject = nil;
            return YES;
        }
    }

    Throw( @"Unsupported type: %ld", (long)site.type );
}

- (NSString *)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolveLoginForSite:site usingKey:siteKey result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (NSString *)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolvePasswordForSite:site usingKey:siteKey result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (NSString *)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolveAnswerForSite:site usingKey:siteKey result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (NSString *)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)siteKey {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolveAnswerForQuestion:question usingKey:siteKey result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (void)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    BOOL loginGenerated = site.loginGenerated && [[MPAppDelegate_Shared get] isFeatureUnlocked:MPProductGenerateLogins];
    NSString *loginName = site.loginName;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!siteKey)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    if (!loginGenerated || [loginName length])
        resultBlock( loginName );
    else
        PearlNotMainQueue( ^{
            resultBlock( [algorithm generateLoginForSiteNamed:name usingKey:siteKey] );
        } );
}

- (void)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
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
            else if (!siteKey)
                err( @"Missing key." );
            else
                algorithm = site.algorithm;

            PearlNotMainQueue( ^{
                resultBlock( [algorithm generatePasswordForSiteNamed:name ofType:type withCounter:counter usingKey:siteKey] );
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

            PearlNotMainQueue( ^{
                resultBlock( [self decryptContent:encryptedContent usingKey:siteKey] );
            } );
            break;
        }
        case MPSiteTypeStoredDevicePrivate: {
            NSAssert( [site isKindOfClass:[MPStoredSiteEntity class]],
                    @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.", (long)site.type,
                    [site class] );

            NSDictionary *siteQuery = [self queryForDevicePrivateSiteNamed:site.name];
            NSData *encryptedContent = [PearlKeyChain dataOfItemForQuery:siteQuery];

            PearlNotMainQueue( ^{
                resultBlock( [self decryptContent:encryptedContent usingKey:siteKey] );
            } );
            break;
        }
    }
}

- (void)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    id<MPAlgorithm> algorithm = nil;
    if (!site.name.length)
        err( @"Missing name." );
    else if (!siteKey)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    PearlNotMainQueue( ^{
        resultBlock( [algorithm generateAnswerForSiteNamed:name onQuestion:nil usingKey:siteKey] );
    } );
}

- (void)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)siteKey
                          result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[siteKey keyIDForAlgorithm:question.site.user.algorithm] isEqualToData:question.site.user.keyID],
            @"Site does not belong to current user." );
    NSString *name = question.site.name;
    NSString *keyword = question.keyword;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!siteKey)
        err( @"Missing key." );
    else if ([[MPAppDelegate_Shared get] isFeatureUnlocked:MPProductGenerateAnswers])
        algorithm = question.site.algorithm;

    PearlNotMainQueue( ^{
        resultBlock( [algorithm generateAnswerForSiteNamed:name onQuestion:keyword usingKey:siteKey] );
    } );
}

- (void)importProtectedPassword:(NSString *)protectedContent protectedByKey:(MPKey *)importKey
                       intoSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey {

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
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
            if ([[importKey keyIDForAlgorithm:self] isEqualToData:[siteKey keyIDForAlgorithm:self]])
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

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
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

    NSAssert( [[siteKey keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
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
                                           (__bridge id)kSecAttrService: @"DevicePrivate",
                                           (__bridge id)kSecAttrAccount: name
                                   }
                                      matches:nil];
}

- (NSString *)decryptContent:(NSData *)encryptedContent usingKey:(MPKey *)key {

    if (!key)
        return nil;
    NSData *decryptedContent = nil;
    if ([encryptedContent length]) {
        NSData *encryptionKey = [key keyDataForAlgorithm:self trimmedLength:PearlCryptKeySize];
        decryptedContent = [encryptedContent decryptWithSymmetricKey:encryptionKey padding:YES];
    }
    if (!decryptedContent)
        return nil;

    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPSiteType)type byAttacker:(MPAttacker)attacker {

    if (!(type & MPSiteTypeClassGenerated))
        return NO;
    size_t count = 0;
    const char **templates = mpw_templatesForType( type, &count );
    if (!templates)
        return NO;

    NSDecimalNumber *permutations = [NSDecimalNumber zero], *templatePermutations;
    for (size_t t = 0; t < count; ++t) {
        const char *template = templates[t];
        templatePermutations = [NSDecimalNumber one];

        for (NSUInteger c = 0; c < strlen( template ); ++c)
            templatePermutations = [templatePermutations decimalNumberByMultiplyingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:strlen( mpw_charactersInClass( template[c] ) )]];

        permutations = [permutations decimalNumberByAdding:templatePermutations];
    }
    free( templates );

    return [self timeToCrack:timeToCrack permutations:permutations forAttacker:attacker];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordString:(NSString *)password byAttacker:(MPAttacker)attacker {

    NSDecimalNumber *permutations = [NSDecimalNumber one];

    for (NSUInteger c = 0; c < [password length]; ++c) {
        const char passwordCharacter = [password substringWithRange:NSMakeRange( c, 1 )].UTF8String[0];

        unsigned long characterEntropy = 0;
        for (NSString *characterClass in @[ @"v", @"c", @"a", @"x" ]) {
            char const *charactersForClass = mpw_charactersInClass( characterClass.UTF8String[0] );

            if (strchr( charactersForClass, passwordCharacter )) {
                // Found class for password character.
                characterEntropy = strlen( charactersForClass );
                break;
            }
        }
        if (!characterEntropy)
            characterEntropy = 256 /* a byte */;

        permutations = [permutations decimalNumberByMultiplyingBy:
                (id)[[NSDecimalNumber alloc] initWithUnsignedLong:characterEntropy]];
    }

    return [self timeToCrack:timeToCrack permutations:permutations forAttacker:attacker];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack permutations:(NSDecimalNumber *)permutations forAttacker:(MPAttacker)attacker {

    // Determine base seconds needed to calculate the permutations.
    NSDecimalNumber *secondsToCrack = [permutations decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:CRACKING_PER_SECOND]];

    // Modify seconds needed by applying our hardware budget.
    switch (attacker) {
        case MPAttacker1:
            break;
        case MPAttacker5K:
            secondsToCrack = [secondsToCrack decimalNumberByMultiplyingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:CRACKING_PRICE]];
            secondsToCrack = [secondsToCrack decimalNumberByDividingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:5000]];
            break;
        case MPAttacker20M:
            secondsToCrack = [secondsToCrack decimalNumberByMultiplyingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:CRACKING_PRICE]];
            secondsToCrack = [secondsToCrack decimalNumberByDividingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:20000000]];
            break;
        case MPAttacker5B:
            secondsToCrack = [secondsToCrack decimalNumberByMultiplyingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:CRACKING_PRICE]];
            secondsToCrack = [secondsToCrack decimalNumberByDividingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:5000]];
            secondsToCrack = [secondsToCrack decimalNumberByDividingBy:
                    (id)[[NSDecimalNumber alloc] initWithUnsignedLong:1000000]];
            break;
    }

    NSDecimalNumber *ulong_max = (id)[[NSDecimalNumber alloc] initWithUnsignedLong:ULONG_MAX];

    NSDecimalNumber *hoursToCrack = [secondsToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:3600L]];
    if ([hoursToCrack compare:ulong_max] == NSOrderedAscending)
        timeToCrack->hours = (unsigned long long)[hoursToCrack doubleValue];
    else
        timeToCrack->hours = ULONG_MAX;

    NSDecimalNumber *daysToCrack = [hoursToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:24L]];
    if ([daysToCrack compare:ulong_max] == NSOrderedAscending)
        timeToCrack->days = (unsigned long long)[daysToCrack doubleValue];
    else
        timeToCrack->days = ULONG_MAX;

    NSDecimalNumber *weeksToCrack = [daysToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:7L]];
    if ([weeksToCrack compare:ulong_max] == NSOrderedAscending)
        timeToCrack->weeks = (unsigned long long)[weeksToCrack doubleValue];
    else
        timeToCrack->weeks = ULONG_MAX;

    NSDecimalNumber *monthsToCrack = [daysToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:31L]];
    if ([monthsToCrack compare:ulong_max] == NSOrderedAscending)
        timeToCrack->months = (unsigned long long)[monthsToCrack doubleValue];
    else
        timeToCrack->months = ULONG_MAX;

    NSDecimalNumber *yearsToCrack = [daysToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:356L]];
    if ([yearsToCrack compare:ulong_max] == NSOrderedAscending)
        timeToCrack->years = (unsigned long long)[yearsToCrack doubleValue];
    else
        timeToCrack->years = ULONG_MAX;

    NSDecimalNumber *universesToCrack = [yearsToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:14000L]];
    universesToCrack = [universesToCrack decimalNumberByDividingBy:
            (id)[[NSDecimalNumber alloc] initWithUnsignedLong:1000000L]];
    if ([universesToCrack compare:ulong_max] == NSOrderedAscending)
        timeToCrack->universes = (unsigned long long)[universesToCrack doubleValue];
    else
        timeToCrack->universes = ULONG_MAX;

    return YES;
}

@end
