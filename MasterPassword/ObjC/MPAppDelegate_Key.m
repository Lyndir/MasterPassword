//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface MPAppDelegate_Shared()

@property(strong, nonatomic) MPKey *key;

@end

@implementation MPAppDelegate_Shared(Key)

static NSDictionary *createKeyQuery(MPUserEntity *user, BOOL newItem, MPKeyOrigin *keyOrigin) {

#if TARGET_OS_IPHONE
    if (user.touchID && kSecUseOperationPrompt) {
        if (keyOrigin)
            *keyOrigin = MPKeyOriginKeyChainBiometric;

        CFErrorRef acError = NULL;
        SecAccessControlRef accessControl = SecAccessControlCreateWithFlags( kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlTouchIDCurrentSet, &acError );
        if (!accessControl || acError)
            err( @"Could not use TouchID on this device: %@", acError );

        else
            return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                           attributes:@{
                                                   (__bridge id)kSecAttrService         : @"Saved Master Password",
                                                   (__bridge id)kSecAttrAccount         : user.name?: @"",
                                                   (__bridge id)kSecAttrAccessControl   : (__bridge id)accessControl,
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
                                           (__bridge id)kSecAttrService    : @"Saved Master Password",
                                           (__bridge id)kSecAttrAccount    : user.name?: @"",
#if TARGET_OS_IPHONE
                                           (__bridge id)kSecAttrAccessible : (__bridge id)(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly?: kSecAttrAccessibleWhenUnlockedThisDeviceOnly),
#endif
                                   }
                                      matches:nil];
}

- (MPKey *)loadSavedKeyFor:(MPUserEntity *)user {

    MPKeyOrigin keyOrigin;
    NSDictionary *keyQuery = createKeyQuery( user, NO, &keyOrigin );
    NSData *keyData = [PearlKeyChain dataOfItemForQuery:keyQuery];
    if (!keyData) {
        inf( @"No key found in keychain for user: %@", user.userID );
        return nil;
    }

    inf( @"Found key in keychain for user: %@", user.userID );
    return [[MPKey alloc] initForFullName:user.name withKeyData:keyData forAlgorithm:user.algorithm keyOrigin:keyOrigin];
}

- (void)storeSavedKeyFor:(MPUserEntity *)user {

    if (user.saveKey) {
        inf( @"Saving key in keychain for user: %@", user.userID );

        [PearlKeyChain addOrUpdateItemForQuery:createKeyQuery( user, YES, nil )
                                withAttributes:@{
                                        (__bridge id)kSecValueData : [self.key keyDataForAlgorithm:user.algorithm],
                                }];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:MPSignedOutNotification object:self userInfo:@{ @"animated" : @(animated) }];
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
        switch (self.key.origin) {
            case MPKeyOriginMasterPassword:
                [self storeSavedKeyFor:user];
                break;

            case MPKeyOriginKeyChain:
            case MPKeyOriginKeyChainBiometric:
                break;
        }
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
                __block NSString *masterPassword = nil;

#ifdef PEARL_UIKIT
                dispatch_group_t recoverPasswordGroup = dispatch_group_create();
                dispatch_group_enter( recoverPasswordGroup );
                [PearlAlert showAlertWithTitle:@"Enter Old Master Password"
                                       message:PearlString( @"Your old master password is required to migrate the stored password for %@",
                                                       site.name )
                                     viewStyle:UIAlertViewStyleSecureTextInput
                                     initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                            @try {
                                if (buttonIndex_ == [alert_ cancelButtonIndex])
                                    // Don't Migrate
                                    return;

                                masterPassword = [alert_ textFieldAtIndex:0].text;
                            }
                            @finally {
                                dispatch_group_leave( recoverPasswordGroup );
                            }
                        }          cancelTitle:@"Don't Migrate" otherTitles:@"Migrate", nil];
                dispatch_group_wait( recoverPasswordGroup, DISPATCH_TIME_FOREVER );
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
