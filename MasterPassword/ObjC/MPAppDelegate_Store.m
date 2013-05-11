//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <objc/runtime.h>
#import "MPAppDelegate_Store.h"

#if TARGET_OS_IPHONE
#define STORE_OPTIONS NSPersistentStoreFileProtectionKey : NSFileProtectionComplete,
#else
#define STORE_OPTIONS
#endif

#define MPCloudContainerIdentifier @"HL3Q45LX9N.com.lyndir.lhunath.MasterPassword.shared"
#define MPMigrationLevelLocalStoreKey @"MPMigrationLevelLocalStoreKey"
#define MPMigrationLevelCloudStoreKey @"MPMigrationLevelCloudStoreKey"

typedef NS_ENUM(NSInteger, MPMigrationLevelLocalStore) {
    MPMigrationLevelLocalStoreV1,
    MPMigrationLevelLocalStoreV2,
    MPMigrationLevelLocalStoreCurrent = MPMigrationLevelLocalStoreV2,
};

typedef NS_ENUM(NSInteger, MPMigrationLevelCloudStore) {
    MPMigrationLevelCloudStoreV1,
    MPMigrationLevelCloudStoreV2,
    MPMigrationLevelCloudStoreV3,
    MPMigrationLevelCloudStoreCurrent = MPMigrationLevelCloudStoreV3,
};

@implementation MPAppDelegate_Shared(Store)
        PearlAssociatedObjectProperty(NSManagedObjectContext*, PrivateManagedObjectContext, privateManagedObjectContext);
PearlAssociatedObjectProperty(NSManagedObjectContext*, MainManagedObjectContext, mainManagedObjectContext);


#pragma mark - Core Data setup

+ (NSManagedObjectContext *)managedObjectContextForThreadIfReady {

    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext)
        return nil;
    if ([[NSThread currentThread] isMainThread])
        return mainManagedObjectContext;

    NSManagedObjectContext
            *threadManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    threadManagedObjectContext.parentContext = mainManagedObjectContext;

    return threadManagedObjectContext;
}

+ (BOOL)managedObjectContextPerformBlock:(void (^)(NSManagedObjectContext *))mocBlock {

    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext)
        return NO;

    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    moc.parentContext = mainManagedObjectContext;
    [moc performBlock:^{
        mocBlock( moc );
    }];

    return YES;
}

+ (BOOL)managedObjectContextPerformBlockAndWait:(void (^)(NSManagedObjectContext *))mocBlock {

    NSManagedObjectContext *mainManagedObjectContext = [[self get] mainManagedObjectContextIfReady];
    if (!mainManagedObjectContext)
        return NO;

    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    moc.parentContext = mainManagedObjectContext;
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
                                         additionalStoreOptions:@{ STORE_OPTIONS }
                                                       delegate:self];

#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:[UIApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[self mainManagedObjectContext] saveToStore];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:[UIApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[self mainManagedObjectContext] saveToStore];
                                                  }];
#else
    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification
                                                      object:[NSApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      NSManagedObjectContext *moc = self.mainManagedObjectContextIfReady;
                                                      [moc performBlockAndWait:^{
                                                          [moc saveToStore];
                                                      }];
                                                  }];
#endif

    return storeManager;
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

    inf(@"Local store migration level: %d (current %d)", (signed)migrationLevel, (signed)MPMigrationLevelLocalStoreCurrent);
    if (migrationLevel <= MPMigrationLevelLocalStoreV1)
        [self migrateV1LocalStore];

    [[NSUserDefaults standardUserDefaults] setInteger:MPMigrationLevelLocalStoreCurrent forKey:MPMigrationLevelLocalStoreKey];
    inf(@"Successfully migrated old to new local store.");
}

- (void)migrateCloudStore {

    MPMigrationLevelCloudStore migrationLevel = (signed)[[NSUserDefaults standardUserDefaults] integerForKey:MPMigrationLevelCloudStoreKey];
    if (migrationLevel >= MPMigrationLevelCloudStoreCurrent)
            // Cloud store up-to-date.
        return;

    inf(@"Cloud store migration level: %d (current %d)", (signed)migrationLevel, (signed)MPMigrationLevelCloudStoreCurrent);
    if (migrationLevel <= MPMigrationLevelCloudStoreV1)
        [self migrateV1CloudStore];
    else if (migrationLevel <= MPMigrationLevelCloudStoreV2)
        [self migrateV2CloudStore];

    [[NSUserDefaults standardUserDefaults] setInteger:MPMigrationLevelCloudStoreCurrent forKey:MPMigrationLevelCloudStoreKey];
}

- (void)migrateV1CloudStore {

    // Migrate cloud enabled preference.
    NSNumber *oldCloudEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"iCloudEnabledKey"];
    if ([oldCloudEnabled boolValue])
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USMCloudEnabledKey];

    // Migrate cloud store.
    NSString *uuid = [[NSUserDefaults standardUserDefaults] stringForKey:@"LocalUUIDKey"];
    if (!uuid) {
        inf(@"No V1 cloud store to migrate.");
        return;
    }

    inf(@"Migrating V1 cloud store: %@ -> %@", uuid, [self.storeManager valueForKey:@"storeUUID"]);
    NSURL *cloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:MPCloudContainerIdentifier];
    NSURL *oldCloudContentURL = [[cloudContainerURL
            URLByAppendingPathComponent:@"Data" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:YES];
    NSURL *oldCloudStoreURL = [[[cloudContainerURL
            URLByAppendingPathComponent:@"Database.nosync" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];

    [self migrateFromCloudStore:oldCloudStoreURL cloudContent:oldCloudContentURL contentName:uuid];
}

- (void)migrateV2CloudStore {

    // Migrate cloud store.
    NSString *uuid = [[NSUbiquitousKeyValueStore defaultStore] stringForKey:@"USMStoreUUIDKey"];
    if (!uuid) {
        inf(@"No V2 cloud store to migrate.");
        return;
    }

    inf(@"Migrating V2 cloud store: %@ -> %@", uuid, [self.storeManager valueForKey:@"storeUUID"]);
    NSURL *cloudContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:MPCloudContainerIdentifier];
    NSURL *oldCloudContentURL = [[cloudContainerURL
            URLByAppendingPathComponent:@"CloudLogs" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:YES];
    NSURL *oldCloudStoreURL = [[[cloudContainerURL
            URLByAppendingPathComponent:@"CloudStore.nosync" isDirectory:YES]
            URLByAppendingPathComponent:uuid isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];

    [self migrateFromCloudStore:oldCloudStoreURL cloudContent:oldCloudContentURL contentName:uuid];
}

- (void)migrateV1LocalStore {

    NSURL *applicationFilesDirectory = [[[NSFileManager defaultManager]
            URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *oldLocalStoreURL = [[applicationFilesDirectory
            URLByAppendingPathComponent:@"MasterPassword" isDirectory:NO] URLByAppendingPathExtension:@"sqlite"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:oldLocalStoreURL.path isDirectory:NO]) {
        inf(@"No V1 local store to migrate.");
        return;
    }

    inf(@"Migrating V1 local store");
    [self migrateFromLocalStore:oldLocalStoreURL];
}

- (void)migrateFromLocalStore:(NSURL *)oldLocalStoreURL {

    NSURL *newLocalStoreURL = [self.storeManager URLForLocalStore];
    if ([[NSFileManager defaultManager] fileExistsAtPath:newLocalStoreURL.path isDirectory:NO]) {
        wrn(@"Can't migrate local store: A new local store already exists.");
        return;
    }

    NSError *error = nil;
    NSDictionary *oldLocalStoreOptions = @{
            STORE_OPTIONS
            NSReadOnlyPersistentStoreOption        : @YES,
            NSInferMappingModelAutomaticallyOption : @YES
    };
    NSDictionary *newLocalStoreOptions = @{
            STORE_OPTIONS
            NSMigratePersistentStoresAutomaticallyOption : @YES,
            NSInferMappingModelAutomaticallyOption       : @YES
    };

    // Create the directory to hold the new local store.
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[self.storeManager URLForLocalStoreDirectory].path
                                   withIntermediateDirectories:YES attributes:nil error:&error])
    err(@"While creating directory for new local store: %@", error);

    if (![self.storeManager copyMigrateStore:oldLocalStoreURL withOptions:oldLocalStoreOptions
                                     toStore:newLocalStoreURL withOptions:newLocalStoreOptions
                                       error:nil cause:nil context:nil])
        return;

    inf(@"Successfully migrated to new local store.");
}

- (void)migrateFromCloudStore:(NSURL *)oldCloudStoreURL cloudContent:(NSURL *)oldCloudContentURL contentName:(NSString *)contentName {

    if (![self.storeManager cloudSafeForSeeding]) {
        inf(@"Can't migrate cloud store: A new cloud store already exists.");
        return;
    }

    NSURL *newCloudStoreURL = [self.storeManager URLForCloudStore];
    NSURL *newCloudContentURL = [self.storeManager URLForCloudContent];

    NSError *error = nil;
    NSDictionary *oldCloudStoreOptions = @{
            STORE_OPTIONS
            NSPersistentStoreUbiquitousContentNameKey : contentName,
            NSPersistentStoreUbiquitousContentURLKey  : oldCloudContentURL,
            NSInferMappingModelAutomaticallyOption    : @YES
    };
    NSDictionary *newCloudStoreOptions = @{
            STORE_OPTIONS
            NSPersistentStoreUbiquitousContentNameKey    : [self.storeManager valueForKey:@"contentName"],
            NSPersistentStoreUbiquitousContentURLKey     : newCloudContentURL,
            NSMigratePersistentStoresAutomaticallyOption : @YES,
            NSInferMappingModelAutomaticallyOption       : @YES
    };

    // Create the directory to hold the new cloud store.
    // This is only necessary if we want to try to rebuild the old store.  See comment above about how that failed.
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[oldCloudStoreURL URLByDeletingLastPathComponent].path
                                   withIntermediateDirectories:YES attributes:nil error:&error])
    err(@"While creating directory for old cloud store: %@", error);
    if (![[NSFileManager defaultManager] createDirectoryAtPath:oldCloudContentURL.path
                                   withIntermediateDirectories:YES attributes:nil error:&error])
    err(@"While creating directory for old cloud content: %@", error);
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[self.storeManager URLForCloudStoreDirectory].path
                                   withIntermediateDirectories:YES attributes:nil error:&error])
    err(@"While creating directory for new cloud store: %@", error);
    if (![[NSFileManager defaultManager] createDirectoryAtPath:[self.storeManager URLForCloudContent].path
                                   withIntermediateDirectories:YES attributes:nil error:&error])
    err(@"While creating directory for new cloud content: %@", error);

    if (![self.storeManager copyMigrateStore:oldCloudStoreURL withOptions:oldCloudStoreOptions
                                     toStore:newCloudStoreURL withOptions:newCloudStoreOptions
                                       error:nil cause:nil context:nil])
        return;

    inf(@"Successfully migrated to new cloud store.");
}

#pragma mark - UbiquityStoreManagerDelegate

- (NSManagedObjectContext *)managedObjectContextForUbiquityStoreManager:(UbiquityStoreManager *)usm {

    return [self privateManagedObjectContextIfReady];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager log:(NSString *)message {

    dbg(@"[StoreManager] %@", message);
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager willLoadStoreIsCloud:(BOOL)isCloudStore {

    NSManagedObjectContext *moc = self.mainManagedObjectContextIfReady;
    [moc performBlockAndWait:^{
        [moc saveToStore];

        self.privateManagedObjectContext = nil;
        self.mainManagedObjectContext = nil;
    }];

    [self migrateStoreForManager:manager isCloud:isCloudStore];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didLoadStoreForCoordinator:(NSPersistentStoreCoordinator *)coordinator
                     isCloud:(BOOL)isCloudStore {

    inf(@"Using iCloud? %@", @(isCloudStore));
    MPCheckpoint( MPCheckpointCloud, @{
            @"enabled" : @(isCloudStore)
    } );

    // Create our contexts.
    NSManagedObjectContext
            *privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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

    self.privateManagedObjectContext = privateManagedObjectContext;
    self.mainManagedObjectContext = mainManagedObjectContext;
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didEncounterError:(NSError *)error cause:(UbiquityStoreErrorCause)cause
                     context:(id)context {

    err(@"[StoreManager] ERROR: cause=%d, context=%@, error=%@", cause, context, error);
    MPCheckpoint( MPCheckpointMPErrorUbiquity, @{
            @"cause"        : @(cause),
            @"error.domain" : error.domain,
            @"error.code"   : @(error.code)
    } );
}

#pragma mark - Utilities

- (void)addElementNamed:(NSString *)siteName completion:(void (^)(MPElementEntity *element))completion {

    if (![siteName length]) {
        completion( nil );
        return;
    }

    [MPAppDelegate_Shared managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        MPUserEntity *activeUser = [self activeUserInContext:moc];
        assert(activeUser);

        MPElementType type = activeUser.defaultType;
        if (!type)
            type = activeUser.defaultType = MPElementTypeGeneratedLong;
        NSString *typeEntityClassName = [MPAlgorithmDefault classNameOfType:type];

        MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:typeEntityClassName
                                                                 inManagedObjectContext:moc];

        element.name = siteName;
        element.user = activeUser;
        element.type = type;
        element.lastUsed = [NSDate date];
        element.version = MPAlgorithmDefaultVersion;
        [moc saveToStore];

        NSError *error = nil;
        if (element.objectID.isTemporaryID && ![moc obtainPermanentIDsForObjects:@[ element ] error:&error])
        err(@"Failed to obtain a permanent object ID after creating new element: %@", error);

        NSManagedObjectID *elementOID = [element objectID];
        dispatch_async( dispatch_get_main_queue(), ^{
            completion( (MPElementEntity *)[[MPAppDelegate_Shared managedObjectContextForThreadIfReady] objectRegisteredForID:elementOID] );
        } );
    }];
}

- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *(^)(NSString *userName))importPassword
              askUserPassword:(NSString *(^)(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword {

    // Compile patterns.
    static NSRegularExpression *headerPattern, *sitePattern;
    NSError *error = nil;
    if (!headerPattern) {
        headerPattern = [[NSRegularExpression alloc]
                initWithPattern:@"^#[[:space:]]*([^:]+): (.*)"
                        options:(NSRegularExpressionOptions)0 error:&error];
        if (error) {
            err(@"Error loading the header pattern: %@", error);
            return MPImportResultInternalError;
        }
    }
    if (!sitePattern) {
        sitePattern = [[NSRegularExpression alloc]
                initWithPattern:@"^([^[:space:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+([[:digit:]]+)(:[[:digit:]]+)?[[:space:]]+([^\t]+)\t(.*)"
                        options:(NSRegularExpressionOptions)0 error:&error];
        if (error) {
            err(@"Error loading the site pattern: %@", error);
            return MPImportResultInternalError;
        }
    }

    // Get a MOC.
    NSAssert(![[NSThread currentThread] isMainThread], @"This method should not be invoked from the main thread.");
    NSManagedObjectContext *moc;
    while (!(moc = [MPAppDelegate_Shared managedObjectContextForThreadIfReady]))
        usleep( (useconds_t)(USEC_PER_SEC * 0.2) );

    // Parse import data.
    inf(@"Importing sites.");
    __block MPUserEntity *user = nil;
    id<MPAlgorithm> importAlgorithm = nil;
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
                err(@"Invalid header format in line: %@", importedSiteLine);
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
                NSArray *users = [moc executeFetchRequest:userFetchRequest error:&error];
                if (!users) {
                    err(@"While looking for user: %@, error: %@", importUserName, error);
                    return MPImportResultInternalError;
                }
                if ([users count] > 1) {
                    err(@"While looking for user: %@, found more than one: %lu", importUserName, (unsigned long)[users count]);
                    return MPImportResultInternalError;
                }

                user = [users count]? [users lastObject]: nil;
                dbg(@"Found user: %@", [user debugDescription]);
            }
            if ([headerName isEqualToString:@"Key ID"])
                importKeyID = [headerValue decodeHex];
            if ([headerName isEqualToString:@"Version"]) {
                importBundleVersion = headerValue;
                importAlgorithm = MPAlgorithmDefaultForBundleVersion( importBundleVersion );
            }
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
        if ([sitePattern numberOfMatchesInString:importedSiteLine options:(NSMatchingOptions)0
                                           range:NSMakeRange( 0, [importedSiteLine length] )] != 1) {
            err(@"Invalid site format in line: %@", importedSiteLine);
            return MPImportResultMalformedInput;
        }
        NSTextCheckingResult *siteElements = [[sitePattern matchesInString:importedSiteLine options:(NSMatchingOptions)0
                                                                     range:NSMakeRange( 0, [importedSiteLine length] )] lastObject];
        NSString *lastUsed = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
        NSString *uses = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
        NSString *type = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
        NSString *version = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
        if ([version length])
            version = [version substringFromIndex:1]; // Strip the leading colon.
        NSString *name = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
        NSString *exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:6]];

        // Find existing site.
        if (user) {
            elementFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND user == %@", name, user];
            NSArray *existingSites = [moc executeFetchRequest:elementFetchRequest error:&error];
            if (!existingSites) {
                err(@"Lookup of existing sites failed for site: %@, user: %@, error: %@", name, user.userID, error);
                return MPImportResultInternalError;
            }
            else if (existingSites.count)
            dbg(@"Existing sites: %@", existingSites);

            [elementsToDelete addObjectsFromArray:existingSites];
            [importedSiteElements addObject:@[ lastUsed, uses, type, version, name, exportContent ]];
            dbg(@"Will import site: lastUsed=%@, uses=%@, type=%@, version=%@, name=%@, exportContent=%@",
            lastUsed, uses, type, version, name, exportContent);
        }
    }

    // Ask for confirmation to import these sites and the master password of the user.
    inf(@"Importing %lu sites, deleting %lu sites, for user: %@", (unsigned long)[importedSiteElements count], (unsigned long)[elementsToDelete count], [MPUserEntity idFor:importUserName]);
    NSString *userMasterPassword = userPassword( user.name, [importedSiteElements count], [elementsToDelete count] );
    if (!userMasterPassword) {
        inf(@"Import cancelled.");
        return MPImportResultCancelled;
    }
    MPKey *userKey = [MPAlgorithmDefault keyForPassword:userMasterPassword ofUserNamed:user.name];
    if (![userKey.keyID isEqualToData:user.keyID])
        return MPImportResultInvalidPassword;
    __block MPKey *importKey = userKey;
    if ([importKey.keyID isEqualToData:importKeyID])
        importKey = nil;

    // Delete existing sites.
    if (elementsToDelete.count)
        [elementsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            inf(@"Deleting site: %@, it will be replaced by an imported site.", [obj name]);
            [moc deleteObject:obj];
        }];

    // Make sure there is a user.
    if (!user) {
        user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass( [MPUserEntity class] )
                                             inManagedObjectContext:moc];
        user.name = importUserName;
        user.keyID = importKeyID;
        dbg(@"Created User: %@", [user debugDescription]);
    }

    // Import new sites.
    for (NSArray *siteElements in importedSiteElements) {
        NSDate *lastUsed = [[NSDateFormatter rfc3339DateFormatter] dateFromString:[siteElements objectAtIndex:0]];
        NSUInteger uses = (unsigned)[[siteElements objectAtIndex:1] integerValue];
        MPElementType type = (MPElementType)[[siteElements objectAtIndex:2] integerValue];
        NSUInteger version = (unsigned)[[siteElements objectAtIndex:3] integerValue];
        NSString *name = [siteElements objectAtIndex:4];
        NSString *exportContent = [siteElements objectAtIndex:5];

        // Create new site.
        MPElementEntity
                *element = [NSEntityDescription insertNewObjectForEntityForName:[MPAlgorithmForVersion( version ) classNameOfType:type]
                                                         inManagedObjectContext:moc];
        element.name = name;
        element.user = user;
        element.type = type;
        element.uses = uses;
        element.lastUsed = lastUsed;
        element.version = version;
        if ([exportContent length]) {
            if (clearText)
                [element importClearTextContent:exportContent usingKey:userKey];
            else {
                if (!importKey)
                    importKey = [importAlgorithm keyForPassword:importPassword( user.name ) ofUserNamed:user.name];
                if (![importKey.keyID isEqualToData:importKeyID])
                    return MPImportResultInvalidPassword;

                [element importProtectedContent:exportContent protectedByKey:importKey usingKey:userKey];
            }
        }

        dbg(@"Created Element: %@", [element debugDescription]);
    }

    if (![moc save:&error]) {
        err(@"While saving imported sites: %@", error);
        return MPImportResultInternalError;
    }

    inf(@"Import completed successfully.");
    MPCheckpoint( MPCheckpointSitesImported, nil );

    return MPImportResultSuccess;
}

- (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords {

    MPUserEntity *activeUser = [self activeUserForThread];
    inf(@"Exporting sites, %@, for: %@", showPasswords? @"showing passwords": @"omitting passwords", activeUser.userID);

    // Header.
    NSMutableString *export = [NSMutableString new];
    [export appendFormat:@"# Master Password site export\n"];
    if (showPasswords)
        [export appendFormat:@"#     Export of site names and passwords in clear-text.\n"];
    else
        [export appendFormat:@"#     Export of site names and stored passwords (unless device-private) encrypted with the master key.\n"];
    [export appendFormat:@"# \n"];
    [export appendFormat:@"##\n"];
    [export appendFormat:@"# Version: %@\n", [PearlInfoPlist get].CFBundleVersion];
    [export appendFormat:@"# User Name: %@\n", activeUser.name];
    [export appendFormat:@"# Key ID: %@\n", [activeUser.keyID encodeHex]];
    [export appendFormat:@"# Date: %@\n", [[NSDateFormatter rfc3339DateFormatter] stringFromDate:[NSDate date]]];
    if (showPasswords)
        [export appendFormat:@"# Passwords: VISIBLE\n"];
    else
        [export appendFormat:@"# Passwords: PROTECTED\n"];
    [export appendFormat:@"##\n"];
    [export appendFormat:@"#\n"];
    [export appendFormat:@"#               Last     Times  Password                  Site\tSite\n"];
    [export appendFormat:@"#               used      used      type                  name\tpassword\n"];

    // Sites.
    for (MPElementEntity *element in activeUser.elements) {
        NSDate *lastUsed = element.lastUsed;
        NSUInteger uses = element.uses;
        MPElementType type = element.type;
        NSUInteger version = element.version;
        NSString *name = element.name;
        NSString *content = nil;

        // Determine the content to export.
        if (!(type & MPElementFeatureDevicePrivate)) {
            if (showPasswords)
                content = element.content;
            else if (type & MPElementFeatureExportContent)
                content = element.exportContent;
        }

        [export appendFormat:@"%@  %8ld  %8s  %20s\t%@\n",
                             [[NSDateFormatter rfc3339DateFormatter] stringFromDate:lastUsed], (long)uses,
                             [PearlString( @"%u:%lu", type, (unsigned long)version ) UTF8String], [name UTF8String], content
                                                                                                                     ? content: @""];
    }

    MPCheckpoint( MPCheckpointSitesExported, @{
            @"showPasswords" : @(showPasswords)
    } );

    return export;
}

@end
