//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "LocalyticsSession.h"

@implementation MPAppDelegate_Shared (Key)

static NSDictionary *keyQuery(MPUserEntity *user) {

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:@{(__bridge id)kSecAttrService: @"Saved Master Password",
                                                             (__bridge id)kSecAttrAccount: user.name}
                                   matches:nil];
}

- (MPKey *)loadSavedKeyFor:(MPUserEntity *)user {

    NSData *keyData = [PearlKeyChain dataOfItemForQuery:keyQuery(user)];
    if (keyData)
    inf(@"Found key in keychain for: %@", user.userID);

    else {
        user.saveKey = NO;
        inf(@"No key found in keychain for: %@", user.userID);
    }

    return [MPAlgorithmDefault keyFromKeyData:keyData];
}

- (void)storeSavedKeyFor:(MPUserEntity *)user {

    if (user.saveKey) {
        NSData *existingKeyData = [PearlKeyChain dataOfItemForQuery:keyQuery(user)];

        if (![existingKeyData isEqualToData:self.key.keyData]) {
            inf(@"Saving key in keychain for: %@", user.userID);

            [PearlKeyChain addOrUpdateItemForQuery:keyQuery(user)
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                  self.key.keyData, (__bridge id)kSecValueData,
                                                                  #if TARGET_OS_IPHONE
                                                                   (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly, (__bridge id)kSecAttrAccessible,
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
            inf(@"Removed key from keychain for: %@", user.userID);

            [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
        }
    }
}

- (void)signOutAnimated:(BOOL)animated {

    if (self.key)
        self.key = nil;

    if (self.activeUser) {
        self.activeUser = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationSignedOut object:self userInfo:
         @{@"animated": @(animated)}];
    }
}

- (BOOL)signInAsUser:(MPUserEntity *)user usingMasterPassword:(NSString *)password {

    MPKey *tryKey = nil;

    // Method 1: When the user has no keyID set, set a new key from the given master password.
    if (!user.keyID) {
        if ([password length])
            if ((tryKey = [MPAlgorithmDefault keyForPassword:password ofUserNamed:user.name])) {
                user.keyID = tryKey.keyID;
                [[MPAppDelegate_Shared get] saveContext];
            }
    }

    // Method 2: Depending on the user's saveKey, load or remove the key from the keychain.
    if (!user.saveKey)
     // Key should not be stored in keychain.  Delete it.
        [self forgetSavedKeyFor:user];

    else
        if (!tryKey) {
            // Key should be saved in keychain.  Load it.
            if ((tryKey = [self loadSavedKeyFor:user]))
                if (![user.keyID isEqual:tryKey.keyID]) {
                    // Loaded password doesn't match user's keyID.  Forget saved password: it is incorrect.
                    inf(@"Saved password doesn't match keyID for: %@", user.userID);
                    
                    tryKey = nil;
                    [self forgetSavedKeyFor:user];
                }
        }

    // Method 3: Check the given master password string.
    if (!tryKey) {
        if ([password length])
            if ((tryKey = [MPAlgorithmDefault keyForPassword:password ofUserNamed:user.name]))
                if (![user.keyID isEqual:tryKey.keyID]) {
                    inf(@"Key derived from password doesn't match keyID for: %@", user.userID);

                    tryKey = nil;
                }
    }

    // No more methods left, fail if key still not known.
    if (!tryKey) {
        if (password) {
            inf(@"Login failed for: %@", user.userID);
            
            [TestFlight passCheckpoint:MPCheckpointSignInFailed];
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointSignInFailed attributes:nil];
        }

        return NO;
    }
    inf(@"Logged in: %@", user.userID);

    if (![self.key isEqualToKey:tryKey]) {
        self.key = tryKey;
        [self storeSavedKeyFor:user];
    }

    @try {
        if ([[MPiOSConfig get].sendInfo boolValue]) {
            [TestFlight addCustomEnvironmentInformation:user.userID forKey:@"username"];
            [Crashlytics setObjectValue:user.userID forKey:@"username"];
            [Crashlytics setUserName:user.userID];
        }
    }
    @catch (id exception) {
        err(@"While setting username: %@", exception);
    }


    user.lastUsed   = [NSDate date];
    self.activeUser = user;
    self.activeUser.requiresExplicitMigration = NO;
    [[MPAppDelegate_Shared get] saveContext];

    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationSignedIn object:self];
    [TestFlight passCheckpoint:MPCheckpointSignedIn];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointSignedIn attributes:nil];

    return YES;
}

@end
