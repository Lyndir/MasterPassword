//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Store.h"

#if TARGET_OS_IPHONE
#define STORE_OPTIONS NSPersistentStoreFileProtectionKey : NSFileProtectionComplete,
#else
#define STORE_OPTIONS
#endif

#define MPCloudContainerIdentifier @"HL3Q45LX9N.com.lyndir.lhunath.MasterPassword.shared"
#define MPMigrationLevelLocalStoreKey @"MPMigrationLevelLocalStoreKey"
#define MPMigrationLevelCloudStoreKey @"MPMigrationLevelCloudStoreKey"

typedef NS_ENUM( NSInteger, MPMigrationLevelLocalStore ) {
    MPMigrationLevelLocalStoreV1,
    MPMigrationLevelLocalStoreV2,
    MPMigrationLevelLocalStoreCurrent = MPMigrationLevelLocalStoreV2,
};

typedef NS_ENUM( NSInteger, MPMigrationLevelCloudStore ) {
    MPMigrationLevelCloudStoreV1,
    MPMigrationLevelCloudStoreV2,
    MPMigrationLevelCloudStoreV3,
    MPMigrationLevelCloudStoreCurrent = MPMigrationLevelCloudStoreV3,
};

@implementation MPAppDelegate_Shared(Store)

PearlAssociatedObjectProperty( id, SaveObserver, saveObserver );

PearlAssociatedObjectProperty( NSManagedObjectContext*, PrivateManagedObjectContext, privateManagedObjectContext );

PearlAssociatedObjectProperty( NSManagedObjectContext*, MainManagedObjectContext, mainManagedObjectContext );

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
        mocBlock( mainManagedObjectContext );
    }];

    return YES;
}

+ (BOOL)managedObjectContextForMainThreadPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock {

    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext)
        return NO;

    [mainManagedObjectContext performBlockAndWait:^{
        mocBlock( mainManagedObjectContext );
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
        mocBlock( moc );
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
        mocBlock( moc );
    }];

    return YES;
}

- (NSManagedObjectContext *)mainManagedObjectContextIfReady {

    [self storeManager];
    return self.mainManagedObjectContext;
}

- (NSManagedObjectContext *)privateManagedObjectContextIfReady {

    [self storeManager];
    return self.privateManagedObjectContext;
}

- (UbiquityStoreManager *)storeManager {

    static UbiquityStoreManager *storeManager = nil;
    if (storeManager)
        return storeManager;

    storeManager = [[UbiquityStoreManager alloc] initStoreNamed:nil withManagedObjectModel:nil localStoreURL:nil
                                            containerIdentifier:MPCloudContainerIdentifier
                                             storeConfiguration:nil storeOptions:@{ STORE_OPTIONS }
                                                       delegate:self];

#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:UIApp
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
                    ^(NSNotification *note) {
                        [[self mainManagedObjectContext] saveToStore];
                    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:UIApp
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
                    ^(NSNotification *note) {
                        [[self mainManagedObjectContext] saveToStore];
                    }];
#else
    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification object:NSApp
                                                       queue:[NSOperationQueue mainQueue] usingBlock:
     ^(NSNotification *note) {
         [self.mainManagedObjectContextIfReady saveToStore];
     }];
#endif

    return storeManager;
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
                err( @"Failed to fetch %@ objects: %@", entity, error );
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
                MPInconsistenciesFixResultUserKey : @(result)
        }];
    }

    return result;
}

- (void)migrateStoreForManager:(UbiquityStoreManager *)manager isCloud:(BOOL)isCloudStore {

    [self migrateLocalStore];

    if (isCloudStore)
        [self migrateCloudStore];
}

- (void)migrateLocalStore {

    MPMigrationLevelLocalStore migrationLevel = (signed)[[NSUserDefaults standardUserDefaults] integerForKey:MPMigrationLevelLocalStoreKey];
    if (migrationLevel >= MPMigrationLevelLocalStoreCurrent)
        // Local store up-to-date.
        return;

    inf( @"Local store migration level: %d (current %d)", (signed)migrationLevel, (signed)MPMigrationLevelLocalStoreCurrent );
    if (migrationLevel <= MPMigrationLevelLocalStoreV1) if (![self migrateV1LocalStore]) {
        inf( @"Failed to migrate old V1 to new local store." );
        return;
    }

    [[NSUserDefaults standardUserDefaults] setInteger:MPMigrationLevelLocalStoreCurrent forKey:MPMigrationLevelLocalStoreKey];
    inf( @"Successfully migrated old to new local store." );
}

- (void)migrateCloudStore {

    MPMigrationLevelCloudStore migrationLevel = (signed)[[NSUserDefaults standardUserDefaults] integerForKey:MPMigrationLevelCloudStoreKey];
    if (migrationLevel >= MPMigrationLevelCloudStoreCurrent)
        // Cloud store up-to-date.
        return;

    inf( @"Cloud store migration level: %d (current %d)", (signed)migrationLevel, (signed)MPMigrationLevelCloudStoreCurrent );
    if (migrationLevel <= MPMigrationLevelCloudStoreV1) {
        if (![self migrateV1CloudStore]) {
            inf( @"Failed to migrate old V1 to new cloud store." );
            return;
        }
    }
    else if (migrationLevel <= MPMigrationLevelCloudStoreV2) {
        if (![self migrateV2CloudStore]) {
            inf( @"Failed to migrate old V2 to new cloud store." );
            return;
        }
    }

    [[NSUserDefaults standardUserDefaults] setInteger:MPMigrationLevelCloudStoreCurrent forKey:MPMigrationLevelCloudStoreKey];
    inf( @"Successfully migrated old to new cloud store." );
}

- (BOOL)migrateV1CloudStore {

    // Migrate cloud enabled preference.
    NSNumber *oldCloudEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"iCloudEnabledKey"];
    if ([oldCloudEnabled boolValue])
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USMCloudEnabledKey];

    // Migrate cloud store.
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"LocalUUIDKey"];
    if (!uuid) {
        inf( @"No V1 cloud store to migrate." );
        return YES;
    }

    inf( @"Migrating V1 cloud store: %@ -> %@", uuid, [self.storeManager valueForKey:@"storeUUID"] );
    NSURL *cloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:MPCloudContainerIdentifier];
    NSURL *oldCloudContentURL = [[cloudContainerURL
            URLByAppendingPathComponent:@"Data" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:YES];
    NSURL *oldCloudStoreURL = [[[cloudContainerURL
            URLByAppendingPathComponent:@"Database.nosync" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];

    return [self migrateFromCloudStore:oldCloudStoreURL cloudContent:oldCloudContentURL];
}

- (BOOL)migrateV2CloudStore {

    // Migrate cloud store.
    NSString *uuid = [[NSUbiquitousKeyValueStore defaultStore] stringForKey:@"USMStoreUUIDKey"];
    if (!uuid) {
        inf( @"No V2 cloud store to migrate." );
        return YES;
    }

    inf( @"Migrating V2 cloud store: %@ -> %@", uuid, [self.storeManager valueForKey:@"storeUUID"] );
    NSURL *cloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:MPCloudContainerIdentifier];
    NSURL *oldCloudContentURL = [[cloudContainerURL
            URLByAppendingPathComponent:@"CloudLogs" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:YES];
    NSURL *oldCloudStoreURL = [[[cloudContainerURL
            URLByAppendingPathComponent:@"CloudStore.nosync" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];

    return [self migrateFromCloudStore:oldCloudStoreURL cloudContent:oldCloudContentURL];
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
    return [self migrateFromLocalStore:oldLocalStoreURL];
}

- (BOOL)migrateFromLocalStore:(NSURL *)oldLocalStoreURL {

    NSURL *newLocalStoreURL = [self.storeManager URLForLocalStore];
    if ([[NSFileManager defaultManager] fileExistsAtPath:newLocalStoreURL.path isDirectory:NULL]) {
        wrn( @"Can't migrate local store: A new local store already exists." );
        return YES;
    }

    if (![self.storeManager migrateStore:oldLocalStoreURL withOptions:nil
                                 toStore:newLocalStoreURL withOptions:nil
                                strategy:0 error:nil cause:nil context:nil]) {
        self.storeManager.localStoreURL = oldLocalStoreURL;
        return NO;
    }

    inf( @"Successfully migrated to new local store." );
    return YES;
}

- (BOOL)migrateFromCloudStore:(NSURL *)oldCloudStoreURL cloudContent:(NSURL *)oldCloudContentURL {

    if (![self.storeManager cloudSafeForSeeding]) {
        inf( @"Can't migrate cloud store: A new cloud store already exists." );
        return YES;
    }

    NSURL *newCloudStoreURL = [self.storeManager URLForCloudStore];
    if (![self.storeManager migrateStore:oldCloudStoreURL withOptions:nil
                                 toStore:newCloudStoreURL withOptions:nil
                                strategy:0 error:nil cause:nil context:nil])
        return NO;

    inf( @"Successfully migrated to new cloud store." );
    return YES;
}

#pragma mark - UbiquityStoreManagerDelegate

- (NSManagedObjectContext *)ubiquityStoreManager:(UbiquityStoreManager *)manager
          managedObjectContextForUbiquityChanges:(NSNotification *)note {

    return [self mainManagedObjectContextIfReady];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager log:(NSString *)message {

    inf( @"[StoreManager] %@", message );
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager willLoadStoreIsCloud:(BOOL)isCloudStore {

    NSManagedObjectContext *moc = [self mainManagedObjectContextIfReady];
    [moc performBlockAndWait:^{
        [moc saveToStore];
        [moc reset];

        if (self.saveObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:self.saveObserver];
            self.saveObserver = nil;
        }

        self.privateManagedObjectContext = nil;
        self.mainManagedObjectContext = nil;
    }];

    [self migrateStoreForManager:manager isCloud:isCloudStore];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didLoadStoreForCoordinator:(NSPersistentStoreCoordinator *)coordinator
                     isCloud:(BOOL)isCloudStore {

    inf( @"Using iCloud? %@", @(isCloudStore) );
    MPCheckpoint( MPCheckpointCloud, @{
            @"enabled" : @(isCloudStore)
    } );

    // Create our contexts.
    NSManagedObjectContext *privateManagedObjectContext =
            [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateManagedObjectContext performBlockAndWait:^{
        privateManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        privateManagedObjectContext.persistentStoreCoordinator = coordinator;

//        dbg(@"===");
//        NSError *error;
//        for (NSEntityDescription *entityDescription in [coordinator.managedObjectModel entities]) {
//            dbg(@"Entities: %@", entityDescription.name);
//            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityDescription.name];
//            NSArray *entities = [privateManagedObjectContext executeFetchRequest:request error:&error];
//            if (!entities)
//            err(@"  - Error: %@", error);
//            else
//                for (id entity in entities)
//                        dbg(@"  - %@", [entity debugDescription]);
//        }
//        dbg(@"===");
    }];

    NSManagedObjectContext *mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    mainManagedObjectContext.parentContext = privateManagedObjectContext;

    if (self.saveObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:self.saveObserver];
    self.saveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                                          object:privateManagedObjectContext queue:nil usingBlock:
                    ^(NSNotification *note) {
                        // When privateManagedObjectContext is saved, import the changes into mainManagedObjectContext.
                        [mainManagedObjectContext performBlock:^{
                            [mainManagedObjectContext mergeChangesFromContextDidSaveNotification:note];
                        }];
                    }];

    self.privateManagedObjectContext = privateManagedObjectContext;
    self.mainManagedObjectContext = mainManagedObjectContext;

    // Perform a data sanity check on the newly loaded store to find and fix any issues.
    if ([[MPConfig get].checkInconsistency boolValue])
        [MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            [self findAndFixInconsistenciesSaveInContext:context];
        }];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didEncounterError:(NSError *)error cause:(UbiquityStoreErrorCause)cause
                     context:(id)context {

    err( @"[StoreManager] ERROR: cause=%@, context=%@, error=%@", NSStringFromUSMCause( cause ), context, error );
    MPCheckpoint( MPCheckpointMPErrorUbiquity, @{
            @"cause"        : @(cause),
            @"error.code"   : @(error.code),
            @"error.domain" : NilToNSNull( error.domain ),
            @"error.reason" : NilToNSNull( [error localizedFailureReason]?: [error localizedDescription] ),
    } );
}

#pragma mark - Utilities

- (void)addElementNamed:(NSString *)siteName completion:(void ( ^ )(MPElementEntity *element, NSManagedObjectContext *context))completion {

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

        MPElementType type = activeUser.defaultType;
        NSString *typeEntityName = [MPAlgorithmDefault classNameOfType:type];

        MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:typeEntityName inManagedObjectContext:context];
        element.name = siteName;
        element.user = activeUser;
        element.type = type;
        element.lastUsed = [NSDate date];
        element.version = MPAlgorithmDefaultVersion;

        NSError *error = nil;
        if (element.objectID.isTemporaryID && ![context obtainPermanentIDsForObjects:@[ element ] error:&error])
            err( @"Failed to obtain a permanent object ID after creating new element: %@", error );

        [context saveToStore];

        completion( element, context );
    }];
}

- (MPElementEntity *)changeElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context toType:(MPElementType)type {

    if (element.type == type)
        return element;

    if ([element.algorithm classOfType:type] == element.typeClass) {
        element.type = type;
        [context saveToStore];
    }

    else {
        // Type requires a different class of element.  Recreate the element.
        NSString *typeEntityName = [element.algorithm classNameOfType:type];
        MPElementEntity *newElement = [NSEntityDescription insertNewObjectForEntityForName:typeEntityName inManagedObjectContext:context];
        newElement.type = type;
        newElement.name = element.name;
        newElement.user = element.user;
        newElement.uses = element.uses;
        newElement.lastUsed = element.lastUsed;
        newElement.version = element.version;
        newElement.loginName = element.loginName;

        NSError *error = nil;
        if (![context obtainPermanentIDsForObjects:@[ newElement ] error:&error])
            err( @"Failed to obtain a permanent object ID after changing object type: %@", error );

        [context deleteObject:element];
        [context saveToStore];

        [[NSNotificationCenter defaultCenter] postNotificationName:MPElementUpdatedNotification object:element.objectID];
        element = newElement;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:MPElementUpdatedNotification object:element.objectID];
    return element;
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
            err( @"Error loading the header pattern: %@", error );
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
            err( @"Error loading the site patterns: %@", error );
            return MPImportResultInternalError;
        }
    }

    // Parse import data.
    inf( @"Importing sites." );
    __block MPUserEntity *user = nil;
    id<MPAlgorithm> importAlgorithm = nil;
    NSUInteger importFormat = 0;
    NSUInteger importAvatar = NSNotFound;
    NSString *importBundleVersion = nil, *importUserName = nil;
    NSData *importKeyID = nil;
    BOOL headerStarted = NO, headerEnded = NO, clearText = NO;
    NSArray *importedSiteLines = [importedSitesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableSet *elementsToDelete = [NSMutableSet set];
    NSMutableArray *importedSiteElements = [NSMutableArray arrayWithCapacity:[importedSiteLines count]];
    NSFetchRequest *elementFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
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
            NSTextCheckingResult *headerElements = [[headerPattern matchesInString:importedSiteLine options:(NSMatchingOptions)0
                                                                             range:NSMakeRange( 0, [importedSiteLine length] )] lastObject];
            NSString *headerName = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:1]];
            NSString *headerValue = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:2]];
            if ([headerName isEqualToString:@"User Name"]) {
                importUserName = headerValue;

                NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
                userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@", importUserName];
                NSArray *users = [context executeFetchRequest:userFetchRequest error:&error];
                if (!users) {
                    err( @"While looking for user: %@, error: %@", importUserName, error );
                    return MPImportResultInternalError;
                }
                if ([users count] > 1) {
                    err( @"While looking for user: %@, found more than one: %lu", importUserName, (unsigned long)[users count] );
                    return MPImportResultInternalError;
                }

                user = [users lastObject];
                dbg( @"Existing user? %@", [user debugDescription] );
            }
            if ([headerName isEqualToString:@"Key ID"])
                importKeyID = [headerValue decodeHex];
            if ([headerName isEqualToString:@"Version"]) {
                importBundleVersion = headerValue;
                importAlgorithm = MPAlgorithmDefaultForBundleVersion( importBundleVersion );
            }
            if ([headerName isEqualToString:@"Format"]) {
                importFormat = [headerValue integerValue];
                if (importFormat >= [sitePatterns count]) {
                    err( @"Unsupported import format: %lu", (unsigned long)importFormat );
                    return MPImportResultInternalError;
                }
            }
            if ([headerName isEqualToString:@"Avatar"])
                importAvatar = [headerValue integerValue];
            if ([headerName isEqualToString:@"Passwords"]) {
                if ([headerValue isEqualToString:@"VISIBLE"])
                    clearText = YES;
            }

            continue;
        }
        if (!headerEnded)
            continue;
        if (!importKeyID || ![importUserName length])
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
            elementFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND user == %@", siteName, user];
            NSArray *existingSites = [context executeFetchRequest:elementFetchRequest error:&error];
            if (!existingSites) {
                err( @"Lookup of existing sites failed for site: %@, user: %@, error: %@", siteName, user.userID, error );
                return MPImportResultInternalError;
            }
            if ([existingSites count]) {
                dbg( @"Existing sites: %@", existingSites );
                [elementsToDelete addObjectsFromArray:existingSites];
            }
        }
        [importedSiteElements addObject:@[ lastUsed, uses, type, version, counter, loginName, siteName, exportContent ]];
        dbg( @"Will import site: lastUsed=%@, uses=%@, type=%@, version=%@, counter=%@, loginName=%@, siteName=%@, exportContent=%@",
                lastUsed, uses, type, version, counter, loginName, siteName, exportContent );
    }

    // Ask for confirmation to import these sites and the master password of the user.
    inf( @"Importing %lu sites, deleting %lu sites, for user: %@", (unsigned long)[importedSiteElements count],
            (unsigned long)[elementsToDelete count], [MPUserEntity idFor:importUserName] );
    NSString *userMasterPassword = askUserPassword( user? user.name: importUserName, [importedSiteElements count],
            [elementsToDelete count] );
    if (!userMasterPassword) {
        inf( @"Import cancelled." );
        return MPImportResultCancelled;
    }
    MPKey *userKey = [MPAlgorithmDefault keyForPassword:userMasterPassword ofUserNamed:user? user.name: importUserName];
    if (user && ![userKey.keyID isEqualToData:user.keyID])
        return MPImportResultInvalidPassword;
    __block MPKey *importKey = userKey;
    if (![importKey.keyID isEqualToData:importKeyID])
        importKey = [importAlgorithm keyForPassword:askImportPassword( importUserName ) ofUserNamed:importUserName];
    if (![importKey.keyID isEqualToData:importKeyID])
        return MPImportResultInvalidPassword;


    // Delete existing sites.
    if (elementsToDelete.count)
        [elementsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            inf( @"Deleting site: %@, it will be replaced by an imported site.", [obj name] );
            [context deleteObject:obj];
        }];

    // Make sure there is a user.
    if (user) {
        if (importAvatar != NSNotFound)
            user.avatar = importAvatar;
        dbg( @"Updating User: %@", [user debugDescription] );
    } else {
        user = [MPUserEntity insertNewObjectInContext:context];
        user.name = importUserName;
        user.keyID = importKeyID;
        if (importAvatar != NSNotFound)
            user.avatar = importAvatar;
        dbg( @"Created User: %@", [user debugDescription] );
    }

    // Import new sites.
    for (NSArray *siteElements in importedSiteElements) {
        NSDate *lastUsed = [[NSDateFormatter rfc3339DateFormatter] dateFromString:siteElements[0]];
        NSUInteger uses = (unsigned)[siteElements[1] integerValue];
        MPElementType type = (MPElementType)[siteElements[2] integerValue];
        NSUInteger version = (unsigned)[siteElements[3] integerValue];
        NSUInteger counter = [siteElements[4] length]? (unsigned)[siteElements[4] integerValue]: NSNotFound;
        NSString *loginName = [siteElements[5] length]? siteElements[5]: nil;
        NSString *siteName = siteElements[6];
        NSString *exportContent = siteElements[7];

        // Create new site.
        NSString *typeEntityName = [MPAlgorithmForVersion( version ) classNameOfType:type];
        MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:typeEntityName inManagedObjectContext:context];
        element.name = siteName;
        element.loginName = loginName;
        element.user = user;
        element.type = type;
        element.uses = uses;
        element.lastUsed = lastUsed;
        element.version = version;
        if ([exportContent length]) {
            if (clearText)
                [element.algorithm importClearTextContent:exportContent intoElement:element usingKey:userKey];
            else
                [element.algorithm importProtectedContent:exportContent protectedByKey:importKey intoElement:element usingKey:userKey];
        }
        if ([element isKindOfClass:[MPElementGeneratedEntity class]] && counter != NSNotFound)
            ((MPElementGeneratedEntity *)element).counter = counter;

        dbg( @"Created Element: %@", [element debugDescription] );
    }

    if (![context saveToStore])
        return MPImportResultInternalError;

    inf( @"Import completed successfully." );
    MPCheckpoint( MPCheckpointSitesImported, nil );

    [[NSNotificationCenter defaultCenter] postNotificationName:MPSitesImportedNotification object:nil userInfo:@{
            MPSitesImportedNotificationUserKey : user
    }];

    return MPImportResultSuccess;
}

- (NSString *)exportSitesRevealPasswords:(BOOL)revealPasswords {

    MPUserEntity *activeUser = [self activeUserForMainThread];
    inf( @"Exporting sites, %@, for: %@", revealPasswords? @"revealing passwords": @"omitting passwords", activeUser.userID );

    // Header.
    NSMutableString *export = [NSMutableString new];
    [export appendFormat:@"# Master Password site export\n"];
    if (revealPasswords)
        [export appendFormat:@"#     Export of site names and passwords in clear-text.\n"];
    else
        [export appendFormat:@"#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n"];
    [export appendFormat:@"# \n"];
    [export appendFormat:@"##\n"];
    [export appendFormat:@"# User Name: %@\n", activeUser.name];
    [export appendFormat:@"# Avatar: %lu\n", (unsigned long)activeUser.avatar];
    [export appendFormat:@"# Key ID: %@\n", [activeUser.keyID encodeHex]];
    [export appendFormat:@"# Date: %@\n", [[NSDateFormatter rfc3339DateFormatter] stringFromDate:[NSDate date]]];
    [export appendFormat:@"# Version: %@\n", [PearlInfoPlist get].CFBundleVersion];
    [export appendFormat:@"# Format: 1\n"];
    if (revealPasswords)
        [export appendFormat:@"# Passwords: VISIBLE\n"];
    else
        [export appendFormat:@"# Passwords: PROTECTED\n"];
    [export appendFormat:@"##\n"];
    [export appendFormat:@"#\n"];
    [export appendFormat:@"#               Last     Times  Password                      Login\t                     Site\tSite\n"];
    [export appendFormat:@"#               used      used      type                       name\t                     name\tpassword\n"];

    // Sites.
    for (MPElementEntity *element in activeUser.elements) {
        NSDate *lastUsed = element.lastUsed;
        NSUInteger uses = element.uses;
        MPElementType type = element.type;
        NSUInteger version = element.version;
        NSUInteger counter = 0;
        NSString *loginName = element.loginName;
        NSString *siteName = element.name;
        NSString *content = nil;

        // Generated-specific
        if ([element isKindOfClass:[MPElementGeneratedEntity class]])
            counter = ((MPElementGeneratedEntity *)element).counter;


        // Determine the content to export.
        if (!(type & MPElementFeatureDevicePrivate)) {
            if (revealPasswords)
                content = [element.algorithm resolveContentForElement:element usingKey:self.key];
            else if (type & MPElementFeatureExportContent)
                content = [element.algorithm exportContentForElement:element usingKey:self.key];
        }

        [export appendFormat:@"%@  %8ld  %8s  %25s\t%25s\t%@\n",
                             [[NSDateFormatter rfc3339DateFormatter] stringFromDate:lastUsed], (long)uses,
                             [strf( @"%lu:%lu:%lu", (long)type, (long)version, (long)counter ) UTF8String],
                             [(loginName?: @"") UTF8String], [siteName UTF8String], content?: @""];
    }

    MPCheckpoint( MPCheckpointSitesExported, @{
            @"showPasswords" : @(revealPasswords)
    } );

    return export;
}

@end
