//
//  MPElementStoredEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementStoredEntity.h"
#import "MPAppDelegate_Shared.h"

@interface MPElementStoredEntity ()

@property (nonatomic, retain, readwrite) id contentObject;

@end

@implementation MPElementStoredEntity

@dynamic contentObject;

+ (NSDictionary *)queryForDevicePrivateElementNamed:(NSString *)name {
    
    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                              attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                          @"DevicePrivate",  (__bridge id)kSecAttrService,
                                          name,              (__bridge id)kSecAttrAccount,
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
                                           encryptedContent,                                (__bridge id)kSecValueData,
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
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
