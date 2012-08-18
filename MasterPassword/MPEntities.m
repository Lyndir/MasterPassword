//
//  MPElementEntities.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 31/05/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPEntities.h"
#import "MPAppDelegate.h"

@implementation MPElementEntity (MP)

- (MPElementType)type {

    return (MPElementType)[self.type_ unsignedIntegerValue];
}

- (void)setType:(MPElementType)aType {

    self.type_ = PearlUnsignedInteger(aType);
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

    self.uses_ = PearlUnsignedInteger(anUses);
}

- (NSUInteger)version {

    return [self.version_ unsignedIntegerValue];
}

- (void)setVersion:(NSUInteger)version {

    self.version_ = PearlUnsignedInteger(version);
}

- (BOOL)requiresExplicitMigration {

    return [self.requiresExplicitMigration_ boolValue];
}

- (void)setRequiresExplicitMigration:(BOOL)requiresExplicitMigration {

    self.requiresExplicitMigration_ = PearlBool(requiresExplicitMigration);
}

- (id<MPAlgorithm>)algorithm {

    return MPAlgorithmForVersion(self.version);
}

- (NSUInteger)use {

    self.lastUsed = [NSDate date];
    return ++self.uses;
}

- (id)content {

    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Content implementation missing." userInfo:nil];
}

- (NSString *)exportContent {

    return nil;
}

- (void)importProtectedContent:(NSString *)content {

}

- (void)importClearTextContent:(NSString *)clearContent usingKey:(MPKey *)key {

}

- (NSString *)description {

    return PearlString(@"%@:%@", [self class], [self name]);
}

- (NSString *)debugDescription {

    return PearlString(@"{%@: name=%@, user=%@, type=%d, uses=%d, lastUsed=%@, version=%d, userName=%@, requiresExplicitMigration=%d}",
                       NSStringFromClass([self class]), self.name, self.user.name, self.type, self.uses, self.lastUsed, self.version,
                       self.userName, self.requiresExplicitMigration);
}

- (BOOL)migrateExplicitly:(BOOL)explicit {

    while (self.version < MPAlgorithmDefaultVersion)
        if ([MPAlgorithmForVersion(self.version + 1) migrateElement:self explicit:explicit])
        inf(@"%@ migration to version: %d succeeded for element: %@", explicit? @"Explicit": @"Automatic", self.version + 1, self);
        else {
            wrn(@"%@ migration to version: %d failed for element: %@", explicit? @"Explicit": @"Automatic", self.version + 1, self);
            return NO;
        }

    return YES;
}

@end

@implementation MPElementGeneratedEntity (MP)

- (NSUInteger)counter {

    return [self.counter_ unsignedIntegerValue];
}

- (void)setCounter:(NSUInteger)aCounter {

    self.counter_ = PearlUnsignedInteger(aCounter);
}

- (id)content {

    MPKey *key = [MPAppDelegate get].key;
    if (!key)
        return nil;

    if (!(self.type & MPElementTypeClassGenerated)) {
        err(@"Corrupt element: %@, type: %d is not in MPElementTypeClassGenerated", self.name, self.type);
        return nil;
    }

    if (![self.name length])
        return nil;

    return [self.algorithm generateContentForElement:self usingKey:key];
}

@end

@implementation MPElementStoredEntity (MP)

+ (NSDictionary *)queryForDevicePrivateElementNamed:(NSString *)name {

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             @"DevicePrivate", (__bridge id)kSecAttrService,
                                                             name, (__bridge id)kSecAttrAccount,
                                                             nil]
                                      matches:nil];
}

- (id)content {

    MPKey *key = [MPAppDelegate get].key;
    if (!key)
        return nil;

    return [self contentUsingKey:key];
}

- (void)setContent:(id)content {

    MPKey *key = [MPAppDelegate get].key;
    if (!key)
        return;

    assert([key.keyID isEqualToData:self.user.keyID]);
    [self setContent:content usingKey:key];
}

- (id)contentUsingKey:(MPKey *)key {

    assert(self.type & MPElementTypeClassStored);
    assert([key.keyID isEqualToData:self.user.keyID]);

    NSData *encryptedContent;
    if (self.type & MPElementFeatureDevicePrivate)
        encryptedContent = [PearlKeyChain dataOfItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]];
    else
        encryptedContent = self.contentObject;

    NSData *decryptedContent = nil;
    if ([encryptedContent length])
        decryptedContent = [encryptedContent decryptWithSymmetricKey:[key subKeyOfLength:PearlCryptKeySize].keyData padding:YES];

    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

- (void)setContent:(id)content usingKey:(MPKey *)key {

    assert(self.type & MPElementTypeClassStored);
    assert(key);

    NSData *encryptedContent = [[content description] encryptWithSymmetricKey:[key subKeyOfLength:PearlCryptKeySize].keyData padding:YES];

    if (self.type & MPElementFeatureDevicePrivate) {
        [PearlKeyChain addOrUpdateItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]
                                withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              encryptedContent, (__bridge id)kSecValueData,
                                                              #if TARGET_OS_IPHONE
                                                              (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                              (__bridge id)kSecAttrAccessible,
                                                              #endif
                                                              nil]];
        self.contentObject = nil;
    } else
        self.contentObject = encryptedContent;
}

- (NSString *)exportContent {

    return [self.contentObject encodeBase64];
}

- (void)importProtectedContent:(NSString *)protectedContent {

    self.contentObject = [protectedContent decodeBase64];
}

- (void)importClearTextContent:(NSString *)clearContent usingKey:(MPKey *)key {

    [self setContent:clearContent usingKey:key];
}

@end

@implementation MPUserEntity (MP)

- (NSUInteger)avatar {

    return [self.avatar_ unsignedIntegerValue];
}

- (void)setAvatar:(NSUInteger)anAvatar {

    self.avatar_ = PearlUnsignedInteger(anAvatar);
}

- (BOOL)saveKey {

    return [self.saveKey_ boolValue];
}

- (void)setSaveKey:(BOOL)aSaveKey {

    self.saveKey_ = [NSNumber numberWithBool:aSaveKey];
}

- (MPElementType)defaultType {

    return (MPElementType)[self.defaultType_ unsignedIntegerValue];
}

- (void)setDefaultType:(MPElementType)aDefaultType {

    self.defaultType_ = PearlUnsignedInteger(aDefaultType);
}

- (BOOL)requiresExplicitMigration {

    return [self.requiresExplicitMigration_ boolValue];
}

- (void)setRequiresExplicitMigration:(BOOL)requiresExplicitMigration {

    self.requiresExplicitMigration_ = PearlBool(requiresExplicitMigration);
}

- (NSString *)userID {

    return [MPUserEntity idFor:self.name];
}

+ (NSString *)idFor:(NSString *)userName {

    return [[userName hashWith:PearlHashSHA1] encodeHex];
}

@end
