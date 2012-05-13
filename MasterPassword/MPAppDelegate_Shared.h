//
//  MPAppDelegate_Shared.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#if TARGET_OS_IPHONE
@interface MPAppDelegate_Shared : PearlAppDelegate
#else
@interface MPAppDelegate_Shared : NSObject <PearlConfigDelegate>
#endif

@property (strong, nonatomic) NSData                *key;
@property (strong, nonatomic) NSData                *keyID;

+ (MPAppDelegate_Shared *)get;

- (NSURL *)applicationFilesDirectory;

@end
