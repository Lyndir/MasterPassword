//
//  MPAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPPasswordWindowController.h"

@interface MPAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow                                    *window;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *managedObjectContext;

@property (readonly, strong, nonatomic) MPPasswordWindowController      *passwordWindow;
@property (readonly, strong, nonatomic) NSData                          *keyPhrase;
@property (readonly, strong, nonatomic) NSString                        *keyPhraseHashHex;

+ (MPAppDelegate *)get;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:(id)sender;
- (NSData *)keyPhraseWithLength:(NSUInteger)keyLength;

@end
