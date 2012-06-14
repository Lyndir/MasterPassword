//
//  MPElementEntities.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 31/05/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPEntities.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPUserEntity.h"

@implementation MPElementEntity (MP)

- (MPElementType)type {

    return (MPElementType)[self.type_ unsignedIntegerValue];
}

- (void)setType:(MPElementType)aType {

    self.type_ = PearlUnsignedInteger(aType);
}

- (NSUInteger)uses {

    return [self.uses_ unsignedIntegerValue];
}

- (void)setUses:(NSUInteger)anUses {

    self.uses_ = PearlUnsignedInteger(anUses);
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

- (void)importContent:(NSString *)content {

}

- (NSString *)description {

    return PearlString(@"%@:%@", [self class], [self name]);
}

- (NSString *)debugDescription {

    return PearlString(@"{%@: name=%@, user=%@, type=%d, uses=%d, lastUsed=%@}",
                       NSStringFromClass([self class]), self.name, self.user.name, self.type, self.uses, self.lastUsed);
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

    if (!(self.type & MPElementTypeClassGenerated)) {
        err(@"Corrupt element: %@, type: %d is not in MPElementTypeClassGenerated", self.name, self.type);
        return nil;
    }

    if (![self.name length])
        return nil;

    return MPCalculateContent(self.type, self.name, [MPAppDelegate get].key, self.counter);
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

    assert(self.type & MPElementTypeClassStored);

    NSData *encryptedContent;
    if (self.type & MPElementFeatureDevicePrivate)
        encryptedContent = [PearlKeyChain dataOfItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]];
    else
        encryptedContent = self.contentObject;

    NSData *decryptedContent = [encryptedContent decryptWithSymmetricKey:[[MPAppDelegate get] keyWithLength:PearlCryptKeySize]
                                                 padding:YES];
    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

- (void)setContent:(id)content {

    NSData *encryptedContent = [[content description] encryptWithSymmetricKey:[[MPAppDelegate get] keyWithLength:PearlCryptKeySize]
                                         padding:YES];

    if (self.type & MPElementFeatureDevicePrivate) {
        [PearlKeyChain addOrUpdateItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]
                       withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     encryptedContent, (__bridge id)kSecValueData,
                                                     #if TARGET_OS_IPHONE
                                                     kSecAttrAccessibleWhenUnlockedThisDeviceOnly, (__bridge id)kSecAttrAccessible,
                                                     #endif
                                                     nil]];
        self.contentObject = nil;
    } else
        self.contentObject = encryptedContent;
}

- (NSString *)exportContent {

    return [self.contentObject encodeBase64];
}

- (void)importContent:(NSString *)content {

    self.contentObject = [content decodeBase64];
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

- (NSString *)userID {

    return [MPUserEntity idFor:self.name];
}


- (void)setDefaultType:(MPElementType)aDefaultType {

    self.defaultType_ = PearlUnsignedInteger(aDefaultType);
}

+ (NSString *)idFor:(NSString *)userName {

    return [[userName hashWith:PearlHashSHA1] encodeHex];
}

@end
