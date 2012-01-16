//
//  OPAppDelegate.m
//  OnePassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPAppDelegate.h"

#import "OPMainViewController.h"

@implementation OPAppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize keyPhrase = _keyPhrase;

+ (void)initialize {
    
    [Logger get].autoprintLevel = LogLevelDebug;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    if (![[OPConfig get].rememberKeyPhrase boolValue])
        self.keyPhrase = nil;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    if (!self.keyPhrase)
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *keyPhraseHash = [OPConfig get].keyPhraseHash;
            
            AlertViewController *keyPhraseAlert = [[AlertViewController alloc] initQuestionWithTitle:@"One Password"
                                                                                             message:keyPhraseHash? @"Unlock with your master password:": @"Choose your master password:"
                                                                                   tappedButtonBlock:
                                                   ^(NSInteger buttonIndex, NSString *answer) {
                                                       if (buttonIndex == 0)
                                                           exit(0);
                                                       
                                                       if (![answer length]) {
                                                           [AlertViewController showAlertWithTitle:[PearlStrings get].commonTitleError
                                                                                           message:@"No master password entered."
                                                                                 tappedButtonBlock:
                                                            ^(NSInteger buttonIndex) {
                                                                exit(0);
                                                            } cancelTitle:@"Quit" otherTitles:nil];
                                                       }
                                                       
                                                       NSString *answerHash = [[answer hashWith:PearlDigestSHA1] encodeHex];
                                                       if (keyPhraseHash) {
                                                           if (![keyPhraseHash isEqualToString:answerHash]) {
                                                               [AlertViewController showAlertWithTitle:[PearlStrings get].commonTitleError
                                                                                               message:@"Incorrect master password."
                                                                                     tappedButtonBlock:
                                                                ^(NSInteger buttonIndex) {
                                                                    exit(0);
                                                                } cancelTitle:@"Quit" otherTitles:nil];
                                                               
                                                               return;
                                                           }
                                                       } else
                                                           [OPConfig get].keyPhraseHash = answerHash;
                                                       
                                                       self.keyPhrase = answer;
                                                   } cancelTitle:@"Quit" otherTitles:@"Unlock", nil];
            keyPhraseAlert.alertField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            keyPhraseAlert.alertField.autocorrectionType = UITextAutocorrectionTypeNo;
            keyPhraseAlert.alertField.secureTextEntry = YES;
            [keyPhraseAlert showAlert];
        });
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

+ (OPAppDelegate *)get {
    
    return (OPAppDelegate *)[super get];
}

- (void)saveContext
{
    NSError *error = nil;
    if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         */
        err(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    } 
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"OnePassword" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"OnePassword.sqlite"];
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                                                          options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   (id)kCFBooleanTrue,  NSMigratePersistentStoresAutomaticallyOption,
                                                                   (id)kCFBooleanTrue,  NSInferMappingModelAutomaticallyOption,
                                                                   nil]
                                                            error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        err(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
        wrn(@"Deleted datastore: %@", storeURL);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];        
#endif
        @throw [NSException exceptionWithName:error.domain reason:error.localizedDescription
                                     userInfo:[NSDictionary dictionaryWithObject:error forKey:@"cause"]];
    }
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
