//
//  MPAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MPAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow                                    *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;

@property (readonly, strong, nonatomic) NSData                          *keyPhrase;

+ (MPAppDelegate *)get;

- (IBAction)saveAction:(id)sender;
- (NSData *)keyPhraseWithLength:(NSUInteger)keyLength;

@end
