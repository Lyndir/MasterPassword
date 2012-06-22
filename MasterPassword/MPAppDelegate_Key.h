//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

@interface MPAppDelegate_Shared (Key)

- (BOOL)signInAsUser:(MPUserEntity *)user usingMasterPassword:(NSString *)password;
- (void)signOut;

- (void)storeSavedKeyFor:(MPUserEntity *)user;
- (void)forgetSavedKeyFor:(MPUserEntity *)user;

@end
