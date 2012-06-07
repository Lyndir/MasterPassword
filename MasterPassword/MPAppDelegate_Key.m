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

- (NSData *)loadSavedKeyFor:(MPUserEntity *)user {

    NSData *key = [PearlKeyChain dataOfItemForQuery:keyQuery(user)];
    if (key)
        inf(@"Found key (for: %@) in keychain.", user.name);

    else {
        user.saveKey = NO;
        inf(@"No key found (for: %@) in keychain.", user.name);
    }

    return key;
}

- (void)storeSavedKeyFor:(MPUserEntity *)user {

    if (user.saveKey) {
        NSData *existingKey = [PearlKeyChain dataOfItemForQuery:keyQuery(user)];

        if (![existingKey isEqualToData:self.key]) {
            inf(@"Updating key in keychain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyQuery(user)
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                            self.key, (__bridge id) kSecValueData,
#if TARGET_OS_IPHONE
                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, (__bridge id) kSecAttrAccessible,
#endif
                                            nil]];
        }
    }
}

- (void)forgetSavedKeyFor:(MPUserEntity *)user {

    OSStatus result = [PearlKeyChain deleteItemForQuery:keyQuery(user)];
    if (result == noErr || result == errSecItemNotFound) {
        user.saveKey = NO;

        if (result == noErr) {
            inf(@"Removed key (for: %@) from keychain.", user.name);

            [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPTestFlightCheckpointForgetSavedKey];
#endif
        }
    }
}

- (void)signOut {

    self.key = nil;
    self.activeUser = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationSignedOut object:self];
}

- (BOOL)signInAsUser:(MPUserEntity *)user usingMasterPassword:(NSString *)password {

    NSData *tryKey = nil;

    // Method 1: When the user has no keyID set, set a new key from the given master password.
    if (!user.keyID) {
        if ([password length])
            if ((tryKey = keyForPassword(password, user.name))) {
                user.keyID = keyIDForKey(tryKey);
                [[MPAppDelegate_Shared get] saveContext];
            }
    }

    // Method 2: Depending on the user's saveKey, load or remove the key from the keychain.
    if (!user.saveKey)
            // Key should not be stored in keychain.  Delete it.
        [self forgetSavedKeyFor:user];

    else if (!tryKey) {
        // Key should be saved in keychain.  Load it.
        if ((tryKey = [self loadSavedKeyFor:user]))
            if (![user.keyID isEqual:keyIDForKey(tryKey)]) {
                // Loaded password doesn't match user's keyID.  Forget saved password: it is incorrect.
                tryKey = nil;
                [self forgetSavedKeyFor:user];

#ifdef TESTFLIGHT_SDK_VERSION
                [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
#endif
            }
    }

    // Method 3: Check the given master password string.
    if (!tryKey) {
        if ([password length])
            if ((tryKey = keyForPassword(password, user.name)))
                if (![user.keyID isEqual:keyIDForKey(tryKey)]) {
                    tryKey = nil;

    #ifdef TESTFLIGHT_SDK_VERSION
                    [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
    #endif
                }
    }

    // No more methods left, fail if key still not known.
    if (!tryKey)
        return NO;

    if (![self.key isEqualToData:tryKey]) {
        self.key = tryKey;
        [self storeSavedKeyFor:user];
    }

    user.lastUsed = [NSDate date];
    self.activeUser = user;
    [[MPAppDelegate_Shared get] saveContext];

    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationSignedIn object:self];
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointSignedIn];
#endif

    return YES;
}

- (NSData *)keyWithLength:(NSUInteger)keyLength {

    return [self.key subdataWithRange:NSMakeRange(0, MIN(keyLength, self.key.length))];
}

@end
