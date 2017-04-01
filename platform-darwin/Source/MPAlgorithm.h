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
//  MPAlgorithm
//
//  Created by Maarten Billemont on 16/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPKey.h"
#import "MPStoredSiteEntity.h"
#import "MPGeneratedSiteEntity.h"
#import "MPSiteQuestionEntity.h"
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
