//
//  OPElementStoredEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPElementStoredEntity.h"
#import "OPAppDelegate.h"

@interface OPElementStoredEntity ()

@property (nonatomic, retain, readwrite) id contentObject;

@end

@implementation OPElementStoredEntity

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
    
    assert(self.type & OPElementTypeClassStored);
    
    NSData *encryptedContent;
    if (self.type == OPElementTypeStoredDevicePrivate)
        encryptedContent = [KeyChain dataOfItemForQuery:[OPElementStoredEntity queryForDevicePrivateElementNamed:self.name]];
    else
        encryptedContent = self.contentObject;
    
    NSData *decryptedContent = [encryptedContent decryptWithSymmetricKey:[[OPAppDelegate get].keyPhrase
                                                                          dataUsingEncoding:NSUTF8StringEncoding]
                                                              usePadding:YES];
    return [[NSString alloc] initWithBytes:decryptedContent.bytes length:decryptedContent.length encoding:NSUTF8StringEncoding];
}

- (void)setContent:(id)content {
    
    NSData *encryptedContent = [[content description] encryptWithSymmetricKey:[[OPAppDelegate get].keyPhrase
                                                                               dataUsingEncoding:NSUTF8StringEncoding]
                                                                   usePadding:YES];
    
    if (self.type == OPElementTypeStoredDevicePrivate) {
        [KeyChain addOrUpdateItemForQuery:[OPElementStoredEntity queryForDevicePrivateElementNamed:self.name]
                           withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                           encryptedContent,                                (__bridge id)kSecValueData,
                                           kSecAttrAccessibleWhenUnlockedThisDeviceOnly,    (__bridge id)kSecAttrAccessible,
                                           nil]];
        self.contentObject = nil;
    } else
        self.contentObject = encryptedContent;
}

@end
