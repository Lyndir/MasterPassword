//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPAppDelegate_Store.h"
#import "mpw-marshall.h"

#if TARGET_OS_IPHONE
#define STORE_OPTIONS NSPersistentStoreFileProtectionKey : NSFileProtectionComplete,
#else
#define STORE_OPTIONS
#endif

#define MPMigrationLevelLocalStoreKey @"MPMigrationLevelLocalStoreKey"

typedef NS_ENUM( NSInteger, MPStoreMigrationLevel ) {
    MPStoreMigrationLevelV1,
    MPStoreMigrationLevelV2,
    MPStoreMigrationLevelV3,
    MPStoreMigrationLevelCurrent = MPStoreMigrationLevelV3,
};

@implementation MPAppDelegate_Shared(Store)

PearlAssociatedObjectProperty( NSOperationQueue *, StoreQueue, storeQueue );

PearlAssociatedObjectProperty( NSManagedObjectContext*, PrivateManagedObjectContext, privateManagedObjectContext );

PearlAssociatedObjectProperty( NSManagedObjectContext*, MainManagedObjectContext, mainManagedObjectContext );

PearlAssociatedObjectProperty( NSNumber*, StoreCorrupted, storeCorrupted );

#pragma mark - Core Data setup

+ (NSManagedObjectContext *)managedObjectContextForMainThreadIfReady {

    NSAssert( [[NSThread currentThread] isMainThread], @"Can only access main MOC from the main thread." );
    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext || ![[NSThread currentThread] isMainThread])
        return nil;

    return mainManagedObjectContext;
}

+ (BOOL)managedObjectContextForMainThreadPerformBlock:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock {

    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext)
        return NO;

    [mainManagedObjectContext performBlock:^{
        @try {
            mocBlock( mainManagedObjectContext );
        }
        @catch (id exception) {
            err( @"While performing managed block:\n%@", [exception fullDescription] );
        }
    }];

    return YES;
}

+ (BOOL)managedObjectContextForMainThreadPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock {

    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext)
        return NO;

    [mainManagedObjectContext performBlockAndWait:^{
        @try {
            mocBlock( mainManagedObjectContext );
        }
        @catch (NSException *exception) {
            err( @"While performing managed block:\n%@", [exception fullDescription] );
        }
    }];

    return YES;
}

+ (BOOL)managedObjectContextPerformBlock:(void ( ^ )(NSManagedObjectContext *context))mocBlock {

    NSManagedObjectContext *privateManagedObjectContextIfReady = [[self get] privateManagedObjectContextIfReady];
    if (!privateManagedObjectContextIfReady)
        return NO;

    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    moc.parentContext = privateManagedObjectContextIfReady;
    [moc performBlock:^{
        @try {
            mocBlock( moc );
        }
        @catch (NSException *exception) {
            err( @"While performing managed block:\n%@", [exception fullDescription] );
        }
    }];

    return YES;
}

+ (BOOL)managedObjectContextPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *context))mocBlock {

    NSManagedObjectContext *privateManagedObjectContextIfReady = [[self get] privateManagedObjectContextIfReady];
    if (!privateManagedObjectContextIfReady)
        return NO;

    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    moc.parentContext = privateManagedObjectContextIfReady;
    [moc performBlockAndWait:^{
        @try {
            mocBlock( moc );
        }
        @catch (NSException *exception) {
            err( @"While performing managed block:\n%@", [exception fullDescription] );
        }
    }];

    return YES;
}

+ (id)managedObjectContextChanged:(void ( ^ )(NSDictionary<NSManagedObjectID *, NSString *> *affectedObjects))changedBlock {

    NSManagedObjectContext *privateManagedObjectContextIfReady = [[self get] privateManagedObjectContextIfReady];
    if (!privateManagedObjectContextIfReady)
        return nil;

    return PearlAddNotificationObserver( NSManagedObjectContextObjectsDidChangeNotification, privateManagedObjectContextIfReady, nil,
            ^(id host, NSNotification *note) {
                NSMutableDictionary *affectedObjects = [NSMutableDictionary new];
                for (NSManagedObject *object in note.userInfo[NSInsertedObjectsKey])
                    affectedObjects[object.objectID] = NSInsertedObjectsKey;
                for (NSManagedObject *object in note.userInfo[NSUpdatedObjectsKey])
                    affectedObjects[object.objectID] = NSUpdatedObjectsKey;
                for (NSManagedObject *object in note.userInfo[NSDeletedObjectsKey])
                    affectedObjects[object.objectID] = NSDeletedObjectsKey;
                changedBlock( affectedObjects );
            } );
}

- (NSManagedObjectContext *)mainManagedObjectContextIfReady {

    [self loadStore];
    return self.mainManagedObjectContext;
}

- (NSManagedObjectContext *)privateManagedObjectContextIfReady {

    [self loadStore];
    return self.privateManagedObjectContext;
}

- (NSURL *)localStoreURL {

    NSURL *applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                           inDomains:NSUserDomainMask] lastObject];
    return [[[applicationSupportURL
            URLByAppendingPathComponent:[NSBundle mainBundle].bundleIdentifier isDirectory:YES]
            URLByAppendingPathComponent:@"MasterPassword" isDirectory:NO]
            URLByAppendingPathExtension:@"sqlite"];
}

- (void)loadStore {

    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        (self.storeQueue = [NSOperationQueue new]).maxConcurrentOperationCount = 1;
    } );

    // Do nothing if already fully set up, otherwise (re-)load the store.
    if (self.storeCoordinator && self.mainManagedObjectContext && self.privateManagedObjectContext)
        return;

    [self.storeQueue addOperationWithBlock:^{
        // Do nothing if already fully set up, otherwise (re-)load the store.
        if (self.storeCoordinator && self.mainManagedObjectContext && self.privateManagedObjectContext)
            return;

        // Unregister any existing observers and contexts.
        PearlRemoveNotificationObserversFrom( self.mainManagedObjectContext );
        [self.mainManagedObjectContext performBlockAndWait:^{
            [self.mainManagedObjectContext reset];
            self.mainManagedObjectContext = nil;
        }];
        [self.privateManagedObjectContext performBlockAndWait:^{
            [self.privateManagedObjectContext reset];
            self.privateManagedObjectContext = nil;
        }];

        // Don't load when the store is corrupted.
        if ([self.storeCorrupted boolValue])
            return;

        // Check if migration is necessary.
        [self migrateStore];

        // Install managed object contexts and observers.
        self.privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [self.privateManagedObjectContext performBlockAndWait:^{
            self.privateManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            self.privateManagedObjectContext.persistentStoreCoordinator = self.storeCoordinator;
        }];

        self.mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        self.mainManagedObjectContext.parentContext = self.privateManagedObjectContext;
        if ([self.mainManagedObjectContext respondsToSelector:@selector( automaticallyMergesChangesFromParent )]) // iOS 10+
            self.mainManagedObjectContext.automaticallyMergesChangesFromParent = YES;
        else
            // When privateManagedObjectContext is saved, import the changes into mainManagedObjectContext.
            PearlAddNotificationObserverTo( self.mainManagedObjectContext, NSManagedObjectContextDidSaveNotification,
                    self.privateManagedObjectContext, nil, ^(NSManagedObjectContext *mainContext, NSNotification *note) {
                [mainContext performBlock:^{
                    @try {
                        [mainContext mergeChangesFromContextDidSaveNotification:note];
                    }
                    @catch (NSException *exception) {
                        err( @"While merging changes:\n%@", [exception fullDescription] );
                    }
                }];
            } );


        // Create a new store coordinator.
        NSError *error = nil;
        NSURL *localStoreURL = [self localStoreURL];
        if (![[NSFileManager defaultManager] createDirectoryAtURL:[localStoreURL URLByDeletingLastPathComponent]
                                      withIntermediateDirectories:YES attributes:nil error:&error]) {
            MPError( error, @"Couldn't create our application support directory." );
            return;
        }
        if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[self localStoreURL]
                                                       options:@{
                                                               NSMigratePersistentStoresAutomaticallyOption: @YES,
                                                               NSInferMappingModelAutomaticallyOption      : @YES,
                                                               STORE_OPTIONS
                                                       } error:&error]) {
            MPError( error, @"Failed to open store." );
            self.storeCorrupted = @YES;
            [self handleCoordinatorError:error];
            return;
        }
        self.storeCorrupted = @NO;

#if TARGET_OS_IPHONE
        PearlAddNotificationObserver( UIApplicationWillResignActiveNotification, UIApp, [NSOperationQueue mainQueue],
                ^(MPAppDelegate_Shared *self, NSNotification *note) {
                    [self.mainManagedObjectContext saveToStore];
                } );
#else
        PearlAddNotificationObserver( NSApplicationWillResignActiveNotification, NSApp, [NSOperationQueue mainQueue],
                ^(MPAppDelegate_Shared *self, NSNotification *note) {
                    [self.mainManagedObjectContext saveToStore];
                } );
#endif

        // Perform a data sanity check on the newly loaded store to find and fix any issues.
        if ([[MPConfig get].checkInconsistency boolValue])
            [MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
                [self findAndFixInconsistenciesSaveInContext:context];
            }];
    }];
}

- (void)deleteAndResetStore {

    @synchronized (self) {
        // Unregister any existing observers and contexts.
        PearlRemoveNotificationObserversFrom( self.mainManagedObjectContext );
        [self.mainManagedObjectContext performBlockAndWait:^{
            [self.mainManagedObjectContext reset];
            self.mainManagedObjectContext = nil;
        }];
        [self.privateManagedObjectContext performBlockAndWait:^{
            [self.privateManagedObjectContext reset];
            self.privateManagedObjectContext = nil;
        }];
        NSError *error = nil;
        for (NSPersistentStore *store in self.storeCoordinator.persistentStores) {
            if (![self.storeCoordinator removePersistentStore:store error:&error])
                MPError( error, @"Couldn't remove persistence store from coordinator." );
        }
        if (![[NSFileManager defaultManager] removeItemAtURL:self.localStoreURL error:&error])
            MPError( error, @"Couldn't remove persistence store at URL %@.", self.localStoreURL );

        [self loadStore];
    }
}

- (MPFixableResult)findAndFixInconsistenciesSaveInContext:(NSManagedObjectContext *)context {

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    fetchRequest.fetchBatchSize = 50;

    MPFixableResult result = MPFixableResultNoProblems;
    for (NSEntityDescription *entity in [context.persistentStoreCoordinator.managedObjectModel entities])
        if (class_conformsToProtocol( NSClassFromString( entity.managedObjectClassName ), @protocol(MPFixable) )) {
            fetchRequest.entity = entity;
            NSArray *objects = [context executeFetchRequest:fetchRequest error:&error];
            if (!objects) {
                MPError( error, @"Failed to fetch %@ objects.", entity );
                continue;
            }

            for (NSManagedObject<MPFixable> *object in objects)
                result = MPApplyFix( result, ^MPFixableResult {
                    return [object findAndFixInconsistenciesInContext:context];
                } );
        }

    if (result == MPFixableResultNoProblems)
        inf( @"Sanity check found no problems in store." );

    else {
        [context saveToStore];
        [[NSNotificationCenter defaultCenter] postNotificationName:MPFoundInconsistenciesNotification object:nil userInfo:@{
                MPInconsistenciesFixResultUserKey: @(result)
        }];
    }

    return result;
}

- (void)migrateStore {

    MPStoreMigrationLevel migrationLevel = (MPStoreMigrationLevel)
            [[NSUserDefaults standardUserDefaults] integerForKey:MPMigrationLevelLocalStoreKey];
    if (migrationLevel >= MPStoreMigrationLevelCurrent)
        // Local store up-to-date.
        return;

    inf( @"Local store migration level: %d (current %d)", (signed)migrationLevel, (signed)MPStoreMigrationLevelCurrent );
    if (migrationLevel <= MPStoreMigrationLevelV1 && ![self migrateV1LocalStore]) {
        inf( @"Failed to migrate old V1 to new local store." );
        return;
    }
    if (migrationLevel <= MPStoreMigrationLevelV2 && ![self migrateV2LocalStore]) {
        inf( @"Failed to migrate old V2 to new local store." );
        return;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:MPStoreMigrationLevelCurrent forKey:MPMigrationLevelLocalStoreKey];
    inf( @"Successfully migrated old to new local store." );
    if (![[NSUserDefaults standardUserDefaults] synchronize])
        wrn( @"Couldn't synchronize after store migration." );
}

- (BOOL)migrateV1LocalStore {

    NSURL *applicationFilesDirectory = [[[NSFileManager defaultManager]
            URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *oldLocalStoreURL = [[applicationFilesDirectory
            URLByAppendingPathComponent:@"MasterPassword" isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:oldLocalStoreURL.path isDirectory:NULL]) {
        inf( @"No V1 local store to migrate." );
        return YES;
    }

    inf( @"Migrating V1 local store" );
    NSURL *newLocalStoreURL = [self localStoreURL];
    if (![[NSFileManager defaultManager] fileExistsAtPath:newLocalStoreURL.path isDirectory:NULL]) {
        inf( @"New local store already exists." );
        return YES;
    }

    NSError *error = nil;
    if (![NSPersistentStore migrateStore:oldLocalStoreURL withOptions:@{ STORE_OPTIONS }
                                 toStore:newLocalStoreURL withOptions:@{ STORE_OPTIONS }
                                   error:&error]) {
        MPError( error, @"Couldn't migrate the old store to the new location." );
        return NO;
    }

    return YES;
}

- (BOOL)migrateV2LocalStore {

    NSURL *applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                                           inDomains:NSUserDomainMask] lastObject];
    NSURL *oldLocalStoreURL;
    // On iOS, each app is in a sandbox so we don't need to app-scope this directory.
#if TARGET_OS_IPHONE
    oldLocalStoreURL = [[applicationSupportURL
            URLByAppendingPathComponent:@"UbiquityStore" isDirectory:NO]
            URLByAppendingPathExtension:@"sqlite"];
#else
    // The directory is shared between all apps on the system so we need to scope it for the running app.
    oldLocalStoreURL = [[[applicationSupportURL
            URLByAppendingPathComponent:[NSRunningApplication currentApplication].bundleIdentifier isDirectory:YES]
            URLByAppendingPathComponent:@"UbiquityStore" isDirectory:NO]
            URLByAppendingPathExtension:@"sqlite"];
#endif

    if (![[NSFileManager defaultManager] fileExistsAtPath:oldLocalStoreURL.path isDirectory:NULL]) {
        inf( @"No V2 local store to migrate." );
        return YES;
    }

    inf( @"Migrating V2 local store" );
    NSURL *newLocalStoreURL = [self localStoreURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:newLocalStoreURL.path isDirectory:NULL]) {
        inf( @"New local store already exists." );
        return YES;
    }

    NSError *error = nil;
    if (![NSPersistentStore migrateStore:oldLocalStoreURL withOptions:@{
            NSMigratePersistentStoresAutomaticallyOption: @YES,
            NSInferMappingModelAutomaticallyOption      : @YES,
            STORE_OPTIONS
    }                            toStore:newLocalStoreURL withOptions:@{
            NSMigratePersistentStoresAutomaticallyOption: @YES,
            NSInferMappingModelAutomaticallyOption      : @YES,
            STORE_OPTIONS
    }                              error:&error]) {
        MPError( error, @"Couldn't migrate the old store to the new location." );
        return NO;
    }

    return YES;
}

//- (BOOL)migrateV3LocalStore {
//
//    inf( @"Migrating V3 local store" );
//    NSURL *localStoreURL = [self localStoreURL];
//    if (![[NSFileManager defaultManager] fileExistsAtPath:localStoreURL.path isDirectory:NULL]) {
//        inf( @"No V3 local store to migrate." );
//        return YES;
//    }
//
//    NSError *error = nil;
//    NSDictionary<NSString *, id> *metadata = [NSPersistentStore metadataForPersistentStoreWithURL:localStoreURL error:&error];
//    if (!metadata) {
//        MPError( error, @"Couldn't inspect metadata for store: %@", localStoreURL );
//        return NO;
//    }
//    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:
//            [NSManagedObjectModel mergedModelFromBundles:nil forStoreMetadata:metadata]];
//    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
//                                             URL:localStoreURL options:@{ STORE_OPTIONS }
//                                           error:&error]) {
//        MPError( error, @"Couldn't open V3 local store to migrate." );
//        return NO;
//    }
//
//    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//    [context performBlockAndWait:^{
//        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
//        context.persistentStoreCoordinator = coordinator;
//        for (MPStoredSiteEntity *storedSite in [[MPStoredSiteEntity fetchRequest] execute:&error]) {
//            id contentObject = [storedSite valueForKey:@"contentObject"];
//            if ([contentObject isKindOfClass:[NSData class]])
//                storedSite.contentObject = contentObject;
//        }
//    }];
//
//    return YES;
//}

#pragma mark - Utilities

- (void)addSiteNamed:(NSString *)siteName completion:(void ( ^ )(MPSiteEntity *site, NSManagedObjectContext *context))completion {

    if (![siteName length]) {
        completion( nil, nil );
        return;
    }

    [MPAppDelegate_Shared managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [self activeUserInContext:context];
        NSAssert( activeUser, @"Missing user." );
        if (!activeUser) {
            completion( nil, nil );
            return;
        }

        MPSiteType type = activeUser.defaultType;
        id<MPAlgorithm> algorithm = MPAlgorithmDefault;
        Class entityType = [algorithm classOfType:type];

        MPSiteEntity *site = (MPSiteEntity *)[entityType insertNewObjectInContext:context];
        site.name = siteName;
        site.user = activeUser;
        site.type = type;
        site.lastUsed = [NSDate date];
        site.algorithm = algorithm;

        [context saveToStore];

        completion( site, context );
    }];
}

- (MPSiteEntity *)changeSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context toType:(MPSiteType)type {

    if (site.type == type)
        return site;

    if ([site.algorithm classOfType:type] == site.typeClass) {
        site.type = type;
        [context saveToStore];
    }

    else {
        // Type requires a different class of site.  Recreate the site.
        Class entityType = [site.algorithm classOfType:type];
        MPSiteEntity *newSite = (MPSiteEntity *)[entityType insertNewObjectInContext:context];
        newSite.type = type;
        newSite.name = site.name;
        newSite.user = site.user;
        newSite.uses = site.uses;
        newSite.lastUsed = site.lastUsed;
        newSite.algorithm = site.algorithm;
        newSite.loginName = site.loginName;

        [context deleteObject:site];
        [context saveToStore];

        [[NSNotificationCenter defaultCenter] postNotificationName:MPSiteUpdatedNotification object:site.permanentObjectID];
        site = newSite;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:MPSiteUpdatedNotification object:site.permanentObjectID];
    return site;
}

- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *( ^ )(NSString *userName))importPassword
              askUserPassword:(NSString *( ^ )(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword {

    NSAssert( ![[NSThread currentThread] isMainThread], @"This method should not be invoked from the main thread." );

    __block MPImportResult result = MPImportResultCancelled;
    do {
        if ([MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            result = [self importSites:importedSitesString askImportPassword:importPassword askUserPassword:userPassword
                         saveInContext:context];
        }])
            break;
        usleep( (useconds_t)(USEC_PER_SEC * 0.2) );
    } while (YES);

    return result;
}

- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *( ^ )(NSString *userName))askImportPassword
              askUserPassword:(NSString *( ^ )(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))askUserPassword
                saveInContext:(NSManagedObjectContext *)context {

    // Compile patterns.
    static NSRegularExpression *headerPattern;
    static NSArray *sitePatterns;
    NSError *error = nil;
    if (!headerPattern) {
        headerPattern = [[NSRegularExpression alloc]
                initWithPattern:@"^#[[:space:]]*([^:]+): (.*)"
                        options:(NSRegularExpressionOptions)0 error:&error];
        if (error) {
            MPError( error, @"Error loading the header pattern." );
            return MPImportResultInternalError;
        }
    }
    if (!sitePatterns) {
        sitePatterns = @[
                [[NSRegularExpression alloc] // Format 0
                        initWithPattern:@"^([^ ]+) +([[:digit:]]+) +([[:digit:]]+)(:[[:digit:]]+)? +([^\t]+)\t(.*)"
                                options:(NSRegularExpressionOptions)0 error:&error],
                [[NSRegularExpression alloc] // Format 1
                        initWithPattern:@"^([^ ]+) +([[:digit:]]+) +([[:digit:]]+)(:[[:digit:]]+)?(:[[:digit:]]+)? +([^\t]*)\t *([^\t]+)\t(.*)"
                                options:(NSRegularExpressionOptions)0 error:&error]
        ];
        if (error) {
            MPError( error, @"Error loading the site patterns." );
            return MPImportResultInternalError;
        }
    }

    // Parse import data.
    inf( @"Importing sites." );
    NSUInteger importFormat = 0;
    __block MPUserEntity *user = nil;
    NSUInteger importAvatar = NSNotFound;
    NSData *importKeyID = nil;
    NSString *importBundleVersion = nil, *importUserName = nil;
    id<MPAlgorithm> importAlgorithm = nil;
    MPSiteType importDefaultType = (MPSiteType)0;
    BOOL headerStarted = NO, headerEnded = NO, clearText = NO;
    NSArray *importedSiteLines = [importedSitesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableSet *sitesToDelete = [NSMutableSet set];
    NSMutableArray *importedSiteSites = [NSMutableArray arrayWithCapacity:[importedSiteLines count]];
    NSFetchRequest *siteFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
    for (NSString *importedSiteLine in importedSiteLines) {
        if ([importedSiteLine hasPrefix:@"#"]) {
            // Comment or header
            if (!headerStarted) {
                if ([importedSiteLine isEqualToString:@"##"])
                    headerStarted = YES;
                continue;
            }
            if (headerEnded)
                continue;
            if ([importedSiteLine isEqualToString:@"##"]) {
                headerEnded = YES;
                continue;
            }

            // Header
            if ([headerPattern numberOfMatchesInString:importedSiteLine options:(NSMatchingOptions)0
                                                 range:NSMakeRange( 0, [importedSiteLine length] )] != 1) {
                err( @"Invalid header format in line: %@", importedSiteLine );
                return MPImportResultMalformedInput;
            }
            NSTextCheckingResult *headerSites = [[headerPattern matchesInString:importedSiteLine options:(NSMatchingOptions)0
                                                                          range:NSMakeRange( 0, [importedSiteLine length] )] lastObject];
            NSString *headerName = [importedSiteLine substringWithRange:[headerSites rangeAtIndex:1]];
            NSString *headerValue = [importedSiteLine substringWithRange:[headerSites rangeAtIndex:2]];

            if ([headerName isEqualToString:@"Format"]) {
                importFormat = (NSUInteger)[headerValue integerValue];
                if (importFormat >= [sitePatterns count]) {
                    err( @"Unsupported import format: %lu", (unsigned long)importFormat );
                    return MPImportResultInternalError;
                }
            }
            if (([headerName isEqualToString:@"User Name"] || [headerName isEqualToString:@"Full Name"]) && !importUserName) {
                importUserName = headerValue;

                NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
                userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@", importUserName];
                NSArray *users = [context executeFetchRequest:userFetchRequest error:&error];
                if (!users) {
                    MPError( error, @"While looking for user: %@.", importUserName );
                    return MPImportResultInternalError;
                }
                if ([users count] > 1) {
                    err( @"While looking for user: %@, found more than one: %lu", importUserName, (unsigned long)[users count] );
                    return MPImportResultInternalError;
                }

                user = [users lastObject];
                dbg( @"Existing user? %@", [user debugDescription] );
            }
            if ([headerName isEqualToString:@"Avatar"])
                importAvatar = (NSUInteger)[headerValue integerValue];
            if ([headerName isEqualToString:@"Key ID"])
                importKeyID = [headerValue decodeHex];
            if ([headerName isEqualToString:@"Version"]) {
                importBundleVersion = headerValue;
                importAlgorithm = MPAlgorithmDefaultForBundleVersion( importBundleVersion );
            }
            if ([headerName isEqualToString:@"Algorithm"])
                importAlgorithm = MPAlgorithmForVersion( (MPAlgorithmVersion)[headerValue integerValue] );
            if ([headerName isEqualToString:@"Default Type"])
                importDefaultType = (MPSiteType)[headerValue integerValue];
            if ([headerName isEqualToString:@"Passwords"]) {
                if ([headerValue isEqualToString:@"VISIBLE"])
                    clearText = YES;
            }

            continue;
        }
        if (!headerEnded)
            continue;
        if (![importUserName length])
            return MPImportResultMalformedInput;
        if (![importedSiteLine length])
            continue;

        // Site
        NSRegularExpression *sitePattern = sitePatterns[importFormat];
        if ([sitePattern numberOfMatchesInString:importedSiteLine options:(NSMatchingOptions)0
                                           range:NSMakeRange( 0, [importedSiteLine length] )] != 1) {
            err( @"Invalid site format in line: %@", importedSiteLine );
            return MPImportResultMalformedInput;
        }
        NSTextCheckingResult *siteElements = [[sitePattern matchesInString:importedSiteLine options:(NSMatchingOptions)0
                                                                     range:NSMakeRange( 0, [importedSiteLine length] )] lastObject];
        NSString *lastUsed, *uses, *type, *version, *counter, *siteName, *loginName, *exportContent;
        switch (importFormat) {
            case 0:
                lastUsed = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
                uses = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
                type = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
                version = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
                if ([version length])
                    version = [version substringFromIndex:1]; // Strip the leading colon.
                counter = @"";
                loginName = @"";
                siteName = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
                exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:6]];
                break;
            case 1:
                lastUsed = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
                uses = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
                type = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
                version = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
                if ([version length])
                    version = [version substringFromIndex:1]; // Strip the leading colon.
                counter = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
                if ([counter length])
                    counter = [counter substringFromIndex:1]; // Strip the leading colon.
                loginName = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:6]];
                siteName = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:7]];
                exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:8]];
                break;
            default:
                err( @"Unexpected import format: %lu", (unsigned long)importFormat );
                return MPImportResultInternalError;
        }

        // Find existing site.
        if (user) {
            siteFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND user == %@", siteName, user];
            NSArray *existingSites = [context executeFetchRequest:siteFetchRequest error:&error];
            if (!existingSites) {
                MPError( error, @"Lookup of existing sites failed for site: %@, user: %@.", siteName, user.userID );
                return MPImportResultInternalError;
            }
            if ([existingSites count]) {
                dbg( @"Existing sites: %@", existingSites );
                [sitesToDelete addObjectsFromArray:existingSites];
            }
        }
        [importedSiteSites addObject:@[ lastUsed, uses, type, version, counter, loginName, siteName, exportContent ]];
        dbg( @"Will import site: lastUsed=%@, uses=%@, type=%@, version=%@, counter=%@, loginName=%@, siteName=%@, exportContent=%@",
                lastUsed, uses, type, version, counter, loginName, siteName, exportContent );
    }

    // Ask for confirmation to import these sites and the master password of the user.
    inf( @"Importing %lu sites, deleting %lu sites, for user: %@", (unsigned long)[importedSiteSites count],
            (unsigned long)[sitesToDelete count], [MPUserEntity idFor:importUserName] );
    NSString *userMasterPassword = askUserPassword( user? user.name: importUserName, [importedSiteSites count],
            [sitesToDelete count] );
    if (!userMasterPassword) {
        inf( @"Import cancelled." );
        return MPImportResultCancelled;
    }
    MPKey *userKey = [[MPKey alloc] initForFullName:user? user.name: importUserName withMasterPassword:userMasterPassword];
    if (user && ![[userKey keyIDForAlgorithm:user.algorithm] isEqualToData:user.keyID])
        return MPImportResultInvalidPassword;
    __block MPKey *importKey = userKey;
    if (importKeyID && ![[importKey keyIDForAlgorithm:importAlgorithm] isEqualToData:importKeyID])
        importKey = [[MPKey alloc] initForFullName:importUserName withMasterPassword:askImportPassword( importUserName )];
    if (importKeyID && ![[importKey keyIDForAlgorithm:importAlgorithm] isEqualToData:importKeyID])
        return MPImportResultInvalidPassword;

    // Delete existing sites.
    if (sitesToDelete.count)
        [sitesToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            inf( @"Deleting site: %@, it will be replaced by an imported site.", [obj name] );
            [context deleteObject:obj];
        }];

    // Make sure there is a user.
    if (user) {
        if (importAvatar != NSNotFound)
            user.avatar = importAvatar;
        if (importDefaultType)
            user.defaultType = importDefaultType;
        dbg( @"Updating User: %@", [user debugDescription] );
    }
    else {
        user = [MPUserEntity insertNewObjectInContext:context];
        user.name = importUserName;
        user.algorithm = MPAlgorithmDefault;
        user.keyID = [userKey keyIDForAlgorithm:user.algorithm];
        user.defaultType = importDefaultType?: user.algorithm.defaultType;
        if (importAvatar != NSNotFound)
            user.avatar = importAvatar;
        dbg( @"Created User: %@", [user debugDescription] );
    }

    // Import new sites.
    for (NSArray *siteElements in importedSiteSites) {
        NSDate *lastUsed = [[NSDateFormatter rfc3339DateFormatter] dateFromString:siteElements[0]];
        NSUInteger uses = (unsigned)[siteElements[1] integerValue];
        MPSiteType type = (MPSiteType)[siteElements[2] integerValue];
        MPAlgorithmVersion version = (MPAlgorithmVersion)[siteElements[3] integerValue];
        NSUInteger counter = [siteElements[4] length]? (unsigned)[siteElements[4] integerValue]: NSNotFound;
        NSString *loginName = [siteElements[5] length]? siteElements[5]: nil;
        NSString *siteName = siteElements[6];
        NSString *exportContent = siteElements[7];

        // Create new site.
        id<MPAlgorithm> algorithm = MPAlgorithmForVersion( version );
        Class entityType = [algorithm classOfType:type];
        if (!entityType) {
            err( @"Invalid site type in import file: %@ has type %lu", siteName, (long)type );
            return MPImportResultInternalError;
        }
        MPSiteEntity *site = (MPSiteEntity *)[entityType insertNewObjectInContext:context];
        site.name = siteName;
        site.loginName = loginName;
        site.user = user;
        site.type = type;
        site.uses = uses;
        site.lastUsed = lastUsed;
        site.algorithm = algorithm;
        if ([exportContent length]) {
            if (clearText)
                [site.algorithm importClearTextPassword:exportContent intoSite:site usingKey:userKey];
            else
                [site.algorithm importProtectedPassword:exportContent protectedByKey:importKey intoSite:site usingKey:userKey];
        }
        if ([site isKindOfClass:[MPGeneratedSiteEntity class]] && counter != NSNotFound)
            ((MPGeneratedSiteEntity *)site).counter = counter;

        dbg( @"Created Site: %@", [site debugDescription] );
    }

    if (![context saveToStore])
        return MPImportResultInternalError;

    inf( @"Import completed successfully." );

    [[NSNotificationCenter defaultCenter] postNotificationName:MPSitesImportedNotification object:nil userInfo:@{
            MPSitesImportedNotificationUserKey: user
    }];

    return MPImportResultSuccess;
}

- (NSString *)exportSitesRevealPasswords:(BOOL)revealPasswords {

    MPUserEntity *activeUser = [self activeUserForMainThread];
    inf( @"Exporting sites, %@, for user: %@", revealPasswords? @"revealing passwords": @"omitting passwords", activeUser.userID );

    MPMarshalledUser exportUser = mpw_marshall_user( activeUser.name.UTF8String,
            [self.key keyForAlgorithm:activeUser.algorithm], activeUser.algorithm.version );
    exportUser.avatar = activeUser.avatar;
    exportUser.defaultType = activeUser.defaultType;
    exportUser.lastUsed = (time_t)activeUser.lastUsed.timeIntervalSince1970;


    for (MPSiteEntity *site in activeUser.sites) {
        MPMarshalledSite exportSite = mpw_marshall_site( &exportUser,
                site.name.UTF8String, site.type, site.counter, site.algorithm.version );
        exportSite.loginName = site.loginName.UTF8String;
        exportSite.url = site.url.UTF8String;
        exportSite.uses = site.uses;
        exportSite.lastUsed = (time_t)site.lastUsed.timeIntervalSince1970;

        for (MPSiteQuestionEntity *siteQuestion in site.questions)
            mpw_marshal_question( &exportSite, siteQuestion.keyword.UTF8String );
    }

    mpw_marshall_write( &export, MPMarshallFormatFlat, exportUser );
}

@end
