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

+ (NSManagedObjectContext *)managedObjectContext {

    return [[self get] managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {

    return [[self get] managedObjectModel];
}

- (NSManagedObjectModel *)managedObjectModel {

    static NSManagedObjectModel *managedObjectModel = nil;
    if (managedObjectModel)
        return managedObjectModel;

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MasterPassword" withExtension:@"momd"];
    return managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObjectContext *)managedObjectContext {

    static NSManagedObjectContext *managedObjectContext = nil;
    if (managedObjectContext)
        return managedObjectContext;

    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [managedObjectContext performBlockAndWait:^{
        managedObjectContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
        managedObjectContext.mergePolicy                = NSMergeByPropertyObjectTrumpMergePolicy;
    }];

    return managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

    // Start loading the store.
    [self storeManager];

    // Wait until the storeManager is ready.
    while (![self storeManager].isReady)
        [NSThread sleepForTimeInterval:0.1];

    return [self storeManager].persistentStoreCoordinator;
}

- (UbiquityStoreManager *)storeManager {

    static UbiquityStoreManager *storeManager = nil;
    if (storeManager)
        return storeManager;

    storeManager = [[UbiquityStoreManager alloc] initWithManagedObjectModel:[self managedObjectModel]
                                          localStoreURL:[[self applicationFilesDirectory] URLByAppendingPathComponent:@"MasterPassword.sqlite"]
                                          containerIdentifier:@"HL3Q45LX9N.com.lyndir.lhunath.MasterPassword.shared"
#if TARGET_OS_IPHONE
                                       additionalStoreOptions:[NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                                                          forKey:NSPersistentStoreFileProtectionKey]
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

    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges])
            if (![self.managedObjectContext save:&error])
            err(@"While saving context: %@", error);
    }];
}

#pragma mark - UbiquityStoreManagerDelegate

- (NSManagedObjectContext *)managedObjectContextForUbiquityStoreManager:(UbiquityStoreManager *)usm {

    return self.managedObjectContext;
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
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCloud
                                               attributes:[NSDictionary dictionaryWithObject:iCloudEnabled? @"YES": @"NO" forKey:@"enabled"]];

    [MPConfig get].iCloud = [NSNumber numberWithBool:iCloudEnabled];
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
            wrn(@"Local store could not be opened, resetting it.");

#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPCheckpointLocalStoreIncompatible];
#endif
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointLocalStoreIncompatible
                                                       attributes:nil];
            manager.hardResetEnabled = YES;
            [manager hardResetLocalStorage];

            [NSException raise:NSGenericException format:@"Local store was reset, application must be restarted to use it."];
            return;
        }
        case UbiquityStoreManagerErrorCauseOpenCloudStore: {
            wrn(@"iCloud store could not be opened, resetting it.");

#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPCheckpointCloudStoreIncompatible];
#endif
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointCloudStoreIncompatible
                                                       attributes:nil];
            manager.hardResetEnabled = YES;
            [manager hardResetCloudStorage];
            break;
        }
    }
}

#pragma mark - Import / Export

- (MPImportResult)importSites:(NSString *)importedSitesString withPassword:(NSString *)password
              askConfirmation:(BOOL(^)(NSUInteger importCount, NSUInteger deleteCount))confirmation {

    inf(@"Importing sites.");

    static NSRegularExpression *headerPattern, *sitePattern;
    __autoreleasing NSError *error;
    if (!headerPattern) {
        headerPattern = [[NSRegularExpression alloc]
                                              initWithPattern:@"^#[[:space:]]*([^:]+): (.*)"
                                                      options:0 error:&error];
        if (error)
        err(@"Error loading the header pattern: %@", error);
    }
    if (!sitePattern) {
        sitePattern = [[NSRegularExpression alloc]
                                            initWithPattern:@"^([^[:space:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+([^\t]+)\t(.*)"
                                                    options:0 error:&error];
        if (error)
        err(@"Error loading the site pattern: %@", error);
    }
    if (!headerPattern || !sitePattern)
        return MPImportResultInternalError;

    NSString *keyIDHex = nil, *userName = nil;
    MPUserEntity *user = nil;
    BOOL headerStarted = NO, headerEnded = NO;
    NSArray        *importedSiteLines    = [importedSitesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableSet   *elementsToDelete     = [NSMutableSet set];
    NSMutableArray *importedSiteElements = [NSMutableArray arrayWithCapacity:[importedSiteLines count]];
    NSFetchRequest *fetchRequest         = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
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
            NSString             *key            = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:1]];
            NSString             *value          = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:2]];
            if ([key isEqualToString:@"User Name"]) {
                userName = value;

                NSFetchRequest *userFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPUserEntity class])];
                userFetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@", userName];
                user = [[self.managedObjectContext executeFetchRequest:fetchRequest error:&error] lastObject];
            }
            if ([key isEqualToString:@"Key ID"]) {
                if (![(keyIDHex = value) isEqualToString:[keyIDForPassword(password, userName) encodeHex]])
                    return MPImportResultInvalidPassword;
            }

            continue;
        }
        if (!headerEnded)
            continue;
        if (!keyIDHex || ![userName length])
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
        NSString             *name          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
        NSString             *exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];

        // Find existing site.
        if (user) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND user == %@", name, user];
            NSArray *existingSites = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (error)
            err(@"Couldn't search existing sites: %@", error);
            if (!existingSites) {
                err(@"Lookup of existing sites failed for site: %@, user: %@", name, user.userID);
                return MPImportResultInternalError;
            }

            [elementsToDelete addObjectsFromArray:existingSites];
            [importedSiteElements addObject:[NSArray arrayWithObjects:lastUsed, uses, type, name, exportContent, nil]];
        }
    }

    inf(@"Importing %u sites, deleting %u sites, for user: %@",
    [importedSiteElements count], [elementsToDelete count], [MPUserEntity idFor:userName]);

    // Ask for confirmation to import these sites.
    if (!confirmation([importedSiteElements count], [elementsToDelete count])) {
        inf(@"Import cancelled.");
        return MPImportResultCancelled;
    }

    // Delete existing sites.
    [elementsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        inf(@"Deleting site: %@, it will be replaced by an imported site.", [obj name]);
        [self.managedObjectContext deleteObject:obj];
    }];
    [self saveContext];

    // Import new sites.
    if (!user) {
        user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPUserEntity class])
                                    inManagedObjectContext:self.managedObjectContext];
        user.name  = userName;
        user.keyID = [keyIDHex decodeHex];
    }
    for (NSArray *siteElements in importedSiteElements) {
        NSDate *lastUsed = [[NSDateFormatter rfc3339DateFormatter] dateFromString:[siteElements objectAtIndex:0]];
        NSUInteger    uses = (unsigned)[[siteElements objectAtIndex:1] integerValue];
        MPElementType type = (MPElementType)[[siteElements objectAtIndex:2] integerValue];
        NSString *name          = [siteElements objectAtIndex:3];
        NSString *exportContent = [siteElements objectAtIndex:4];

        // Create new site.
        MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:ClassNameFromMPElementType(type)
                                                                 inManagedObjectContext:self.managedObjectContext];
        element.name     = name;
        element.user     = user;
        element.type     = type;
        element.uses     = uses;
        element.lastUsed = lastUsed;
        if ([exportContent length])
            [element importContent:exportContent];
    }
    [self saveContext];

    inf(@"Import completed successfully.");
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPCheckpointSitesImported];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointSitesImported
                                               attributes:nil];

    return MPImportResultSuccess;
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
        NSUInteger    uses = element.uses;
        MPElementType type = element.type;
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

        [export appendFormat:@"%@  %8d  %8d  %20s\t%@\n",
                             [[NSDateFormatter rfc3339DateFormatter] stringFromDate:lastUsed], uses, type, [name cStringUsingEncoding:NSUTF8StringEncoding], content
         ? content: @""];
    }

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPCheckpointSitesExported];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointSitesExported attributes:nil];

    return export;
}

@end
