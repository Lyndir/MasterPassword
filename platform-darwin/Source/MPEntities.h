//
//  MPEntities.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 31/05/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPSiteEntity+CoreDataClass.h"
#import "MPStoredSiteEntity+CoreDataClass.h"
#import "MPGeneratedSiteEntity+CoreDataClass.h"
#import "MPUserEntity+CoreDataClass.h"
#import "MPAlgorithm.h"
#import "MPFixable.h"

#define MPAvatarCount 19

@interface NSManagedObjectContext(MP)

- (BOOL)saveToStore;

@end

@interface NSManagedObject(MP)

- (NSManagedObjectID *)permanentObjectID;

@end

@interface MPSiteQuestionEntity(MP)

- (NSString *)resolveQuestionAnswerUsingKey:(MPKey *)key;
- (void)resolveQuestionAnswerUsingKey:(MPKey *)key result:(void ( ^ )(NSString *))result;

@end

@interface MPSiteEntity(MP)<MPFixable>

@property(assign) BOOL loginGenerated;
@property(assign) MPSiteType type;
@property(readonly) NSString *typeName;
@property(readonly) NSString *typeShortName;
@property(readonly) NSString *typeClassName;
@property(readonly) Class typeClass;
@property(assign) NSUInteger uses;
@property(assign) BOOL requiresExplicitMigration;
@property(strong) id<MPAlgorithm> algorithm;

- (NSUInteger)use;
- (BOOL)tryMigrateExplicitly:(BOOL)explicit;
- (NSString *)resolveLoginUsingKey:(MPKey *)key;
- (NSString *)resolvePasswordUsingKey:(MPKey *)key;
- (NSString *)resolveSiteAnswerUsingKey:(MPKey *)key;
- (void)resolveLoginUsingKey:(MPKey *)key result:(void ( ^ )(NSString *))result;
- (void)resolvePasswordUsingKey:(MPKey *)key result:(void ( ^ )(NSString *))result;
- (void)resolveSiteAnswerUsingKey:(MPKey *)key result:(void ( ^ )(NSString *))result;
- (void)resolveAnswerUsingKey:(MPKey *)key forQuestion:(NSString *)question result:(void ( ^ )(NSString *))result;

@end

@interface MPGeneratedSiteEntity(MP)

@property(assign) NSUInteger counter;

@end

@interface MPUserEntity(MP)

@property(assign) NSUInteger avatar;
@property(assign) BOOL saveKey;
@property(assign) BOOL touchID;
@property(assign) MPSiteType defaultType;
@property(readonly) NSString *userID;
@property(strong) id<MPAlgorithm> algorithm;

+ (NSString *)idFor:(NSString *)userName;

@end
