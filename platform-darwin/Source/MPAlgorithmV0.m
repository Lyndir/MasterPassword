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

static NSOperationQueue *_mpwQueue = nil;

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
        MPMasterKey masterKey = mpw_masterKey( fullName.UTF8String, masterPassword.UTF8String, [self version] );
        if (masterKey) {
            keyData = [NSData dataWithBytes:masterKey length:MPMasterKeySize];
            trc( @"User: %@, password: %@ derives to key ID: %@ (took %0.2fs)", //
                    fullName, masterPassword, [self keyIDForKey:masterKey], -[start timeIntervalSinceNow] );
            mpw_free( &masterKey, MPMasterKeySize );
        }
    }];

    return keyData;
}

- (NSData *)keyIDForKey:(MPMasterKey)masterKey {

    return [[NSData dataWithBytesNoCopy:(void *)masterKey length:MPMasterKeySize] hashWith:PearlHashSHA256];
}

- (NSString *)nameOfType:(MPResultType)type {

    if (!type)
        return nil;

    switch (type) {
        case MPResultTypeTemplateMaximum:
            return @"Maximum Security Password";

        case MPResultTypeTemplateLong:
            return @"Long Password";

        case MPResultTypeTemplateMedium:
            return @"Medium Password";

        case MPResultTypeTemplateBasic:
            return @"Basic Password";

        case MPResultTypeTemplateShort:
            return @"Short Password";

        case MPResultTypeTemplatePIN:
            return @"PIN";

        case MPResultTypeTemplateName:
            return @"Name";

        case MPResultTypeTemplatePhrase:
            return @"Phrase";

        case MPResultTypeStatefulPersonal:
            return @"Personal Password";

        case MPResultTypeStatefulDevice:
            return @"Device Private Password";

        case MPResultTypeDeriveKey:
            return @"Crypto Key";
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSString *)shortNameOfType:(MPResultType)type {

    if (!type)
        return nil;

    switch (type) {
        case MPResultTypeTemplateMaximum:
            return @"Maximum";

        case MPResultTypeTemplateLong:
            return @"Long";

        case MPResultTypeTemplateMedium:
            return @"Medium";

        case MPResultTypeTemplateBasic:
            return @"Basic";

        case MPResultTypeTemplateShort:
            return @"Short";

        case MPResultTypeTemplatePIN:
            return @"PIN";

        case MPResultTypeTemplateName:
            return @"Name";

        case MPResultTypeTemplatePhrase:
            return @"Phrase";

        case MPResultTypeStatefulPersonal:
            return @"Personal";

        case MPResultTypeStatefulDevice:
            return @"Device";

        case MPResultTypeDeriveKey:
            return @"Key";
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSString *)classNameOfType:(MPResultType)type {

    return NSStringFromClass( [self classOfType:type] );
}

- (Class)classOfType:(MPResultType)type {

    if (!type)
        Throw( @"No type given." );

    switch (type) {
        case MPResultTypeTemplateMaximum:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplateLong:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplateMedium:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplateBasic:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplateShort:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplatePIN:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplateName:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeTemplatePhrase:
            return [MPGeneratedSiteEntity class];

        case MPResultTypeStatefulPersonal:
            return [MPStoredSiteEntity class];

        case MPResultTypeStatefulDevice:
            return [MPStoredSiteEntity class];

        case MPResultTypeDeriveKey:
            break;
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (NSArray *)allTypes {

    return [self allTypesStartingWith:MPResultTypeTemplatePhrase];
}

- (NSArray *)allTypesStartingWith:(MPResultType)startingType {

    NSMutableArray *allTypes = [[NSMutableArray alloc] initWithCapacity:8];
    MPResultType currentType = startingType;
    do {
        [allTypes addObject:@(currentType)];
    } while ((currentType = [self nextType:currentType]) != startingType);

    return allTypes;
}

- (MPResultType)defaultType {

    return MPResultTypeTemplateLong;
}

- (MPResultType)nextType:(MPResultType)type {

    switch (type) {
        case MPResultTypeTemplatePhrase:
            return MPResultTypeTemplateName;
        case MPResultTypeTemplateName:
            return MPResultTypeTemplateMaximum;
        case MPResultTypeTemplateMaximum:
            return MPResultTypeTemplateLong;
        case MPResultTypeTemplateLong:
            return MPResultTypeTemplateMedium;
        case MPResultTypeTemplateMedium:
            return MPResultTypeTemplateBasic;
        case MPResultTypeTemplateBasic:
            return MPResultTypeTemplateShort;
        case MPResultTypeTemplateShort:
            return MPResultTypeTemplatePIN;
        case MPResultTypeTemplatePIN:
            return MPResultTypeStatefulPersonal;
        case MPResultTypeStatefulPersonal:
            return MPResultTypeStatefulDevice;
        case MPResultTypeStatefulDevice:
            return MPResultTypeTemplatePhrase;
        case MPResultTypeDeriveKey:
            break;
    }

    return [self defaultType];
}

- (MPResultType)previousType:(MPResultType)type {

    MPResultType previousType = type, nextType = type;
    while ((nextType = [self nextType:nextType]) != type)
        previousType = nextType;

    return previousType;
}

- (NSString *)mpwLoginForSiteNamed:(NSString *)name usingKey:(MPKey *)key {

    return [self mpwResultForSiteNamed:name ofType:MPResultTypeTemplateName parameter:nil withCounter:MPCounterValueInitial
                               variant:MPKeyPurposeIdentification context:nil usingKey:key];
}

- (NSString *)mpwTemplateForSiteNamed:(NSString *)name ofType:(MPResultType)type
                          withCounter:(MPCounterValue)counter usingKey:(MPKey *)key {

    return [self mpwResultForSiteNamed:name ofType:type parameter:nil withCounter:counter
                               variant:MPKeyPurposeAuthentication context:nil usingKey:key];
}

- (NSString *)mpwAnswerForSiteNamed:(NSString *)name onQuestion:(NSString *)question usingKey:(MPKey *)key {

    return [self mpwResultForSiteNamed:name ofType:MPResultTypeTemplatePhrase parameter:nil withCounter:MPCounterValueInitial
                               variant:MPKeyPurposeRecovery context:question usingKey:key];
}

- (NSString *)mpwResultForSiteNamed:(NSString *)name ofType:(MPResultType)type parameter:(NSString *)parameter
                        withCounter:(MPCounterValue)counter variant:(MPKeyPurpose)purpose context:(NSString *)context
                           usingKey:(MPKey *)key {

    __block NSString *result = nil;
    [self mpw_perform:^{
        char const *resultBytes = mpw_siteResult( [key keyForAlgorithm:self],
                name.UTF8String, counter, purpose, context.UTF8String, type, parameter.UTF8String, [self version] );
        if (resultBytes) {
            result = [NSString stringWithCString:resultBytes encoding:NSUTF8StringEncoding];
            mpw_free_string( &resultBytes );
        }
    }];

    return result;
}

- (BOOL)savePassword:(NSString *)plainText toSite:(MPSiteEntity *)site usingKey:(MPKey *)key {

    if (!(site.type & MPResultTypeClassStateful)) {
        wrn( @"Can only save content to site with a stateful type: %lu.", (long)site.type );
        return NO;
    }

    NSAssert( [[key keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
        wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                (long)site.type, [site class] );
        return NO;
    }

    __block NSData *state = nil;
    if (plainText)
        [self mpw_perform:^{
            char const *stateBytes = mpw_siteState( [key keyForAlgorithm:self], site.name.UTF8String,
                    MPCounterValueInitial, MPKeyPurposeAuthentication, NULL, site.type, plainText.UTF8String, [self version] );
            if (stateBytes) {
                state = [[NSString stringWithCString:stateBytes encoding:NSUTF8StringEncoding] decodeBase64];
                mpw_free_string( &stateBytes );
            }
        }];

    NSDictionary *siteQuery = [self queryForSite:site];
    if (!state)
        [PearlKeyChain deleteItemForQuery:siteQuery];
    else
        [PearlKeyChain addOrUpdateItemForQuery:siteQuery withAttributes:@{
                (__bridge id)kSecValueData: state,
#if TARGET_OS_IPHONE
        (__bridge id)kSecAttrAccessible:
        site.type & MPSiteFeatureDevicePrivate? (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                                              : (__bridge id)kSecAttrAccessibleWhenUnlocked,
#endif
        }];
    ((MPStoredSiteEntity *)site).contentObject = nil;
    return YES;
}

- (NSString *)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)key {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolveLoginForSite:site usingKey:key result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (NSString *)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)key {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolvePasswordForSite:site usingKey:key result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (NSString *)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)key {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolveAnswerForSite:site usingKey:key result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (NSString *)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)key {

    return PearlAwait( ^(void (^setResult)(id)) {
        [self resolveAnswerForQuestion:question usingKey:key result:^(NSString *result_) {
            setResult( result_ );
        }];
    } );
}

- (void)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)key result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[key keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    BOOL loginGenerated = site.loginGenerated && [[MPAppDelegate_Shared get] isFeatureUnlocked:MPProductGenerateLogins];
    NSString *loginName = site.loginName;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!key)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    if (!loginGenerated || [loginName length])
        resultBlock( loginName );
    else
        PearlNotMainQueue( ^{
            resultBlock( [algorithm mpwLoginForSiteNamed:name usingKey:key] );
        } );
}

- (void)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)key result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[key keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    MPResultType type = site.type;
    id<MPAlgorithm> algorithm = nil;
    if (!site.name.length)
        err( @"Missing name." );
    else if (!key)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    switch (site.type) {
        case MPResultTypeTemplateMaximum:
        case MPResultTypeTemplateLong:
        case MPResultTypeTemplateMedium:
        case MPResultTypeTemplateBasic:
        case MPResultTypeTemplateShort:
        case MPResultTypeTemplatePIN:
        case MPResultTypeTemplateName:
        case MPResultTypeTemplatePhrase: {
            if (![site isKindOfClass:[MPGeneratedSiteEntity class]]) {
                wrn( @"Site with generated type %lu is not an MPGeneratedSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                break;
            }

            MPCounterValue counter = ((MPGeneratedSiteEntity *)site).counter;

            PearlNotMainQueue( ^{
                resultBlock( [algorithm mpwTemplateForSiteNamed:name ofType:type withCounter:counter usingKey:key] );
            } );
            break;
        }

        case MPResultTypeStatefulPersonal:
        case MPResultTypeStatefulDevice: {
            if (![site isKindOfClass:[MPStoredSiteEntity class]]) {
                wrn( @"Site with stored type %lu is not an MPStoredSiteEntity, but a %@.",
                        (long)site.type, [site class] );
                break;
            }

            NSDictionary *siteQuery = [self queryForSite:site];
            NSData *state = [PearlKeyChain dataOfItemForQuery:siteQuery];
            state = state?: ((MPStoredSiteEntity *)site).contentObject;

            PearlNotMainQueue( ^{
                resultBlock( [algorithm mpwResultForSiteNamed:name ofType:type parameter:[state encodeBase64]
                                                  withCounter:MPCounterValueInitial variant:MPKeyPurposeAuthentication context:nil
                                                     usingKey:key] );
            } );
            break;
        }

        case MPResultTypeDeriveKey:
            break;
    }

    Throw( @"Type not supported: %lu", (long)type );
}

- (void)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)key result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[key keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    NSString *name = site.name;
    id<MPAlgorithm> algorithm = nil;
    if (!site.name.length)
        err( @"Missing name." );
    else if (!key)
        err( @"Missing key." );
    else
        algorithm = site.algorithm;

    PearlNotMainQueue( ^{
        resultBlock( [algorithm mpwAnswerForSiteNamed:name onQuestion:nil usingKey:key] );
    } );
}

- (void)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)key
                          result:(void ( ^ )(NSString *result))resultBlock {

    NSAssert( [[key keyIDForAlgorithm:question.site.user.algorithm] isEqualToData:question.site.user.keyID],
            @"Site does not belong to current user." );
    NSString *name = question.site.name;
    NSString *keyword = question.keyword;
    id<MPAlgorithm> algorithm = nil;
    if (!name.length)
        err( @"Missing name." );
    else if (!key)
        err( @"Missing key." );
    else if ([[MPAppDelegate_Shared get] isFeatureUnlocked:MPProductGenerateAnswers])
        algorithm = question.site.algorithm;

    PearlNotMainQueue( ^{
        resultBlock( [algorithm mpwAnswerForSiteNamed:name onQuestion:keyword usingKey:key] );
    } );
}

- (void)importPassword:(NSString *)cipherText protectedByKey:(MPKey *)importKey
              intoSite:(MPSiteEntity *)site usingKey:(MPKey *)key {

    NSAssert( [[key keyIDForAlgorithm:site.user.algorithm] isEqualToData:site.user.keyID], @"Site does not belong to current user." );
    if (cipherText && cipherText.length && site.type & MPResultTypeClassStateful) {
        NSString *plainText = [self mpwResultForSiteNamed:site.name ofType:site.type parameter:cipherText
                                              withCounter:MPCounterValueInitial variant:MPKeyPurposeAuthentication context:nil
                                                 usingKey:importKey];
        if (plainText)
            [self savePassword:plainText toSite:site usingKey:key];
    }
}

- (NSDictionary *)queryForSite:(MPSiteEntity *)site {

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword attributes:@{
            (__bridge id)kSecAttrService: site.type & MPSiteFeatureDevicePrivate? @"DevicePrivate": @"Private",
            (__bridge id)kSecAttrAccount: site.name
    }                                 matches:nil];
}

- (NSString *)exportPasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)key {

    if (!(site.type & MPSiteFeatureExportContent))
        return nil;

    NSDictionary *siteQuery = [self queryForSite:site];
    NSData *state = [PearlKeyChain dataOfItemForQuery:siteQuery];
    return [state?: ((MPStoredSiteEntity *)site).contentObject encodeBase64];
}

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPResultType)type byAttacker:(MPAttacker)attacker {

    if (!(type & MPResultTypeClassTemplate))
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
