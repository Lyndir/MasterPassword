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
    
    dbg(@"Deleting key and hash from key chain.");
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
        dbg(@"Loading key from key chain.");
        [self updateKey:[PearlKeyChain dataOfItemForQuery:keyQuery()]];
        dbg(@" -> Key %@.", self.key? @"found": @"NOT found");
    } else {
        // Key should not be stored in keychain.  Delete it.
        if ([PearlKeyChain deleteItemForQuery:keyQuery()] != errSecItemNotFound)
            dbg(@"Deleted key from key chain.");
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
#endif
    }
}

- (BOOL)tryMasterPassword:(NSString *)tryPassword {
    
    NSData *keyHash = [PearlKeyChain dataOfItemForQuery:keyHashQuery()];
    dbg(@"Key hash %@.", keyHash? @"known": @"NOT known");
    
    if (![tryPassword length])
        return NO;
    
    NSData *tryKey = keyForPassword(tryPassword);
    NSData *tryKeyHash = keyHashForKey(tryKey);
    if (keyHash)
        // A key hash is known -> a key is set.
        // Make sure the user's entered key matches it.
        if (![keyHash isEqual:tryKeyHash]) {
            dbg(@"Key phrase hash mismatch. Expected: %@, answer: %@.", keyHash, tryKeyHash);
            
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
        
        dbg(@"Updating key ID to: %@.", self.keyID);
        [PearlKeyChain addOrUpdateItemForQuery:keyHashQuery()
                                withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                self.keyHash,                                       (__bridge id)kSecValueData,
#if TARGET_OS_IPHONE
                                                kSecAttrAccessibleWhenUnlocked,                     (__bridge id)kSecAttrAccessible,
#endif
                                                nil]];
        if ([[MPConfig get].saveKey boolValue]) {
            dbg(@"Storing key in key chain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyQuery()
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    self.key,                                       (__bridge id)kSecValueData,
#if TARGET_OS_IPHONE
                                                    kSecAttrAccessibleWhenUnlocked,                 (__bridge id)kSecAttrAccessible,
#endif
                                                    nil]];
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
