//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

@interface MPAppDelegate_Shared (Key)

- (void)loadSavedKey;
- (IBAction)signOut:(id)sender;

- (BOOL)tryMasterPassword:(NSString *)tryPassword forUser:(MPUserEntity *)user;
- (void)storeSavedKey;
- (void)forgetSavedKey;
- (void)unsetKey;

- (NSData *)keyWithLength:(NSUInteger)keyLength;

@end
