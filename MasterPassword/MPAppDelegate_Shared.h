//
//  MPAppDelegate_Shared.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

@interface MPAppDelegate_Shared : PearlAppDelegate

@property (strong, nonatomic) NSData                *key;
@property (strong, nonatomic) NSData                *keyID;

+ (MPAppDelegate_Shared *)get;

- (NSURL *)applicationFilesDirectory;

@end
