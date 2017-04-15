//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

@interface MPAppDelegate_Shared()

@property(strong, nonatomic) MPKey *key;

@end

@implementation MPAppDelegate_Shared(Key)

static NSDictionary *createKeyQuery(MPUserEntity *user, BOOL newItem, MPKeyOrigin *keyOrigin) {

#if TARGET_OS_IPHONE
    if (user.touchID && kSecUseAuthenticationUI) {
        if (keyOrigin)
            *keyOrigin = MPKeyOriginKeyChainBiometric;

        CFErrorRef acError = NULL;
        id accessControl = (__bridge_transfer id)SecAccessControlCreateWithFlags( kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlTouchIDCurrentSet, &acError );
        if (!accessControl || acError)
            err( @"Could not use TouchID on this device: %@", acError );

        else
            return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                           attributes:@{
                                                   (__bridge id)kSecAttrService         : @"Saved Master Password",
                                                   (__bridge id)kSecAttrAccount         : user.name?: @"",
                                                   (__bridge id)kSecAttrAccessControl   : accessControl,
                                                   (__bridge id)kSecUseAuthenticationUI : (__bridge id)kSecUseAuthenticationUIAllow,
                                                   (__bridge id)kSecUseOperationPrompt  :
                                                   strf( @"Access %@'s master password.", user.name ),
                                           }
                                              matches:nil];
    }
#endif

    if (keyOrigin)
        *keyOrigin = MPKeyOriginKeyChain;

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:@{
                                           (__bridge id)kSecAttrService: @"Saved Master Password",
                                           (__bridge id)kSecAttrAccount: user.name?: @"",
#if TARGET_OS_IPHONE
                                           (__bridge id)kSecAttrAccessible : (__bridge id)(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly?: kSecAttrAccessibleWhenUnlockedThisDeviceOnly),
#endif
                                   }
                                      matches:nil];
}

- (MPKey *)loadSavedKeyFor:(MPUserEntity *)user {

    MPKeyOrigin keyOrigin;
    NSDictionary *keyQuery = createKeyQuery( user, NO, &keyOrigin );
    id<MPAlgorithm> keyAlgorithm = user.algorithm;
    MPKey *key = [[MPKey alloc] initForFullName:user.name withKeyResolver:^NSData *(id<MPAlgorithm> algorithm) {
        return ![algorithm isEqual:keyAlgorithm]? nil:
               PearlMainQueueAwait( (id)^{
                   return [PearlKeyChain dataOfItemForQuery:keyQuery];
               } );
    }                                 keyOrigin:keyOrigin];

    if ([key keyIDForAlgorithm:user.algorithm])
        inf( @"Found key in keychain for user: %@", user.userID );
    else
        inf( @"No key found in keychain for user: %@", user.userID );

    return key;
}

- (void)storeSavedKeyFor:(MPUserEntity *)user {

    if (user.saveKey) {
        NSData *keyData = [self.key keyDataForAlgorithm:user.algorithm];
        if (keyData) {
            [self forgetSavedKeyFor:user];

            inf( @"Saving key in keychain for user: %@", user.userID );
            [PearlKeyChain addOrUpdateItemForQuery:createKeyQuery( user, YES, nil )
                                    withAttributes:@{ (__bridge id)kSecValueData: keyData }];
        }
    }
}

- (void)forgetSavedKeyFor:(MPUserEntity *)user {

    OSStatus result = [PearlKeyChain deleteItemForQuery:createKeyQuery( user, NO, nil )];
    if (result == noErr) {
        inf( @"Removed key from keychain for user: %@", user.userID );

        [[NSNotificationCenter defaultCenter] postNotificationName:MPKeyForgottenNotification object:self];
    }
}

- (void)signOutAnimated:(BOOL)animated {

    if (self.key)
        self.key = nil;

    self.activeUser = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:MPSignedOutNotification object:self userInfo:@{ @"animated": @(animated) }];
}

- (BOOL)signInAsUser:(MPUserEntity *)user saveInContext:(NSManagedObjectContext *)moc usingMasterPassword:(NSString *)password {

    NSAssert( ![NSThread isMainThread], @"Authentication should not happen on the main thread." );
    if (!user)
        return NO;

    MPKey *tryKey = nil;

    // Method 1: When the user has no keyID set, set a new key from the given master password.
    if (!user.keyID) {
        if ([password length] && (tryKey = [[MPKey alloc] initForFullName:user.name withMasterPassword:password])) {
            user.keyID = [tryKey keyIDForAlgorithm:MPAlgorithmDefault];

            // Migrate existing sites.
            [self migrateSitesForUser:user saveInContext:moc toKey:tryKey];
        }
    }

    // Method 2: Depending on the user's saveKey, load or remove the key from the keychain.
    if (!user.saveKey)
        // Key should not be stored in keychain.  Delete it.
        [self forgetSavedKeyFor:user];

    else if (!tryKey) {
        // Key should be saved in keychain.  Load it.
        if ((tryKey = [self loadSavedKeyFor:user]) && ![user.keyID isEqual:[tryKey keyIDForAlgorithm:user.algorithm]]) {
            // Loaded password doesn't match user's keyID.  Forget saved password: it is incorrect.
            inf( @"Saved password doesn't match keyID for user: %@", user.userID );
            trc( @"user keyID: %@ (version: %d) != authentication keyID: %@",
                    user.keyID, user.algorithm.version, [tryKey keyIDForAlgorithm:user.algorithm] );

            tryKey = nil;
            [self forgetSavedKeyFor:user];
        }
    }

    // Method 3: Check the given master password string.
    if (!tryKey && [password length] && (tryKey = [[MPKey alloc] initForFullName:user.name withMasterPassword:password]) &&
        ![user.keyID isEqual:[tryKey keyIDForAlgorithm:user.algorithm]]) {
        inf( @"Key derived from password doesn't match keyID for user: %@", user.userID );
        trc( @"user keyID: %@ (version: %u) != authentication keyID: %@",
                user.keyID, user.algorithm.version, [tryKey keyIDForAlgorithm:user.algorithm] );

        tryKey = nil;
    }

    // No more methods left, fail if key still not known.
    if (!tryKey) {
        if (password)
            inf( @"Password login failed for user: %@", user.userID );
        else
            dbg( @"Automatic login failed for user: %@", user.userID );

        return NO;
    }
    inf( @"Logged in user: %@", user.userID );

    if (![self.key isEqualToKey:tryKey]) {
        // Upgrade the user's keyID if not at the default version yet.
        if (user.algorithm.version != MPAlgorithmDefaultVersion) {
            user.algorithm = MPAlgorithmDefault;
            user.keyID = [tryKey keyIDForAlgorithm:user.algorithm];
            inf( @"Upgraded keyID to version %u for user: %@", user.algorithm.version, user.userID );
        }

        self.key = tryKey;

        // Update the key chain if necessary.
        [self storeSavedKeyFor:user];
    }

    @try {
        if ([[MPConfig get].sendInfo boolValue]) {
#ifdef CRASHLYTICS
            [[Crashlytics sharedInstance] setObjectValue:user.userID forKey:@"username"];
            [[Crashlytics sharedInstance] setUserName:user.userID];
#endif
        }
    }
    @catch (id exception) {
        err( @"While setting username: %@", exception );
    }

    user.lastUsed = [NSDate date];
    self.activeUser = user;
    [moc saveToStore];

    // Perform a data sanity check now that we're logged in as the user to allow fixes that require the user's key.
    if ([[MPConfig get].checkInconsistency boolValue])
        [MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            [self findAndFixInconsistenciesSaveInContext:context];
        }];

    [[NSNotificationCenter defaultCenter] postNotificationName:MPSignedInNotification object:self];

    return YES;
}

- (void)migrateSitesForUser:(MPUserEntity *)user saveInContext:(NSManagedObjectContext *)moc toKey:(MPKey *)newKey {

    if (![user.sites count])
        // Nothing to migrate.
        return;

    MPKey *recoverKey = newKey;
#ifdef PEARL_UIKIT
    PearlOverlay *activityOverlay = [PearlOverlay showProgressOverlayWithTitle:PearlString( @"Migrating %ld sites...",
            (long)[user.sites count] )];
#endif

    for (MPSiteEntity *site in user.sites) {
        if (site.type & MPSiteTypeClassStored) {
            NSString *content;
            while (!(content = [site.algorithm storedPasswordForSite:(MPStoredSiteEntity *)site usingKey:recoverKey])) {
                // Failed to decrypt site with the current recoveryKey.  Ask user for a new one to use.
                NSString *masterPassword = nil;

#ifdef PEARL_UIKIT
                masterPassword = PearlAwait( ^(void (^setResult)(id)) {
                    [PearlAlert showAlertWithTitle:@"Enter Old Master Password"
                                           message:PearlString(
                                                           @"Your old master password is required to migrate the stored password for %@",
                                                           site.name )
                                         viewStyle:UIAlertViewStyleSecureTextInput
                                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                                if (buttonIndex_ == [alert_ cancelButtonIndex])
                                    setResult( nil );
                                else
                                    setResult( [alert_ textFieldAtIndex:0].text );
                            }          cancelTitle:@"Don't Migrate" otherTitles:@"Migrate", nil];
                } );
#endif
                if (!masterPassword)
                    // Don't Migrate
                    break;

                recoverKey = [[MPKey alloc] initForFullName:user.name withMasterPassword:masterPassword];
            }

            if (!content)
                // Don't Migrate
                break;

            if (![recoverKey isEqualToKey:newKey])
                [site.algorithm savePassword:content toSite:site usingKey:newKey];
        }
    }

    [moc saveToStore];

#ifdef PEARL_UIKIT
    [activityOverlay cancelOverlayAnimated:YES];
#endif
}

@end
