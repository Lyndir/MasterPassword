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
#import "MPElementStoredEntity.h"
#import "MPElementGeneratedEntity.h"

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
- (BOOL)migrateElement:(MPElementEntity *)element explicit:(BOOL)explicit;

- (MPKey *)keyForPassword:(NSString *)password ofUserNamed:(NSString *)userName;
- (MPKey *)keyFromKeyData:(NSData *)keyData;
- (NSData *)keyIDForKeyData:(NSData *)keyData;

- (NSString *)nameOfType:(MPElementType)type;
- (NSString *)shortNameOfType:(MPElementType)type;
- (NSString *)classNameOfType:(MPElementType)type;
- (Class)classOfType:(MPElementType)type;
- (NSArray *)allTypes;
- (NSArray *)allTypesStartingWith:(MPElementType)startingType;
- (MPElementType)nextType:(MPElementType)type;
- (MPElementType)previousType:(MPElementType)type;

- (NSString *)generateContentNamed:(NSString *)name ofType:(MPElementType)type withCounter:(NSUInteger)counter usingKey:(MPKey *)key;
- (NSString *)storedContentForElement:(MPElementStoredEntity *)element usingKey:(MPKey *)key;

- (BOOL)saveContent:(NSString *)clearContent toElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey;
- (NSString *)resolveContentForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey;
- (void)resolveContentForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey
                          result:(void (^)(NSString *result))resultBlock;

- (void)importProtectedContent:(NSString *)protectedContent protectedByKey:(MPKey *)importKey
                   intoElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey;
- (void)importClearTextContent:(NSString *)clearContent intoElement:(MPElementEntity *)element
                      usingKey:(MPKey *)elementKey;
- (NSString *)exportContentForElement:(MPElementEntity *)element usingKey:(MPKey *)elementKey;

- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordOfType:(MPElementType)type byAttacker:(MPAttacker)attacker;
- (BOOL)timeToCrack:(out TimeToCrack *)timeToCrack passwordString:(NSString *)password byAttacker:(MPAttacker)attacker;

@end
