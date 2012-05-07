//
//  MPAppDelegate_Shared.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

@interface MPAppDelegate () {
}

@property (strong, nonatomic) NSData                *key;
@property (strong, nonatomic) NSData                *keyHash;
@property (strong, nonatomic) NSString              *keyHashHex;

@end

@interface MPAppDelegate (Shared)

+ (MPAppDelegate *)get;
- (NSURL *)applicationFilesDirectory;

@end
