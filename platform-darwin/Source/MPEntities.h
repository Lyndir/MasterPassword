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
@property(assign) MPResultType type;
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

@property(assign) MPCounterValue counter;

@end

@interface MPUserEntity(MP)

@property(assign) NSUInteger avatar;
@property(assign) BOOL saveKey;
@property(assign) BOOL touchID;
@property(assign) MPResultType defaultType;
@property(readonly) NSString *userID;
@property(strong) id<MPAlgorithm> algorithm;

+ (NSString *)idFor:(NSString *)userName;

@end
