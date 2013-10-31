//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

@implementation MPAppDelegate_Shared(Key)

static NSDictionary *keyQuery(MPUserEntity *user) {

    return [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                   attributes:@{
                                           (__bridge id)kSecAttrService : @"Saved Master Password",
                                           (__bridge id)kSecAttrAccount : IfNotNilElse(user.name, @"")
                                   }
                                      matches:nil];
}

- (MPKey *)loadSavedKeyFor:(MPUserEntity *)user {

    NSData *keyData = [PearlKeyChain dataOfItemForQuery:keyQuery( user )];
    if (!keyData) {
        inf(@"No key found in keychain for: %@", user.userID);
        return nil;
    }

    inf(@"Found key in keychain for: %@", user.userID);
    return [MPAlgorithmDefault keyFromKeyData:keyData];
}

- (void)storeSavedKeyFor:(MPUserEntity *)user {

    if (user.saveKey) {
        NSData *existingKeyData = [PearlKeyChain dataOfItemForQuery:keyQuery( user )];

        if (![existingKeyData isEqualToData:self.key.keyData]) {
            inf(@"Saving key in keychain for: %@", user.userID);

            [PearlKeyChain addOrUpdateItemForQuery:keyQuery( user )
                                    withAttributes:@{
                                            (__bridge id)kSecValueData      : self.key.keyData,
#if TARGET_OS_IPHONE
                                            (__bridge id)kSecAttrAccessible : (__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
#endif
                                    }];
        }
    }
}

- (void)forgetSavedKeyFor:(MPUserEntity *)user {

    OSStatus result = [PearlKeyChain deleteItemForQuery:keyQuery( user )];
    if (result == noErr) {
        inf(@"Removed key from keychain for: %@", user.userID);

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

    if (password)
    NSAssert(![NSThread isMainThread], @"Computing key must not happen from the main thread.");

    MPKey *tryKey = nil;

    // Method 1: When the user has no keyID set, set a new key from the given master password.
    if (!user.keyID) {
        if ([password length] && (tryKey = [MPAlgorithmDefault keyForPassword:password ofUserNamed:user.name])) {
            user.keyID = tryKey.keyID;

            // Migrate existing elements.
            [self migrateElementsForUser:user saveInContext:moc toKey:tryKey];
        }
    }

    // Method 2: Depending on the user's saveKey, load or remove the key from the keychain.
    if (!user.saveKey)
            // Key should not be stored in keychain.  Delete it.
        [self forgetSavedKeyFor:user];

    else if (!tryKey) {
        // Key should be saved in keychain.  Load it.
        if ((tryKey = [self loadSavedKeyFor:user]) && ![user.keyID isEqual:tryKey.keyID]) {
            // Loaded password doesn't match user's keyID.  Forget saved password: it is incorrect.
            inf(@"Saved password doesn't match keyID for: %@", user.userID);

            tryKey = nil;
            [self forgetSavedKeyFor:user];
        }
    }

    // Method 3: Check the given master password string.
    if (!tryKey) {
        if ([password length]) if ((tryKey = [MPAlgorithmDefault keyForPassword:password
                                                                    ofUserNamed:user.name])) if (![user.keyID isEqual:tryKey.keyID]) {
            inf(@"Key derived from password doesn't match keyID for: %@", user.userID);

            tryKey = nil;
        }
    }

    // No more methods left, fail if key still not known.
    if (!tryKey) {
        if (password) {
            inf(@"Login failed for: %@", user.userID);
            MPCheckpoint( MPCheckpointSignInFailed, nil );
        }

        return NO;
    }
    inf(@"Logged in: %@", user.userID);

    if (![self.key isEqualToKey:tryKey]) {
        self.key = tryKey;
        [self storeSavedKeyFor:user];
    }

    @try {
        if ([[MPConfig get].sendInfo boolValue]) {
#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight addCustomEnvironmentInformation:user.userID forKey:@"username"];
#endif
#ifdef CRASHLYTICS
            [Crashlytics setObjectValue:user.userID forKey:@"username"];
            [Crashlytics setUserName:user.userID];
#endif
#ifdef LOCALYTICS
            [[LocalyticsSession sharedLocalyticsSession] setCustomerName:user.userID];
#endif
        }
    }
    @catch (id exception) {
        err(@"While setting username: %@", exception);
    }

    user.lastUsed = [NSDate date];
    [moc saveToStore];
    self.activeUser = user;

    [[NSNotificationCenter defaultCenter] postNotificationName:MPSignedInNotification object:self];
    MPCheckpoint( MPCheckpointSignedIn, nil );

    return YES;
}

- (void)migrateElementsForUser:(MPUserEntity *)user saveInContext:(NSManagedObjectContext *)moc toKey:(MPKey *)newKey {

    if (![user.elements count])
            // Nothing to migrate.
        return;

    MPKey *recoverKey = newKey;
#ifdef PEARL_UIKIT
    PearlOverlay *activityOverlay = [PearlOverlay showOverlayWithTitle:PearlString( @"Migrating %ld sites...", (long)[user.elements count] )];
#endif

    for (MPElementEntity *element in user.elements) {
        if (element.type & MPElementTypeClassStored) {
            NSString *content;
            while (!(content = [element.algorithm storedContentForElement:(MPElementStoredEntity *)element usingKey:recoverKey])) {
                // Failed to decrypt element with the current recoveryKey.  Ask user for a new one to use.
                __block NSString *masterPassword = nil;

#ifdef PEARL_UIKIT
                dispatch_group_t recoverPasswordGroup = dispatch_group_create();
                dispatch_group_enter( recoverPasswordGroup );
                [PearlAlert showAlertWithTitle:@"Enter Old Master Password"
                                       message:PearlString( @"Your old master password is required to migrate the stored password for %@",
                                               element.name )
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
                }                  cancelTitle:@"Don't Migrate" otherTitles:@"Migrate", nil];
                dispatch_group_wait( recoverPasswordGroup, DISPATCH_TIME_FOREVER );
#endif
                if (!masterPassword)
                        // Don't Migrate
                    break;

                recoverKey = [element.algorithm keyForPassword:masterPassword ofUserNamed:user.name];
            }

            if (!content)
                    // Don't Migrate
                break;

            if (![recoverKey isEqualToKey:newKey])
                [element.algorithm saveContent:content toElement:element usingKey:newKey];
        }
    }

    [moc saveToStore];

#ifdef PEARL_UIKIT
    [activityOverlay cancelOverlayAnimated:YES];
#endif
}

@end
