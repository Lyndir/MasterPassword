//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"

@interface MPAppDelegate () {
    
    NSPersistentStoreCoordinator                                        *_persistentStoreCoordinator;
    NSManagedObjectModel                                                *_managedObjectModel;
    NSManagedObjectContext                                              *_managedObjectContext;
}

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;

@property (strong, nonatomic) NSData                                    *key;
@property (strong, nonatomic) NSData                                    *keyHash;
@property (strong, nonatomic) NSString                                  *keyHashHex;

@end

@interface MPAppDelegate (Key)

+ (MPAppDelegate *)get;

- (NSURL *)applicationFilesDirectory;

+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectContext *)managedObjectContext;
- (void)saveContext;
- (void)printStore;

- (void)loadStoredKey;
- (void)signOut;

- (BOOL)tryMasterPassword:(NSString *)tryPassword;
- (void)updateKey:(NSData *)key;
- (void)forgetKey;

- (NSData *)keyWithLength:(NSUInteger)keyLength;

@end
