//
//  OPAppDelegate.m
//  OnePassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPAppDelegate.h"

#import "OPMainViewController.h"

@interface OPAppDelegate ()

+ (NSDictionary *)keyPhraseQuery;
+ (NSDictionary *)keyPhraseHashQuery;

@end

@implementation OPAppDelegate

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize keyPhrase = _keyPhrase;

+ (void)initialize {
    
    [Logger get].autoprintLevel = LogLevelDebug;
}

+ (NSDictionary *)keyPhraseQuery {
    
    static NSDictionary *OPKeyPhraseQuery = nil;
    if (!OPKeyPhraseQuery)
        OPKeyPhraseQuery = [KeyChain createQueryForClass:kSecClassGenericPassword
                                              attributes:[NSDictionary dictionaryWithObject:@"MasterKeyPhrase"
                                                                                     forKey:(__bridge id)kSecAttrService]
                                                 matches:nil];
    
    return OPKeyPhraseQuery;
}

+ (NSDictionary *)keyPhraseHashQuery {
    
    static NSDictionary *OPKeyPhraseHashQuery = nil;
    if (!OPKeyPhraseHashQuery)
        OPKeyPhraseHashQuery = [KeyChain createQueryForClass:kSecClassGenericPassword
                                                  attributes:[NSDictionary dictionaryWithObject:@"MasterKeyPhraseHash"
                                                                                         forKey:(__bridge id)kSecAttrService]
                                                     matches:nil];
    
    return OPKeyPhraseHashQuery;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    if ([[OPConfig get].storeKeyPhrase boolValue]) {
        // Key phrase is stored in keychain.  Load it.
        dbg(@"Loading master key phrase from key chain.");
        NSData *keyPhraseData = [KeyChain dataOfItemForQuery:[OPAppDelegate keyPhraseQuery]];
        dbg(@" -> Master key phrase %@.", keyPhraseData? @"found": @"NOT found");
        
        self.keyPhrase = keyPhraseData? [[NSString alloc] initWithBytes:keyPhraseData.bytes length:keyPhraseData.length
                                                               encoding:NSUTF8StringEncoding]: nil;
    } else {
        // Key phrase should not be stored in keychain.  Delete it.
        dbg(@"Deleting master key phrase from key chain.");
        [KeyChain deleteItemForQuery:[OPAppDelegate keyPhraseQuery]];
    }
    
    if (!self.keyPhrase) {
        // Key phrase is not known.  Ask user to set/specify it.
        dbg(@"Key phrase not known.  Will ask user.");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSData *keyPhraseHash = [KeyChain dataOfItemForQuery:[OPAppDelegate keyPhraseHashQuery]];
            dbg(@"Key phrase hash %@.", keyPhraseHash? @"known": @"NOT known");
            
            AlertViewController *keyPhraseAlert = [[AlertViewController alloc] initQuestionWithTitle:@"One Password"
                                                                                             message:keyPhraseHash? @"Unlock with your master password:": @"Choose your master password:"
                                                                                   tappedButtonBlock:
                                                   ^(NSInteger buttonIndex, NSString *answer) {
                                                       if (!buttonIndex)
                                                           exit(0);
                                                       
                                                       if (![answer length]) {
                                                           // User didn't enter a key phrase.
                                                           [AlertViewController showAlertWithTitle:[PearlStrings get].commonTitleError
                                                                                           message:@"No master password entered."
                                                                                 tappedButtonBlock:
                                                            ^(NSInteger buttonIndex) {
                                                                exit(0);
                                                            } cancelTitle:@"Quit" otherTitles:nil];
                                                       }
                                                       
                                                       NSData *answerHash = [answer hashWith:PearlDigestSHA512];
                                                       if (keyPhraseHash)
                                                           // A key phrase hash is known -> a key phrase is set.
                                                           // Make sure the user's entered key phrase matches it.
                                                           if (![keyPhraseHash isEqual:answerHash]) {
                                                               dbg(@"Key phrase hash mismatch. Expected: %@, answer: %@.", keyPhraseHash, answerHash);
                                                               
                                                               [AlertViewController showAlertWithTitle:[PearlStrings get].commonTitleError
                                                                                               message:@"Incorrect master password."
                                                                                     tappedButtonBlock:
                                                                ^(NSInteger buttonIndex) {
                                                                    exit(0);
                                                                } cancelTitle:@"Quit" otherTitles:nil];
                                                               
                                                               return;
                                                           }
                                                       
                                                       self.keyPhrase = answer;
                                                   } cancelTitle:@"Quit" otherTitles:@"Unlock", nil];
            keyPhraseAlert.alertField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            keyPhraseAlert.alertField.autocorrectionType = UITextAutocorrectionTypeNo;
            keyPhraseAlert.alertField.enablesReturnKeyAutomatically = YES;
            keyPhraseAlert.alertField.returnKeyType = UIReturnKeyGo;
            keyPhraseAlert.alertField.secureTextEntry = YES;
            [keyPhraseAlert showAlert];
        });
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    if (![[OPConfig get].rememberKeyPhrase boolValue])
        self.keyPhrase = nil;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

+ (OPAppDelegate *)get {
    
    return (OPAppDelegate *)[super get];
}

+ (NSManagedObjectContext *)managedObjectContext{
    
    return [(OPAppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext];
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

- (void)setKeyPhrase:(NSString *)keyPhrase {
    
    _keyPhrase = keyPhrase;
    
    if (keyPhrase) {
        NSData *keyPhraseHash = [keyPhrase hashWith:PearlDigestSHA512];
        dbg(@"Updating master key phrase hash to: %@.", keyPhraseHash);
        [KeyChain addOrUpdateItemForQuery:[OPAppDelegate keyPhraseHashQuery]
                           withAttributes:[NSDictionary dictionaryWithObject:keyPhraseHash
                                                                      forKey:(__bridge id)kSecValueData]];
        if ([[OPConfig get].storeKeyPhrase boolValue]) {
            dbg(@"Storing master key phrase in key chain.");
            [KeyChain addOrUpdateItemForQuery:[OPAppDelegate keyPhraseQuery]
                               withAttributes:[NSDictionary dictionaryWithObject:[keyPhrase dataUsingEncoding:NSUTF8StringEncoding]
                                                                          forKey:(__bridge id)kSecValueData]];
        }
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
