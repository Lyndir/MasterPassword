//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"

@implementation MPAppDelegate

@synthesize window = _window;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize keyPhrase;

+ (MPAppDelegate *)get {
    
    return (MPAppDelegate *)[NSApplication sharedApplication].delegate;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

- (NSURL *)applicationFilesDirectory {
    
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.lyndir.lhunath.MasterPassword"];
}

- (NSData *)keyPhraseWithLength:(NSUInteger)keyLength {
    
    return [self.keyPhrase subdataWithRange:NSMakeRange(0, MIN(keyLength, self.keyPhrase.length))];
}

#pragma mark - Core Data stack

- (NSManagedObjectModel *)managedObjectModel {
    
    if (__managedObjectModel)
        return __managedObjectModel;
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MasterPassword" withExtension:@"momd"];
    return __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (__managedObjectContext)
        return __managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        __managedObjectContext.persistentStoreCoordinator = coordinator;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                          object:coordinator
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note) {
                                                          dbg(@"Ubiquitous content change: %@", note);
                                                          
                                                          [__managedObjectContext performBlock:^{
                                                              [__managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                              
                                                              [[NSNotificationCenter defaultCenter] postNotification:
                                                               [NSNotification notificationWithName:MPNotificationStoreUpdated
                                                                                             object:self userInfo:[note userInfo]]];
                                                          }];
                                                      }];
    }
    
    return __managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (__persistentStoreCoordinator)
        return __persistentStoreCoordinator;
    
    NSURL *storeURL = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"MasterPassword.storedata"];
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [__persistentStoreCoordinator lock];
    NSError *error = nil;
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:storeURL
                                                          options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSNumber numberWithBool:YES],   NSInferMappingModelAutomaticallyOption,
                                                                   [NSNumber numberWithBool:YES],   NSMigratePersistentStoresAutomaticallyOption,
                                                                   @"MasterPassword.store",         NSPersistentStoreUbiquitousContentNameKey,
                                                                   [[[NSFileManager defaultManager]
                                                                     URLForUbiquityContainerIdentifier:nil]
                                                                    URLByAppendingPathComponent:@"store"
                                                                    isDirectory:YES],               NSPersistentStoreUbiquitousContentURLKey,
                                                                   nil]
                                                            error:&error]) {
        err(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
        wrn(@"Deleted datastore: %@", storeURL);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];        
#endif

        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    [__persistentStoreCoordinator unlock];
    
    return __persistentStoreCoordinator;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!__managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end
