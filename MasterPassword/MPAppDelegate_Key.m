//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

@implementation MPAppDelegate_Shared (Key)

static NSDictionary *keyQuery(MPUserEntity *user) {
    
    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                               @"Saved Master Password",      (__bridge id)kSecAttrService,
                                               user.name,                     (__bridge id)kSecAttrAccount,
                                               nil]
                                      matches:nil];
}

- (void)forgetSavedKey {
    
    if ([PearlKeyChain deleteItemForQuery:keyQuery(self.activeUser)] != errSecItemNotFound) {
        inf(@"Removed key from keychain.");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPForgotten];
#endif
    }
}

- (IBAction)signOut:(id)sender {

    [self forgetSavedKey];
    [self unsetKey];
}

- (void)loadSavedKey {
    
    if (self.activeUser.saveKey) {
        // Key should be saved in keychain.  Load it.
        self.key = [PearlKeyChain dataOfItemForQuery:keyQuery(self.activeUser)];
        inf(@"Looking for key in keychain: %@.", self.key? @"found": @"missing");
        if (self.key)
            [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeySet object:self];
    } else {
        // Key should not be stored in keychain.  Delete it.
        if ([PearlKeyChain deleteItemForQuery:keyQuery(self.activeUser)] != errSecItemNotFound)
            inf(@"Removed key from keychain.");
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
#endif
    }
}

- (BOOL)tryMasterPassword:(NSString *)tryPassword forUser:(MPUserEntity *)user {
    
    if (![tryPassword length])
        return NO;
    
    NSData *tryKey = keyForPassword(tryPassword, user.name);
    NSData *tryKeyID = keyIDForKey(tryKey);
    inf(@"Key ID was known? %@.", user.keyID? @"YES": @"NO");
    if (user.keyID) {
        // A key ID is known -> a master password is set.
        // Make sure the user's entered master password matches it.
        if (![user.keyID isEqual:tryKeyID]) {
            wrn(@"Key ID mismatch. Expected: %@, answer: %@.", [user.keyID encodeHex], [tryKeyID encodeHex]);
            
#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
#endif
            return NO;
        }
    } else {
        // A key ID is not known -> recording a new master password.
        user.keyID = tryKeyID;
        [[MPAppDelegate_Shared get] saveContext];
    }
    user.lastUsed = [NSDate date];

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPEntered];
#endif
    
    if (self.key != tryKey) {
        self.key = tryKey;
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeySet object:self];
    }
    
    self.activeUser = user;
    
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointSetKey];
#endif
    
    return YES;
}

- (void)storeSavedKey {
    
    if (self.activeUser.saveKey) {
        NSData *existingKey = [PearlKeyChain dataOfItemForQuery:keyQuery(self.activeUser)];
        
        if (![existingKey isEqualToData:self.key]) {
            inf(@"Updating key in keychain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyQuery(self.activeUser)
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    self.key,                                       (__bridge id)kSecValueData,
#if TARGET_OS_IPHONE
                                                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,   (__bridge id)kSecAttrAccessible,
#endif
                                                    nil]];
        }
    }
}

- (void)unsetKey {
    
    self.key = nil;
    self.activeUser = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyUnset object:self];
}

- (NSData *)keyWithLength:(NSUInteger)keyLength {
    
    return [self.key subdataWithRange:NSMakeRange(0, MIN(keyLength, self.key.length))];
}

@end
