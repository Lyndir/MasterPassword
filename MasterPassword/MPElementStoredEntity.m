//
//  MPElementStoredEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementStoredEntity.h"
#import "MPAppDelegate.h"

@interface MPElementStoredEntity ()

@property (nonatomic, retain, readwrite) id contentObject;

@end

@implementation MPElementStoredEntity

@dynamic contentObject;

+ (NSDictionary *)queryForDevicePrivateElementNamed:(NSString *)name {
    
    return [KeyChain createQueryForClass:kSecClassGenericPassword
                              attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                          @"DevicePrivate",  (__bridge id)kSecAttrService,
                                          name,              (__bridge id)kSecAttrAccount,
                                          nil]
                                 matches:nil];
}

- (id)content {
    
    assert(self.type & MPElementTypeClassStored);
    
    NSData *encryptedContent;
    if (self.type == MPElementTypeStoredDevicePrivate)
        encryptedContent = [KeyChain dataOfItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]];
    else
        encryptedContent = self.contentObject;
    
    NSData *decryptedContent = [encryptedContent decryptWithSymmetricKey:[[MPAppDelegate get] keyPhraseWithLength:kCipherKeySize]
                                                              usePadding:YES];
    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

- (void)setContent:(id)content {
    
    NSData *encryptedContent = [[content description] encryptWithSymmetricKey:[[MPAppDelegate get] keyPhraseWithLength:kCipherKeySize]
                                                                   usePadding:YES];
    
    if (self.type == MPElementTypeStoredDevicePrivate) {
        [KeyChain addOrUpdateItemForQuery:[MPElementStoredEntity queryForDevicePrivateElementNamed:self.name]
                           withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                           encryptedContent,                                (__bridge id)kSecValueData,
                                           kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    (__bridge id)kSecAttrAccessible,
                                           nil]];
        self.contentObject = nil;
    } else
        self.contentObject = encryptedContent;
}

@end
