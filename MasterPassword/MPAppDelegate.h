//
//  MPAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPAppDelegate : PearlAppDelegate

@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSData                          *keyPhrase;
@property (readonly, strong, nonatomic) NSData                          *keyPhraseHash;
@property (readonly, strong, nonatomic) NSString                        *keyPhraseHashHex;

+ (MPAppDelegate *)get;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectContext *)managedObjectContext;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

- (void)showGuide;
- (void)loadKeyPhrase;
- (void)forgetKeyPhrase;
- (NSData *)keyPhraseWithLength:(NSUInteger)keyLength;
- (BOOL)tryMasterPassword:(NSString *)tryPassword;

@end
