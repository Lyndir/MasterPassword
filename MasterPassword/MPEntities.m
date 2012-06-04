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

@implementation MPElementEntity (MP)

- (NSNumber *)use {
    
    self.lastUsed = [NSDate date];
    self.uses = [NSNumber numberWithUnsignedInteger:[self.uses unsignedIntegerValue] + 1];

    return self.uses;
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

- (id)content {

    if (!([self.type unsignedIntegerValue] & MPElementTypeClassGenerated)) {
        err(@"Corrupt element: %@, type: %d is not in MPElementTypeClassGenerated", self.name, self.type);
        return nil;
    }
    
    if (![self.name length])
        return nil;
    
    return MPCalculateContent([self.type unsignedIntegerValue], self.name, [MPAppDelegate get].key, [self.counter unsignedIntegerValue]);
}

@end

@implementation MPElementStoredEntity (MP)

+ (NSDictionary *)queryForDevicePrivateElementNamed:(NSString *)name {
    
    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                              attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                          @"DevicePrivate",  (__bridge id)kSecAttrService,
                                          name,              (__bridge id)kSecAttrAccount,
                                          nil]
                                 matches:nil];
}

- (id)content {
    
    assert([self.type unsignedIntegerValue] & MPElementTypeClassStored);
    
    NSData *encryptedContent;
    if ([self.type unsignedIntegerValue] & MPElementFeatureDevicePrivate)
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
    
    if ([self.type unsignedIntegerValue] & MPElementFeatureDevicePrivate) {
        [PearlKeyChain addOrUpdateItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]
                           withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                           encryptedContent,                                (__bridge id)kSecValueData,
#if TARGET_OS_IPHONE
                                           kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    (__bridge id)kSecAttrAccessible,
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
