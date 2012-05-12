//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPConfig.h"
#import "MPAppDelegate_Key.h"
#import "MPElementEntity.h"

@implementation MPAppDelegate_Shared (Key)

static NSDictionary *keyQuery() {
    
    static NSDictionary *MPKeyQuery = nil;
    if (!MPKeyQuery)
        MPKeyQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                             attributes:[NSDictionary dictionaryWithObject:@"Saved Master Password"
                                                                                    forKey:(__bridge id)kSecAttrService]
                                                matches:nil];
    
    return MPKeyQuery;
}

static NSDictionary *keyIDQuery() {
    
    static NSDictionary *MPKeyIDQuery = nil;
    if (!MPKeyIDQuery)
        MPKeyIDQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                               attributes:[NSDictionary dictionaryWithObject:@"Master Password Verification"
                                                                                      forKey:(__bridge id)kSecAttrService]
                                                  matches:nil];
    
    return MPKeyIDQuery;
}

- (void)forgetKey {
    
    inf(@"Deleting key and ID from keychain.");
    [PearlKeyChain deleteItemForQuery:keyQuery()];
    [PearlKeyChain deleteItemForQuery:keyIDQuery()];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPForgotten];
#endif
}

- (IBAction)signOut:(id)sender {
    
    [self updateKey:nil];
}

- (void)loadStoredKey {
    
    if ([[MPConfig get].saveKey boolValue]) {
        // Key is stored in keychain.  Load it.
        [self updateKey:[PearlKeyChain dataOfItemForQuery:keyQuery()]];
        inf(@"Looking for key in keychain: %@.", self.key? @"found": @"missing");
    } else {
        // Key should not be stored in keychain.  Delete it.
        if ([PearlKeyChain deleteItemForQuery:keyQuery()] != errSecItemNotFound)
            inf(@"Removed key from keychain.");
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
#endif
    }
}

- (BOOL)tryMasterPassword:(NSString *)tryPassword {
    
    if (![tryPassword length])
        return NO;
    
    NSData *tryKey = keyForPassword(tryPassword);
    NSData *tryKeyID = keyIDForKey(tryKey);
    NSData *keyID = [PearlKeyChain dataOfItemForQuery:keyIDQuery()];
    inf(@"Key ID known? %@.", keyID? @"YES": @"NO");
    if (keyID)
        // A key ID is known -> a password is set.
        // Make sure the user's entered password matches it.
        if (![keyID isEqual:tryKeyID]) {
            wrn(@"Key ID mismatch. Expected: %@, answer: %@.", [keyID encodeHex], [tryKeyID encodeHex]);
            
#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
#endif
            return NO;
        }
    
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPEntered];
#endif
    
    [self updateKey:tryKey];
    return YES;
}

- (void)updateKey:(NSData *)key {
    
    if (self.key != key) {
        self.key = key;
        
        if (key)
            [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeySet object:self];
        else
            [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyUnset object:self];
    }
    
    if (self.key) {
        self.keyID = keyIDForKey(self.key);
        
        NSData *existingKeyID = [PearlKeyChain dataOfItemForQuery:keyIDQuery()];
        if (![existingKeyID isEqualToData:self.keyID]) {
            inf(@"Updating key ID in keychain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyIDQuery()
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    self.keyID,                                       (__bridge id)kSecValueData,
#if TARGET_OS_IPHONE
                                                    kSecAttrAccessibleWhenUnlocked,                     (__bridge id)kSecAttrAccessible,
#endif
                                                    nil]];
        }
        if ([[MPConfig get].saveKey boolValue]) {
            NSData *existingKey = [PearlKeyChain dataOfItemForQuery:keyQuery()];
            if (![existingKey isEqualToData:self.key]) {
                inf(@"Updating key in keychain.");
                [PearlKeyChain addOrUpdateItemForQuery:keyQuery()
                                        withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        self.key,                                       (__bridge id)kSecValueData,
#if TARGET_OS_IPHONE
                                                        kSecAttrAccessibleWhenUnlocked,                 (__bridge id)kSecAttrAccessible,
#endif
                                                        nil]];
            }
        }
        
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPTestFlightCheckpointSetKey];
#endif
    }
}

- (NSData *)keyWithLength:(NSUInteger)keyLength {
    
    return [self.key subdataWithRange:NSMakeRange(0, MIN(keyLength, self.key.length))];
}

@end
