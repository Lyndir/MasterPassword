//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPConfig.h"
#import "MPAppDelegate_Key.h"

@implementation MPAppDelegate (Key)

static NSDictionary *keyQuery() {
    
    static NSDictionary *MPKeyQuery = nil;
    if (!MPKeyQuery)
        MPKeyQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                             attributes:[NSDictionary dictionaryWithObject:@"Stored Master Password"
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
    
    dbg(@"Deleting master key and hash from key chain.");
    [PearlKeyChain deleteItemForQuery:keyQuery()];
    [PearlKeyChain deleteItemForQuery:keyHashQuery()];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPForgotten];
}

- (void)signOut {
    
    [self updateKey:nil];
}

- (void)loadStoredKey {
    
    if ([[MPConfig get].storeKey boolValue]) {
        // Key is stored in keychain.  Load it.
        dbg(@"Loading key from key chain.");
        [self updateKey:[PearlKeyChain dataOfItemForQuery:keyQuery()]];
        dbg(@" -> Key %@.", self.key? @"found": @"NOT found");
    } else {
        // Key should not be stored in keychain.  Delete it.
        dbg(@"Deleting key from key chain.");
        [PearlKeyChain deleteItemForQuery:keyQuery()];
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
    }
}

+ (MPAppDelegate *)get {
    
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    return (MPAppDelegate *)[UIApplication sharedApplication].delegate;
#elif defined (__MAC_OS_X_VERSION_MIN_REQUIRED)
    return (MPAppDelegate *)[NSApplication sharedApplication].delegate;
#else
#error Unsupported OS.
#endif
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
            
            [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
            return NO;
        }
    
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPAsked];
    
    [self updateKey:tryKey];
    return YES;
}

- (void)updateKey:(NSData *)key {
    
    self.key = key;
    
    if (key)
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeySet object:self];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyUnset object:self];
    
    if (key) {
        self.keyHash = keyHashForKey(key);
        self.keyHashHex = [self.keyHash encodeHex];
        
        dbg(@"Updating key hash to: %@.", self.keyHashHex);
        [PearlKeyChain addOrUpdateItemForQuery:keyHashQuery()
                                withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                self.keyHash,                                       (__bridge id)kSecValueData,
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                                                kSecAttrAccessibleWhenUnlocked,                     (__bridge id)kSecAttrAccessible,
#endif
                                                nil]];
        if ([[MPConfig get].storeKey boolValue]) {
            dbg(@"Storing key in key chain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyQuery()
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    key,                                            (__bridge id)kSecValueData,
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                                                    kSecAttrAccessibleWhenUnlocked,                 (__bridge id)kSecAttrAccessible,
#endif
                                                    nil]];
        }
        
        [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointSetKeyphraseLength, key.length]];
    }
}

- (NSData *)keyWithLength:(NSUInteger)keyLength {
    
    return [self.key subdataWithRange:NSMakeRange(0, MIN(keyLength, self.key.length))];
}

@end
