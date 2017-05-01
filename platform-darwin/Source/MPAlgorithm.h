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

#import "MPKey.h"
#import "MPStoredSiteEntity+CoreDataClass.h"
#import "MPGeneratedSiteEntity+CoreDataClass.h"
#import "MPSiteQuestionEntity+CoreDataClass.h"
#import "mpw-algorithm.h"

#define MPAlgorithmDefaultVersion MPAlgorithmVersionCurrent
#define MPAlgorithmDefault MPAlgorithmForVersion(MPAlgorithmDefaultVersion)

id<MPAlgorithm> MPAlgorithmForVersion(MPAlgorithmVersion version);
id<MPAlgorithm> MPAlgorithmDefaultForBundleVersion(NSString *bundleVersion);

PearlEnum( MPAttacker,
        MPAttacker1, MPAttacker5K, MPAttacker20M, MPAttacker5B );

typedef struct TimeToCrack {
    unsigned long long hours;
    unsigned long long days;
    unsigned long long weeks;
    unsigned long long months;
    unsigned long long years;
    unsigned long long universes;
} TimeToCrack;

NSString *NSStringFromTimeToCrack(TimeToCrack timeToCrack);

@protocol MPAlgorithm<NSObject>

@required
- (MPAlgorithmVersion)version;
- (BOOL)tryMigrateUser:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc;
- (BOOL)tryMigrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit;

- (NSData *)keyIDForKeyData:(NSData *)keyData;
- (NSData *)keyDataForFullName:(NSString *)fullName withMasterPassword:(NSString *)masterPassword;

- (NSString *)nameOfType:(MPSiteType)type;
- (NSString *)shortNameOfType:(MPSiteType)type;
- (NSString *)classNameOfType:(MPSiteType)type;
- (Class)classOfType:(MPSiteType)type;
- (NSArray *)allTypes;
- (NSArray *)allTypesStartingWith:(MPSiteType)startingType;
- (MPSiteType)defaultType;
- (MPSiteType)nextType:(MPSiteType)type;
- (MPSiteType)previousType:(MPSiteType)type;

- (NSString *)generateLoginForSiteNamed:(NSString *)name usingKey:(MPKey *)key;
- (NSString *)generatePasswordForSiteNamed:(NSString *)name ofType:(MPSiteType)type withCounter:(NSUInteger)counter
                                  usingKey:(MPKey *)key;
- (NSString *)generateAnswerForSiteNamed:(NSString *)name onQuestion:(NSString *)question usingKey:(MPKey *)key;
- (NSString *)generateContentForSiteNamed:(NSString *)name ofType:(MPSiteType)type withCounter:(NSUInteger)counter
                                  variant:(MPSiteVariant)variant context:(NSString *)context usingKey:(MPKey *)key;

- (NSString *)storedLoginForSite:(MPStoredSiteEntity *)site usingKey:(MPKey *)key;
- (NSString *)storedPasswordForSite:(MPStoredSiteEntity *)site usingKey:(MPKey *)key;

- (BOOL)savePassword:(NSString *)clearPassword toSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;

- (NSString *)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;
- (NSString *)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;
- (NSString *)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;
- (NSString *)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)siteKey;

- (void)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey
                     result:(void ( ^ )(NSString *result))resultBlock;
- (void)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey
                        result:(void ( ^ )(NSString *result))resultBlock;
- (void)resolveAnswerForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey
                      result:(void ( ^ )(NSString *result))resultBlock;
- (void)resolveAnswerForQuestion:(MPSiteQuestionEntity *)question usingKey:(MPKey *)siteKey
                          result:(void ( ^ )(NSString *result))resultBlock;

- (void)importProtectedPassword:(NSString *)protectedPassword protectedByKey:(MPKey *)importKey
                       intoSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;
- (void)importClearTextPassword:(NSString *)clearPassword intoSite:(MPSiteEntity *)site
                       usingKey:(MPKey *)siteKey;
- (NSString *)exportPasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPSiteType)type byAttacker:(MPAttacker)attacker;
- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordString:(NSString *)password byAttacker:(MPAttacker)attacker;

@end
