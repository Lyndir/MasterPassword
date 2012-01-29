//
//  OPAppDelegate.h
//  OnePassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OPAppDelegate : AbstractAppDelegate

@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (strong, nonatomic) NSString                                  *keyPhrase;
@property (strong, nonatomic) NSData                                    *keyPhraseHash;
@property (strong, nonatomic) NSString                                  *keyPhraseHashHex;

+ (OPAppDelegate *)get;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectContext *)managedObjectContext;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
