//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Store.h"
#import "LocalyticsSession.h"

@implementation MPAppDelegate_Shared (Store)

#pragma mark - Core Data setup

+ (NSManagedObjectContext *)managedObjectContextIfReady {

    return [[self get] managedObjectContextIfReady];
}

+ (NSManagedObjectModel *)managedObjectModel {

    return [[self get] managedObjectModel];
}

- (NSManagedObjectModel *)managedObjectModel {

    static NSManagedObjectModel *managedObjectModel = nil;
    if (managedObjectModel)
        return managedObjectModel;

    return managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
}

- (NSManagedObjectContext *)managedObjectContextIfReady {

    if (![self storeManager].isReady)
        return nil;

    static NSManagedObjectContext *managedObjectContext = nil;
    if (!managedObjectContext) {
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext performBlockAndWait:^{
            managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            managedObjectContext.undoManager = [NSUndoManager new];
        }];
    }

    if (![managedObjectContext.persistentStoreCoordinator.persistentStores count])
        [managedObjectContext performBlockAndWait:^{
            managedObjectContext.persistentStoreCoordinator = [self storeManager].persistentStoreCoordinator;
        }];

    if (![self storeManager].isReady)
        return nil;

    return managedObjectContext;
}

- (UbiquityStoreManager *)storeManager {

    static UbiquityStoreManager *storeManager = nil;
    if (storeManager)
        return storeManager;

    storeManager = [[UbiquityStoreManager alloc] initWithManagedObjectModel:[self managedObjectModel]
                                                              localStoreURL:[[self applicationFilesDirectory] URLByAppendingPathComponent:@"MasterPassword.sqlite"]
                                                        containerIdentifier:@"HL3Q45LX9N.com.lyndir.lhunath.MasterPassword.shared"
#if TARGET_OS_IPHONE
                                                     additionalStoreOptions:@{
                                                     NSPersistentStoreFileProtectionKey: NSFileProtectionComplete
                                                     }
#else
                                                     additionalStoreOptions:nil
#endif
    ];
    storeManager.delegate = self;
#ifdef DEBUG
    storeManager.hardResetEnabled = YES;
#endif
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:[UIApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [storeManager checkiCloudStatus];
                                                  }];
#else
    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillBecomeActiveNotification
                                                      object:[NSApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [storeManager checkiCloudStatus];
                                                  }];
#endif
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:[UIApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self saveContext];
                                                  }];
#else
    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification
                                                      object:[NSApplication sharedApplication] queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self saveContext];
                                                  }];
#endif

    return storeManager;
}

- (void)saveContext {

    [self.managedObjectContextIfReady performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContextIfReady hasChanges])
            if (![self.managedObjectContextIfReady save:&error])
            err(@"While saving context: %@", error);
    }];
}

#pragma mark - UbiquityStoreManagerDelegate

- (NSManagedObjectContext *)managedObjectContextForUbiquityStoreManager:(UbiquityStoreManager *)usm {

    return self.managedObjectContextIfReady;
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager log:(NSString *)message {

    dbg(@"[StoreManager] %@", message);
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didSwitchToiCloud:(BOOL)iCloudEnabled {

    // manager.iCloudEnabled is more reliable (eg. iOS' MPAppDelegate tampers with didSwitch a bit)
    iCloudEnabled = manager.iCloudEnabled;
    inf(@"Using iCloud? %@", iCloudEnabled? @"YES": @"NO");

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:iCloudEnabled? MPCheckpointCloudEnabled: MPCheckpointCloudDisabled];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCloud attributes:@{
    @"enabled": iCloudEnabled? @"YES": @"NO"
    }];

    [MPConfig get].iCloud = @(iCloudEnabled);
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didEncounterError:(NSError *)error cause:(UbiquityStoreManagerErrorCause)cause
                     context:(id)context {

    err(@"StoreManager: cause=%d, context=%@, error=%@", cause, context, error);

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:PearlString(@"MPCheckpointMPErrorUbiquity_%d", cause)];
#endif

    switch (cause) {
        case UbiquityStoreManagerErrorCauseDeleteStore:
        case UbiquityStoreManagerErrorCauseDeleteLogs:
        case UbiquityStoreManagerErrorCauseCreateStorePath:
        case UbiquityStoreManagerErrorCauseClearStore:
            break;
        case UbiquityStoreManagerErrorCauseOpenLocalStore: {
            wrn(@"Local store could not be opened: %@", error);

            if (error.code == NSMigrationMissingSourceModelError) {
                wrn(@"Resetting the local store.");

#ifdef TESTFLIGHT_SDK_VERSION
                [TestFlight passCheckpoint:MPCheckpointLocalStoreIncompatible];
#endif
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointLocalStoreIncompatible attributes:nil];
                manager.hardResetEnabled = YES;
                [manager hardResetLocalStorage];

                Throw(@"Local store was reset, application must be restarted to use it.");
            } else
                // Try again.
                [[self storeManager] persistentStoreCoordinator];
        }
        case UbiquityStoreManagerErrorCauseOpenCloudStore: {
            wrn(@"iCloud store could not be opened: %@", error);

            if (error.code == NSMigrationMissingSourceModelError) {
                wrn(@"Resetting the iCloud store.");

#ifdef TESTFLIGHT_SDK_VERSION
                [TestFlight passCheckpoint:MPCheckpointCloudStoreIncompatible];
#endif
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCloudStoreIncompatible attributes:nil];
                manager.hardResetEnabled = YES;
                [manager hardResetCloudStorage];
                break;
            } else
                // Try again.
                [[self storeManager] persistentStoreCoordinator];
        }
    }
}

#pragma mark - Import / Export

- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *(^)(NSString *userName))importPassword
              askUserPassword:(NSString *(^)(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword {

    while (![self managedObjectContextIfReady])
        usleep((useconds_t)(USEC_PER_SEC * 0.2));

    inf(@"Importing sites.");

    static NSRegularExpression *headerPattern, *sitePattern;
    __block NSError *error = nil;
    if (!headerPattern) {
        headerPattern = [[NSRegularExpression alloc] initWithPattern:@"^#[[:space:]]*([^:]+): (.*)"
                                                             options:0 error:&error];
        if (error)
        err(@"Error loading the header pattern: %@", error);
    }
    if (!sitePattern) {
        sitePattern = [[NSRegularExpression alloc] initWithPattern:@"^([^[:space:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+([[:digit:]]+)(:[[:digit:]]+)?[[:space:]]+([^\t]+)\t(.*)"
                                                           options:0 error:&error];
        if (error)
        err(@"Error loading the site pattern: %@", error);
    }
    if (!headerPattern || !sitePattern)
        return MPImportResultInternalError;

    __block MPUserEntity *user = nil;
    id<MPAlgorithm> importAlgorithm = nil;
    NSString *importBundleVersion = nil, *importUserName = nil;
    NSData *importKeyID = nil;
    BOOL headerStarted = NO, headerEnded = NO, clearText = NO;
    NSArray        *importedSiteLines    = [importedSitesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableSet   *elementsToDelete     = [NSMutableSet set];
    NSMutableArray *importedSiteElements = [NSMutableArray arrayWithCapacity:[importedSiteLines count]];
    NSFetchRequest *elementFetchRequest  = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
    for (NSString  *importedSiteLine in importedSiteLines) {
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
            if ([headerPattern numberOfMatchesInString:importedSiteLine options:0 range:NSMakeRange(0, [importedSiteLine length])] != 1) {
                err(@"Invalid header format in line: %@", importedSiteLine);
                return MPImportResultMalformedInput;
            }
            NSTextCheckingResult *headerElements = [[headerPattern matchesInString:importedSiteLine options:0
                                                                             range:NSMakeRange(0, [importedSiteLine length])] lastObject];
            NSString             *headerName     = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:1]];
            NSString             *headerValue    = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:2]];
            if ([headerName isEqualToString:@"User Name"]) {
                importUserName = headerValue;

                NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPUserEntity class])];
                userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@", importUserName];
                __block NSArray *users = nil;
                [self.managedObjectContextIfReady performBlockAndWait:^{
                    users = [self.managedObjectContextIfReady executeFetchRequest:userFetchRequest error:&error];
                }];
                if (!users) {
                    err(@"While looking for user: %@, error: %@", importUserName, error);
                    return MPImportResultInternalError;
                }
                if ([users count] > 1) {
                    err(@"While looking for user: %@, found more than one: %u", importUserName, [users count]);
                    return MPImportResultInternalError;
                }

                user = [users count]? [users lastObject]: nil;
                dbg(@"Found user: %@", [user debugDescription]);
            }
            if ([headerName isEqualToString:@"Key ID"])
                importKeyID                      = [headerValue decodeHex];
            if ([headerName isEqualToString:@"Version"]) {
                importBundleVersion = headerValue;
                importAlgorithm     = MPAlgorithmDefaultForBundleVersion(importBundleVersion);
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
        if ([sitePattern numberOfMatchesInString:importedSiteLine options:0 range:NSMakeRange(0, [importedSiteLine length])] != 1) {
            err(@"Invalid site format in line: %@", importedSiteLine);
            return MPImportResultMalformedInput;
        }
        NSTextCheckingResult *siteElements  = [[sitePattern matchesInString:importedSiteLine options:0
                                                                      range:NSMakeRange(0, [importedSiteLine length])] lastObject];
        NSString             *lastUsed      = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
        NSString             *uses          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
        NSString             *type          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
        NSString             *version       = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
        NSString             *name          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
        NSString             *exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:6]];

        // Find existing site.
        if (user) {
            elementFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND user == %@", name, user];
            __block NSArray *existingSites = nil;
            [self.managedObjectContextIfReady performBlockAndWait:^{
                existingSites = [self.managedObjectContextIfReady executeFetchRequest:elementFetchRequest error:&error];
            }];
            if (!existingSites) {
                err(@"Lookup of existing sites failed for site: %@, user: %@, error: %@", name, user.userID, error);
                return MPImportResultInternalError;
            } else
                if (existingSites.count)
                dbg(@"Existing sites: %@", existingSites);

            [elementsToDelete addObjectsFromArray:existingSites];
            [importedSiteElements addObject:@[lastUsed, uses, type, version, name, exportContent]];
        }
    }

    // Ask for confirmation to import these sites and the master password of the user.
    inf(@"Importing %u sites, deleting %u sites, for user: %@", [importedSiteElements count], [elementsToDelete count], [MPUserEntity idFor:importUserName]);
    NSString *userMasterPassword = userPassword(user.name, [importedSiteElements count], [elementsToDelete count]);
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

    BOOL success = NO;
    [self.managedObjectContextIfReady.undoManager beginUndoGrouping];
    @try {

        // Delete existing sites.
        if (elementsToDelete.count)
            [self.managedObjectContextIfReady performBlockAndWait:^{
                [elementsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                    inf(@"Deleting site: %@, it will be replaced by an imported site.", [obj name]);
                    dbg(@"Deleted Element: %@", [obj debugDescription]);
                    [self.managedObjectContextIfReady deleteObject:obj];
                }];
            }];

        // Make sure there is a user.
        if (!user) {
            [self.managedObjectContextIfReady performBlockAndWait:^{
                user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPUserEntity class])
                                                     inManagedObjectContext:self.managedObjectContextIfReady];
                user.name  = importUserName;
                user.keyID = importKeyID;
            }];
            dbg(@"Created User: %@", [user debugDescription]);
        }
        [self saveContext];

        // Import new sites.
        for (NSArray *siteElements in importedSiteElements) {
            NSDate *lastUsed = [[NSDateFormatter rfc3339DateFormatter] dateFromString:[siteElements objectAtIndex:0]];
            NSUInteger    uses    = (unsigned)[[siteElements objectAtIndex:1] integerValue];
            MPElementType type    = (MPElementType)[[siteElements objectAtIndex:2] integerValue];
            NSUInteger    version = (unsigned)[[siteElements objectAtIndex:3] integerValue];
            NSString *name          = [siteElements objectAtIndex:4];
            NSString *exportContent = [siteElements objectAtIndex:5];

            // Create new site.
            __block MPImportResult result = MPImportResultSuccess;
            [self.managedObjectContextIfReady performBlockAndWait:^{
                MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:[MPAlgorithmForVersion(
                 version) classNameOfType:type]
                                                                         inManagedObjectContext:self.managedObjectContextIfReady];
                element.name     = name;
                element.user     = user;
                element.type     = type;
                element.uses     = uses;
                element.lastUsed = lastUsed;
                element.version  = version;
                if ([exportContent length]) {
                    if (clearText)
                        [element importClearTextContent:exportContent usingKey:userKey];
                    else {
                        if (!importKey)
                            importKey = [importAlgorithm keyForPassword:importPassword(user.name) ofUserNamed:user.name];
                        if (![importKey.keyID isEqualToData:importKeyID]) {
                            result = MPImportResultInvalidPassword;
                            return;
                        }

                        [element importProtectedContent:exportContent protectedByKey:importKey usingKey:userKey];
                    }
                }

                dbg(@"Created Element: %@", [element debugDescription]);
            }];
            if (result != MPImportResultSuccess)
                return result;
        }

        [self saveContext];
        success = YES;
        inf(@"Import completed successfully.");
#ifdef TESTFLIGHT_SDK_VERSION
        [TestFlight passCheckpoint:MPCheckpointSitesImported];
#endif
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointSitesImported attributes:nil];

        return MPImportResultSuccess;
    }
    @finally {
        [self.managedObjectContextIfReady.undoManager endUndoGrouping];

        if (!success)
            [self.managedObjectContextIfReady.undoManager undoNestedGroup];
    }
}

- (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords {

    inf(@"Exporting sites, %@, for: %@", showPasswords? @"showing passwords": @"omitting passwords", self.activeUser.userID);

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
    [export appendFormat:@"# User Name: %@\n", self.activeUser.name];
    [export appendFormat:@"# Key ID: %@\n", [self.activeUser.keyID encodeHex]];
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
    for (MPElementEntity *element in self.activeUser.elements) {
        NSDate *lastUsed = element.lastUsed;
        NSUInteger    uses    = element.uses;
        MPElementType type    = element.type;
        NSUInteger    version = element.version;
        NSString *name    = element.name;
        NSString *content = nil;

        // Determine the content to export.
        if (!(type & MPElementFeatureDevicePrivate)) {
            if (showPasswords)
                content = element.content;
            else
                if (type & MPElementFeatureExportContent)
                    content = element.exportContent;
        }

        [export appendFormat:@"%@  %8d  %8s  %20s\t%@\n",
                             [[NSDateFormatter rfc3339DateFormatter] stringFromDate:lastUsed], uses,
                             [PearlString(@"%u:%u", type, version) UTF8String], [name UTF8String], content
         ? content: @""];
    }

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPCheckpointSitesExported];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointSitesExported attributes:nil];

    return export;
}

@end
