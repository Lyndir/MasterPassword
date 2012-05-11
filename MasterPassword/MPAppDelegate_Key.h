//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

@interface MPAppDelegate_Shared (Key)

- (void)loadStoredKey;
- (IBAction)signOut:(id)sender;

- (BOOL)tryMasterPassword:(NSString *)tryPassword;
- (void)updateKey:(NSData *)key;
- (void)forgetKey;

- (NSData *)keyWithLength:(NSUInteger)keyLength;

@end
