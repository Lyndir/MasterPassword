//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPConfig.h"
#import "MPAppDelegate_Key.h"
#import "MPElementEntity.h"

@implementation MPAppDelegate (Key)

static NSDictionary *keyQuery() {
    
    static NSDictionary *MPKeyQuery = nil;
    if (!MPKeyQuery)
        MPKeyQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                             attributes:[NSDictionary dictionaryWithObject:@"Stored Master Password"
                                                                                    forKey:(__bridge id)kSecAttrService]
                                                matches:nil];
    
    return MPKeyQuery;
}

static NSDictionary *keyHashQuery() {
    
    static NSDictionary *MPKeyHashQuery = nil;
    if (!MPKeyHashQuery)
        MPKeyHashQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                                 attributes:[NSDictionary dictionaryWithObject:@"Master Password Verification"
                                                                                        forKey:(__bridge id)kSecAttrService]
                                                    matches:nil];
    
    return MPKeyHashQuery;
}

- (NSURL *)applicationFilesDirectory {

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
#else
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *applicationFilesDirectory = [appSupportURL URLByAppendingPathComponent:@"com.lyndir.lhunath.MasterPassword"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:applicationFilesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
        err(@"Couldn't create application directory: %@, error occurred: %@", applicationFilesDirectory, error);
    
    return applicationFilesDirectory;
#endif
}

#pragma mark - Core Data stack

+ (NSManagedObjectContext *)managedObjectContext {
    
    return [[self get] managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    
    return [[self get] managedObjectModel];
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel)
        return _managedObjectModel;
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MasterPassword" withExtension:@"momd"];
    return _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (_managedObjectContext)
        return _managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _managedObjectContext.persistentStoreCoordinator = coordinator;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                          object:coordinator
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note) {
                                                          dbg(@"Ubiquitous content change: %@", note);
                                                          
                                                          [_managedObjectContext performBlock:^{
                                                              [_managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                              [self printStore];
                                                              
                                                              [[NSNotificationCenter defaultCenter] postNotification:
                                                               [NSNotification notificationWithName:MPNotificationStoreUpdated
                                                                                             object:self userInfo:[note userInfo]]];
                                                          }];
                                                      }];
    }
    
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator)
        return _persistentStoreCoordinator;
    
    NSString *contentName = @"store";
    NSURL *storeURL = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"MasterPassword.sqlite"];
    NSURL *contentURL = [[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil]
                         URLByAppendingPathComponent:@"logs" isDirectory:YES];
    
//#if DEBUG
//    dbg(@"Deleting store and content.");
//    NSError *storeRemovalError = nil, *contentRemovalError = nil;
//    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&storeRemovalError];
//    if (storeRemovalError)
//        err(@"Store removal error: %@", storeRemovalError);
//    else
//        [[NSFileManager defaultManager] removeItemAtURL:contentURL error:&contentRemovalError];
//    if (contentRemovalError)
//        err(@"Content removal error: %@", contentRemovalError);
//#endif
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [_persistentStoreCoordinator lock];
    @try {
        NSError *error = nil;
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                                                             options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [NSNumber numberWithBool:YES],   NSInferMappingModelAutomaticallyOption,
                                                                      [NSNumber numberWithBool:YES],   NSMigratePersistentStoresAutomaticallyOption,
#if __IPHONE_OS_VERSION_MIN_REQUIRED
                                                                      NSFileProtectionComplete,        NSPersistentStoreFileProtectionKey,
#endif
                                                                      contentURL,                      NSPersistentStoreUbiquitousContentURLKey,
                                                                      contentName,                     NSPersistentStoreUbiquitousContentNameKey,
                                                                      nil]
                                                               error:&error]) {
            ftl(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];        
            wrn(@"Deleted datastore: %@", storeURL);
#endif
            @throw error;
        }
    }
    @finally {
        [_persistentStoreCoordinator unlock];
    }
    
    return _persistentStoreCoordinator;
}

- (void)saveContext {
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
            err(@"Unresolved error %@", error);
    }];
}

- (void)printStore {
    
    if (!_managedObjectModel || !_managedObjectContext) {
        trc(@"Not printing store: store not initialized.");
        return;
    }
    
    [self.managedObjectContext performBlock:^{
        trc(@"=== All entities ===");
        for(NSEntityDescription *entity in [_managedObjectModel entities]) {
            NSFetchRequest *request = [NSFetchRequest new];
            [request setEntity:entity];
            NSError *error;
            NSArray *results = [_managedObjectContext executeFetchRequest:request error:&error];
            for(NSManagedObject *o in results) {
                if ([o isKindOfClass:[MPElementEntity class]]) {
                    MPElementEntity *e = (MPElementEntity *)o;
                    trc(@"For descriptor: %@, found: %@: %@ (%@)", entity.name, [o class], e.name, e.mpHashHex);
                } else {
                    trc(@"For descriptor: %@, found: %@", entity.name, [o class]);
                }
            }
        }
        trc(@"---");
        if ([MPAppDelegate get].keyHashHex) {
            trc(@"=== Known sites ===");
            NSFetchRequest *fetchRequest = [_managedObjectModel
                                            fetchRequestFromTemplateWithName:@"MPElements"
                                            substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   @"",                                     @"query",
                                                                   [MPAppDelegate get].keyHashHex,          @"mpHashHex",
                                                                   nil]];
            [fetchRequest setSortDescriptors:
             [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
            
            NSError *error = nil;
            for (MPElementEntity *e in [_managedObjectContext executeFetchRequest:fetchRequest error:&error]) {
                trc(@"Found site: %@ (%@): %@", e.name, e.mpHashHex, e);
            }
            trc(@"---");
        } else
            trc(@"Not printing sites: master password not set.");
    }];
}

- (void)forgetKey {
    
    dbg(@"Deleting master key and hash from key chain.");
    [PearlKeyChain deleteItemForQuery:keyQuery()];
    [PearlKeyChain deleteItemForQuery:keyHashQuery()];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPForgotten];
#endif
}

- (IBAction)signOut:(id)sender {
    
    [self updateKey:nil];
}

- (void)loadStoredKey {
    
    if ([[MPConfig get].storeKey boolValue]) {
        // Key is stored in keychain.  Load it.
        dbg(@"Loading key from key chain.");
        [self updateKey:[PearlKeyChain dataOfItemForQuery:keyQuery()]];
        dbg(@" -> Key %@.", self.key? @"found": @"NOT found");
    } else {
        // Key should not be stored in keychain.  Delete it.
        dbg(@"Deleting key from key chain.");
        [PearlKeyChain deleteItemForQuery:keyQuery()];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
#endif
    }
}

+ (MPAppDelegate *)get {
    
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    return (MPAppDelegate *)[UIApplication sharedApplication].delegate;
#elif defined (__MAC_OS_X_VERSION_MIN_REQUIRED)
    return (MPAppDelegate *)[NSApplication sharedApplication].delegate;
#else
#error Unsupported OS.
#endif
}

- (BOOL)tryMasterPassword:(NSString *)tryPassword {
    
    NSData *keyHash = [PearlKeyChain dataOfItemForQuery:keyHashQuery()];
    dbg(@"Key hash %@.", keyHash? @"known": @"NOT known");
    
    if (![tryPassword length])
        return NO;
    
    NSData *tryKey = keyForPassword(tryPassword);
    NSData *tryKeyHash = keyHashForKey(tryKey);
    if (keyHash)
        // A key hash is known -> a key is set.
        // Make sure the user's entered key matches it.
        if (![keyHash isEqual:tryKeyHash]) {
            dbg(@"Key phrase hash mismatch. Expected: %@, answer: %@.", keyHash, tryKeyHash);
            
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
            [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
#endif
            return NO;
        }
    
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPAsked];
#endif
    
    [self updateKey:tryKey];
    return YES;
}

- (void)updateKey:(NSData *)key {
    
    self.key = key;
    
    if (key)
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeySet object:self];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyUnset object:self];
    
    if (key) {
        self.keyHash = keyHashForKey(key);
        self.keyHashHex = [self.keyHash encodeHex];
        
        dbg(@"Updating key hash to: %@.", self.keyHashHex);
        [PearlKeyChain addOrUpdateItemForQuery:keyHashQuery()
                                withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                self.keyHash,                                       (__bridge id)kSecValueData,
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                                                kSecAttrAccessibleWhenUnlocked,                     (__bridge id)kSecAttrAccessible,
#endif
                                                nil]];
        if ([[MPConfig get].storeKey boolValue]) {
            dbg(@"Storing key in key chain.");
            [PearlKeyChain addOrUpdateItemForQuery:keyQuery()
                                    withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    key,                                            (__bridge id)kSecValueData,
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
                                                    kSecAttrAccessibleWhenUnlocked,                 (__bridge id)kSecAttrAccessible,
#endif
                                                    nil]];
        }
        
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointSetKeyphraseLength, key.length]];
#endif
    }
}

- (NSData *)keyWithLength:(NSUInteger)keyLength {
    
    return [self.key subdataWithRange:NSMakeRange(0, MIN(keyLength, self.key.length))];
}

@end
