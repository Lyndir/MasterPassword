//
//  MPElementEntities.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 31/05/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"

@implementation NSManagedObjectContext(MP)

- (BOOL)saveToStore {

    __block BOOL success = YES;
    if ([self hasChanges]) {
        [self performBlockAndWait:^{
            @try {
                NSError *error = nil;
                if (!(success = [self save:&error]))
                    err( @"While saving: %@", [error fullDescription] );
            }
            @catch (NSException *exception) {
                success = NO;
                err( @"While saving: %@", exception );
            }
        }];
    }

    return success && (!self.parentContext || [self.parentContext saveToStore]);
}

@end

@implementation MPElementEntity(MP)

- (MPElementType)type {

    return (MPElementType)[self.type_ unsignedIntegerValue];
}

- (void)setType:(MPElementType)aType {

    self.type_ = @(aType);
}

- (NSString *)typeName {

    return [self.algorithm nameOfType:self.type];
}

- (NSString *)typeShortName {

    return [self.algorithm shortNameOfType:self.type];
}

- (NSString *)typeClassName {

    return [self.algorithm classNameOfType:self.type];
}

- (Class)typeClass {

    return [self.algorithm classOfType:self.type];
}

- (NSUInteger)uses {

    return [self.uses_ unsignedIntegerValue];
}

- (void)setUses:(NSUInteger)anUses {

    self.uses_ = @(anUses);
}

- (NSUInteger)version {

    return [self.version_ unsignedIntegerValue];
}

- (void)setVersion:(NSUInteger)version {

    self.version_ = @(version);
}

- (BOOL)requiresExplicitMigration {

    return [self.requiresExplicitMigration_ boolValue];
}

- (void)setRequiresExplicitMigration:(BOOL)requiresExplicitMigration {

    self.requiresExplicitMigration_ = @(requiresExplicitMigration);
}

- (id<MPAlgorithm>)algorithm {

    return MPAlgorithmForVersion( self.version );
}

- (NSUInteger)use {

    self.lastUsed = [NSDate date];
    return ++self.uses;
}

- (NSString *)description {

    return strf( @"%@:%@", [self class], [self name] );
}

- (NSString *)debugDescription {

    return strf( @"{%@: name=%@, user=%@, type=%lu, uses=%ld, lastUsed=%@, version=%ld, loginName=%@, requiresExplicitMigration=%d}",
            NSStringFromClass( [self class] ), self.name, self.user.name, (long)self.type, (long)self.uses, self.lastUsed,
            (long)self.version,
            self.loginName, self.requiresExplicitMigration );
}

- (BOOL)migrateExplicitly:(BOOL)explicit {

    while (self.version < MPAlgorithmDefaultVersion)
        if ([MPAlgorithmForVersion( self.version + 1 ) migrateElement:self explicit:explicit])
            inf( @"%@ migration to version: %ld succeeded for element: %@",
                            explicit? @"Explicit": @"Automatic", (long)self.version + 1, self );
        else {
            wrn( @"%@ migration to version: %ld failed for element: %@",
                            explicit? @"Explicit": @"Automatic", (long)self.version + 1, self );
            return NO;
        }

    return YES;
}

- (NSString *)resolveContentUsingKey:(MPKey *)key {

    return [self.algorithm resolveContentForElement:self usingKey:key];
}

- (void)resolveContentUsingKey:(MPKey *)key result:(void ( ^ )(NSString *))result {

    [self.algorithm resolveContentForElement:self usingKey:key result:result];
}

@end

@implementation MPElementGeneratedEntity(MP)

- (NSUInteger)counter {

    return [self.counter_ unsignedIntegerValue];
}

- (void)setCounter:(NSUInteger)aCounter {

    self.counter_ = @(aCounter);
}

@end

@implementation MPElementStoredEntity(MP)

@end

@implementation MPUserEntity(MP)

- (NSUInteger)avatar {

    return [self.avatar_ unsignedIntegerValue];
}

- (void)setAvatar:(NSUInteger)anAvatar {

    self.avatar_ = @(anAvatar);
}

- (BOOL)saveKey {

    return [self.saveKey_ boolValue];
}

- (void)setSaveKey:(BOOL)aSaveKey {

    self.saveKey_ = @(aSaveKey);
}

- (MPElementType)defaultType {

    return (MPElementType)[self.defaultType_ unsignedIntegerValue]?: MPElementTypeGeneratedLong;
}

- (void)setDefaultType:(MPElementType)aDefaultType {

    self.defaultType_ = @(aDefaultType);
}

- (NSString *)userID {

    return [MPUserEntity idFor:self.name];
}

+ (NSString *)idFor:(NSString *)userName {

    return [[userName hashWith:PearlHashSHA1] encodeHex];
}

@end
