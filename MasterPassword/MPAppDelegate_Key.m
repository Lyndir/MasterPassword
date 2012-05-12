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

static NSDictionary *keyHashQuery() {
    
    static NSDictionary *MPKeyHashQuery = nil;
    if (!MPKeyHashQuery)
        MPKeyHashQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                                 attributes:[NSDictionary dictionaryWithObject:@"Master Password Verification"
                                                                                        forKey:(__bridge id)kSecAttrService]
                                                    matches:nil];
    
    return MPKeyHashQuery;
}

- (void)forgetKey {
    
    inf(@"Deleting key and hash from keychain.");
    [PearlKeyChain deleteItemForQuery:keyQuery()];
    [PearlKeyChain deleteItemForQuery:keyHashQuery()];
    
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
    NSData *tryKeyHash = keyHashForKey(tryKey);
    NSData *keyHash = [PearlKeyChain dataOfItemForQuery:keyHashQuery()];
    inf(@"Key hash known? %@.", keyHash? @"YES": @"NO");
    if (keyHash)
        // A key hash is known -> a key is set.
        // Make sure the user's entered key matches it.
        if (![keyHash isEqual:tryKeyHash]) {
            wrn(@"Key ID mismatch. Expected: %@, answer: %@.", [keyHash encodeHex], [tryKeyHash encodeHex]);
            
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
        self.keyHash = keyHashForKey(self.key);
        self.keyID = [self.keyHash encodeHex];
        
        NSData *existingKeyHash = [PearlKeyChain dataOfItemForQuery:keyHashQuery()];
        if (![existingKeyHash isEqualToData:self.keyHash]) {
            inf(@"Updating key ID in keychain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyHashQuery()
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    self.keyHash,                                       (__bridge id)kSecValueData,
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
