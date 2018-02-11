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
#import "mpw-marshal.h"
#import "mpw-util.h"

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

- (id)managedObjectContextChanged:(void ( ^ )(NSDictionary<NSManagedObjectID *, NSString *> *affectedObjects))changedBlock {

    NSManagedObjectContext *privateManagedObjectContextIfReady = [self privateManagedObjectContextIfReady];
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
        if (@available(iOS 10.0, macOS 10.12, *))
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

        MPResultType type = activeUser.defaultType;
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

- (MPSiteEntity *)changeSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context toType:(MPResultType)type {

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

- (void)importSites:(NSString *)importData
  askImportPassword:(NSString *( ^ )(NSString *userName))importPassword
    askUserPassword:(NSString *( ^ )(NSString *userName))userPassword
             result:(void ( ^ )(NSError *error))resultBlock {

    NSAssert( ![[NSThread currentThread] isMainThread], @"This method should not be invoked from the main thread." );

    do {
        if ([MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            NSError *error = [self importSites:importData askImportPassword:importPassword askUserPassword:userPassword
                                 saveInContext:context];
            PearlMainQueue( ^{
                resultBlock( error );
            } );
        }])
            break;
        usleep( (useconds_t)(USEC_PER_SEC * 0.2) );
    } while (YES);
}

- (NSError *)importSites:(NSString *)importData
       askImportPassword:(NSString *( ^ )(NSString *userName))askImportPassword
         askUserPassword:(NSString *( ^ )(NSString *userName))askUserPassword
           saveInContext:(NSManagedObjectContext *)context {

    // Read metadata for the import file.
    MPMarshalInfo *info = mpw_marshal_read_info( importData.UTF8String );
    if (info->format == MPMarshalFormatNone)
        return MPError( ([NSError errorWithDomain:MPErrorDomain code:MPErrorMarshalCode userInfo:@{
                @"type"                  : @(MPMarshalErrorFormat),
                NSLocalizedDescriptionKey: @"This is not a Master Password import file.",
        }]), @"While importing sites." );

    // Get master password for import file.
    MPKey *importKey;
    NSString *importMasterPassword;
    do {
        importMasterPassword = askImportPassword( @(info->fullName) );
        if (!importMasterPassword) {
            inf( @"Import cancelled." );
            mpw_marshal_info_free( &info );
            return MPError( ([NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]), @"" );
        }

        importKey = [[MPKey alloc] initForFullName:@(info->fullName) withMasterPassword:importMasterPassword];
    } while ([[[importKey keyIDForAlgorithm:MPAlgorithmForVersion( info->algorithm )] encodeHex]
                            caseInsensitiveCompare:@(info->keyID)] != NSOrderedSame);

    // Parse import data.
    MPMarshalError importError = { .type = MPMarshalSuccess };
    MPMarshalledUser *importUser = mpw_marshal_read( importData.UTF8String, info->format, importMasterPassword.UTF8String, &importError );
    mpw_marshal_info_free( &info );

    @try {
        if (!importUser || importError.type != MPMarshalSuccess)
            return MPError( ([NSError errorWithDomain:MPErrorDomain code:MPErrorMarshalCode userInfo:@{
                    @"type"                  : @(importError.type),
                    NSLocalizedDescriptionKey: @(importError.description),
            }]), @"While importing sites." );

        // Find an existing user to update.
        NSError *error = nil;
        NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
        userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@", @(importUser->fullName)];
        NSArray *users = [context executeFetchRequest:userFetchRequest error:&error];
        if (!users)
            return MPError( error, @"While looking for user: %@.", @(importUser->fullName) );
        if ([users count] > 1)
            return MPMakeError( @"While looking for user: %@, found more than one: %zu",
                    @(importUser->fullName), (size_t)[users count] );

        // Get master key for user.
        MPUserEntity *user = [users lastObject];
        MPKey *userKey = importKey;
        while (user && ![[userKey keyIDForAlgorithm:user.algorithm] isEqualToData:user.keyID]) {
            NSString *userMasterPassword = askUserPassword( user.name );
            if (!userMasterPassword) {
                inf( @"Import cancelled." );
                return MPError( ([NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]), @"" );
            }

            userKey = [[MPKey alloc] initForFullName:@(importUser->fullName) withMasterPassword:userMasterPassword];
        }

        // Update or create user.
        if (!user) {
            user = [MPUserEntity insertNewObjectInContext:context];
            user.name = @(importUser->fullName);
        }
        user.algorithm = MPAlgorithmForVersion( importUser->algorithm );
        user.keyID = [userKey keyIDForAlgorithm:user.algorithm];
        user.avatar = importUser->avatar;
        user.defaultType = importUser->defaultType;
        user.lastUsed = [NSDate dateWithTimeIntervalSince1970:MAX( user.lastUsed.timeIntervalSince1970, importUser->lastUsed )];
        dbg( @"Importing user: %@", [user debugDescription] );

        // Update or create sites.
        for (size_t s = 0; s < importUser->sites_count; ++s) {
            MPMarshalledSite *importSite = &importUser->sites[s];

            // Find an existing site to update.
            NSFetchRequest *siteFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
            siteFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND user == %@", @(importSite->name), user];
            NSArray *existingSites = [context executeFetchRequest:siteFetchRequest error:&error];
            if (!existingSites)
                return MPError( error, @"Lookup of existing sites failed for site: %@, user: %@", @(importSite->name), user.userID );
            if ([existingSites count])
                // Update existing site.
                for (MPSiteEntity *site in existingSites) {
                    [self importSite:importSite protectedByKey:importKey intoSite:site usingKey:userKey];
                    dbg( @"Updated site: %@", [site debugDescription] );
                }
            else {
                // Create new site.
                id<MPAlgorithm> algorithm = MPAlgorithmForVersion( importSite->algorithm );
                Class entityType = [algorithm classOfType:importSite->type];
                if (!entityType)
                    return MPMakeError( @"Invalid site type in import file: %@ has type %lu", @(importSite->name), (long)importSite->type );

                MPSiteEntity *site = (MPSiteEntity *)[entityType insertNewObjectInContext:context];
                site.user = user;

                [self importSite:importSite protectedByKey:importKey intoSite:site usingKey:userKey];
                dbg( @"Created site: %@", [site debugDescription] );
            }
        }

        if (![context saveToStore])
            return MPMakeError( @"Failed saving imported changes." );

        inf( @"Import completed successfully." );
        [[NSNotificationCenter defaultCenter] postNotificationName:MPSitesImportedNotification object:nil userInfo:@{
                MPSitesImportedNotificationUserKey: user
        }];
        return nil;
    }
    @finally {
        mpw_marshal_free( &importUser );
    }
}

- (void)importSite:(const MPMarshalledSite *)importSite protectedByKey:(MPKey *)importKey intoSite:(MPSiteEntity *)site
          usingKey:(MPKey *)userKey {

    site.name = @(importSite->name);
    if (importSite->content)
        [site.algorithm importPassword:@(importSite->content) protectedByKey:importKey intoSite:site usingKey:userKey];
    site.type = importSite->type;
    if ([site isKindOfClass:[MPGeneratedSiteEntity class]])
        ((MPGeneratedSiteEntity *)site).counter = importSite->counter;
    site.algorithm = MPAlgorithmForVersion( importSite->algorithm );
    site.loginName = importSite->loginContent? @(importSite->loginContent): nil;
    site.loginGenerated = importSite->loginType & MPResultTypeClassTemplate;
    site.url = importSite->url? @(importSite->url): nil;
    site.uses = importSite->uses;
    site.lastUsed = [NSDate dateWithTimeIntervalSince1970:importSite->lastUsed];
}

- (void)exportSitesRevealPasswords:(BOOL)revealPasswords
                 askExportPassword:(NSString *( ^ )(NSString *userName))askImportPassword
                            result:(void ( ^ )(NSString *mpsites, NSError *error))resultBlock {

    [MPAppDelegate_Shared managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *user = [self activeUserInContext:context];
        NSString *masterPassword = askImportPassword( user.name );

        inf( @"Exporting sites, %@, for user: %@", revealPasswords? @"revealing passwords": @"omitting passwords", user.userID );
        MPMarshalledUser *exportUser = mpw_marshal_user( user.name.UTF8String, masterPassword.UTF8String, user.algorithm.version );
        exportUser->redacted = !revealPasswords;
        exportUser->avatar = (unsigned int)user.avatar;
        exportUser->defaultType = user.defaultType;
        exportUser->lastUsed = (time_t)user.lastUsed.timeIntervalSince1970;

        for (MPSiteEntity *site in user.sites) {
            MPCounterValue counter = MPCounterValueInitial;
            if ([site isKindOfClass:[MPGeneratedSiteEntity class]])
                counter = ((MPGeneratedSiteEntity *)site).counter;
            NSString *content = revealPasswords
                                ? [site.algorithm exportPasswordForSite:site usingKey:self.key]
                                : [site.algorithm resolvePasswordForSite:site usingKey:self.key];

            MPMarshalledSite *exportSite = mpw_marshal_site( exportUser,
                    site.name.UTF8String, site.type, counter, site.algorithm.version );
            exportSite->content = content.UTF8String;
            exportSite->loginContent = site.loginName.UTF8String;
            exportSite->loginType = site.loginGenerated? MPResultTypeTemplateName: MPResultTypeStatefulPersonal;
            exportSite->url = site.url.UTF8String;
            exportSite->uses = (unsigned int)site.uses;
            exportSite->lastUsed = (time_t)site.lastUsed.timeIntervalSince1970;

            for (MPSiteQuestionEntity *siteQuestion in site.questions)
                mpw_marshal_question( exportSite, siteQuestion.keyword.UTF8String );
        }

        char *export = NULL;
        MPMarshalError exportError = (MPMarshalError){ .type= MPMarshalSuccess };
        mpw_marshal_write( &export, MPMarshalFormatFlat, exportUser, &exportError );
        NSString *mpsites = nil;
        if (export && exportError.type == MPMarshalSuccess)
            mpsites = [NSString stringWithCString:export encoding:NSUTF8StringEncoding];
        mpw_free_string( &export );

        resultBlock( mpsites, exportError.type == MPMarshalSuccess? nil:
                              [NSError errorWithDomain:MPErrorDomain code:MPErrorMarshalCode userInfo:@{
                                      @"type"                  : @(exportError.type),
                                      NSLocalizedDescriptionKey: @(exportError.description),
                              }] );
    }];
}

@end
