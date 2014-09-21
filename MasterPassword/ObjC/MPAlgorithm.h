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
#import "MPSiteStoredEntity.h"
#import "MPSiteGeneratedEntity.h"

#define MPAlgorithmDefaultVersion 1
#define MPAlgorithmDefault MPAlgorithmForVersion(MPAlgorithmDefaultVersion)

id<MPAlgorithm> MPAlgorithmForVersion(NSUInteger version);
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
- (NSUInteger)version;
- (BOOL)migrateUser:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc;
- (BOOL)migrateSite:(MPSiteEntity *)site explicit:(BOOL)explicit;

- (MPKey *)keyForPassword:(NSString *)password ofUserNamed:(NSString *)userName;
- (MPKey *)keyFromKeyData:(NSData *)keyData;
- (NSData *)keyIDForKeyData:(NSData *)keyData;

- (NSString *)scopeForVariant:(MPSiteVariant)variant;
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
- (NSString *)generateContentForSiteNamed:(NSString *)name ofType:(MPSiteType)type withCounter:(NSUInteger)counter
                                  variant:(MPSiteVariant)variant usingKey:(MPKey *)key;

- (NSString *)storedLoginForSite:(MPSiteStoredEntity *)site usingKey:(MPKey *)key;
- (NSString *)storedPasswordForSite:(MPSiteStoredEntity *)site usingKey:(MPKey *)key;

- (BOOL)savePassword:(NSString *)clearPassword toSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;

- (NSString *)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;
- (NSString *)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;

- (void)resolveLoginForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey
                     result:(void ( ^ )(NSString *result))resultBlock;
- (void)resolvePasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey
                        result:(void ( ^ )(NSString *result))resultBlock;

- (void)importProtectedPassword:(NSString *)protectedPassword protectedByKey:(MPKey *)importKey
                       intoSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;
- (void)importClearTextPassword:(NSString *)clearPassword intoSite:(MPSiteEntity *)site
                       usingKey:(MPKey *)siteKey;
- (NSString *)exportPasswordForSite:(MPSiteEntity *)site usingKey:(MPKey *)siteKey;

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPSiteType)type byAttacker:(MPAttacker)attacker;
- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordString:(NSString *)password byAttacker:(MPAttacker)attacker;

@end
