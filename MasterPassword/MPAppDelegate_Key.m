//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Key.h"

#import "MPMainViewController.h"
#import "IASKSettingsReader.h"

@implementation MPAppDelegate (Key)

static NSDictionary *keyQuery() {
    
    static NSDictionary *MPKeyQuery = nil;
    if (!MPKeyQuery)
        MPKeyQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                             attributes:[NSDictionary dictionaryWithObject:@"Master Password Key"
                                                                                    forKey:(__bridge id)kSecAttrService]
                                                matches:nil];
    
    return MPKeyQuery;
}

static NSDictionary *keyHashQuery() {
    
    static NSDictionary *MPKeyHashQuery = nil;
    if (!MPKeyHashQuery)
        MPKeyHashQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                                 attributes:[NSDictionary dictionaryWithObject:@"Master Password Key Hash"
                                                                                        forKey:(__bridge id)kSecAttrService]
                                                    matches:nil];
    
    return MPKeyHashQuery;
}

- (void)forgetKey {
    
    dbg(@"Deleting master key and hash from key chain.");
    [PearlKeyChain deleteItemForQuery:keyQuery()];
    [PearlKeyChain deleteItemForQuery:keyHashQuery()];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPForgotten];
#endif
}

- (void)signOut {
    
    [self updateKey:nil];
}

- (void)loadStoredKey {
    
    if ([[MPiOSConfig get].storeKey boolValue]) {
        // Key is stored in keychain.  Load it.
        dbg(@"Loading key from key chain.");
        [self updateKey:[PearlKeyChain dataOfItemForQuery:keyQuery()]];
        dbg(@" -> Key %@.", self.key? @"found": @"NOT found");
    } else {
        // Key should not be stored in keychain.  Delete it.
        dbg(@"Deleting key from key chain.");
        [PearlKeyChain deleteItemForQuery:keyQuery()];
#ifndef PRODUCTION
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
#endif
    }
}

+ (MPAppDelegate *)get {
    
    return (MPAppDelegate *)[super get];
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
            
#ifndef PRODUCTION
            [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
#endif
            return NO;
        }
    
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPAsked];
#endif
    
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
                                                self.keyHash,                                      (__bridge id)kSecValueData,
                                                kSecAttrAccessibleWhenUnlocked,                          (__bridge id)kSecAttrAccessible,
                                                nil]];
        if ([[MPiOSConfig get].storeKey boolValue]) {
            dbg(@"Storing key in key chain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyQuery()
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    key,  (__bridge id)kSecValueData,
                                                    kSecAttrAccessibleWhenUnlocked,                      (__bridge id)kSecAttrAccessible,
                                                    nil]];
        }
        
#ifndef PRODUCTION
        [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointSetKeyphraseLength, key.length]];
#endif
    }
}

- (NSData *)keyWithLength:(NSUInteger)keyLength {
    
    return [self.key subdataWithRange:NSMakeRange(0, MIN(keyLength, self.key.length))];
}

@end
