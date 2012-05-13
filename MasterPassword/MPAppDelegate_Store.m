//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Store.h"
#import "MPElementEntity.h"
#import "MPConfig.h"

@implementation MPAppDelegate_Shared (Store)

static NSDateFormatter *rfc3339DateFormatter = nil;

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
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    assert(coordinator);
    
    managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [managedObjectContext performBlockAndWait:^{
        managedObjectContext.persistentStoreCoordinator = coordinator;
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }];
    
    return managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    // Wait until the storeManager is ready.
    for(__block BOOL isReady = [self storeManager].isReady; !isReady;)
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            isReady = [self storeManager].isReady;
        });
    
    assert([self storeManager].isReady);
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
                                                     additionalStoreOptions:[NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSPersistentStoreFileProtectionKey]
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

- (void)printStore {
    
    if (![self managedObjectModel] || ![self managedObjectContext]) {
        trc(@"Not printing store: store not initialized.");
        return;
    }
    
    [self.managedObjectContext performBlock:^{
        trc(@"=== All entities ===");
        for(NSEntityDescription *entity in [[self managedObjectModel] entities]) {
            NSFetchRequest *request = [NSFetchRequest new];
            [request setEntity:entity];
            NSError *error;
            NSArray *results = [[self managedObjectContext] executeFetchRequest:request error:&error];
            for(NSManagedObject *o in results) {
                if ([o isKindOfClass:[MPElementEntity class]]) {
                    MPElementEntity *e = (MPElementEntity *)o;
                    trc(@"For descriptor: %@, found: %@: %@ (%@)", entity.name, [o class], e.name, e.keyID);
                } else {
                    trc(@"For descriptor: %@, found: %@", entity.name, [o class]);
                }
            }
        }
        trc(@"---");
        if ([MPAppDelegate_Shared get].keyID) {
            trc(@"=== Known sites ===");
            NSFetchRequest *fetchRequest = [[self managedObjectModel]
                                            fetchRequestFromTemplateWithName:@"MPElements"
                                            substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   @"",                                     @"query",
                                                                   [MPAppDelegate_Shared get].keyID,        @"keyID",
                                                                   nil]];
            [fetchRequest setSortDescriptors:
             [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
            
            NSError *error = nil;
            for (MPElementEntity *e in [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error]) {
                trc(@"Found site: %@ (%@): %@", e.name, e.keyID, e);
            }
            trc(@"---");
        } else
            trc(@"Not printing sites: master password not set.");
    }];
}

#pragma mark - UbiquityStoreManagerDelegate

- (NSManagedObjectContext *)managedObjectContextForUbiquityStoreManager:(UbiquityStoreManager *)usm {
    
    return self.managedObjectContext;
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager log:(NSString *)message {
    
    dbg(@"[StoreManager] %@", message);
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didSwitchToiCloud:(BOOL)didSwitch {
    
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:didSwitch? MPTestFlightCheckpointCloudEnabled: MPTestFlightCheckpointCloudDisabled];
#endif
    
    inf(@"Using iCloud? %@", didSwitch? @"YES": @"NO");
    [MPConfig get].iCloud = [NSNumber numberWithBool:didSwitch];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didEncounterError:(NSError *)error cause:(UbiquityStoreManagerErrorCause)cause context:(id)context {
    
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:str(@"MPTestFlightCheckpointMPErrorUbiquity_%d", cause)];
#endif
    err(@"StoreManager: cause=%d, context=%@, error=%@", cause, context, error);
    
    switch (cause) {
        case UbiquityStoreManagerErrorCauseDeleteStore:
        case UbiquityStoreManagerErrorCauseDeleteLogs:
        case UbiquityStoreManagerErrorCauseCreateStorePath:
        case UbiquityStoreManagerErrorCauseClearStore:
            break;
        case UbiquityStoreManagerErrorCauseOpenLocalStore: {
#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPTestFlightCheckpointLocalStoreIncompatible];
#endif
            wrn(@"Local store could not be opened, resetting it.");
            manager.hardResetEnabled = YES;
            [manager hardResetLocalStorage];
            
            [NSException raise:NSGenericException format:@"Local store was reset, application must be restarted to use it."];
            return;
        }
        case UbiquityStoreManagerErrorCauseOpenCloudStore: {
#ifdef TESTFLIGHT_SDK_VERSION
            [TestFlight passCheckpoint:MPTestFlightCheckpointCloudStoreIncompatible];
#endif
            wrn(@"iCloud store could not be opened, resetting it.");
            manager.hardResetEnabled = YES;
            [manager hardResetCloudStorage];
            break;
        }
    }
}

#pragma mark - Import / Export

- (void)loadRFC3339DateFormatter {
    
    if (rfc3339DateFormatter)
        return;
    
    rfc3339DateFormatter = [NSDateFormatter new];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
}

- (MPImportResult)importSites:(NSString *)importedSitesString withPassword:(NSString *)password
              askConfirmation:(BOOL(^)(NSUInteger importCount, NSUInteger deleteCount))confirmation {
    
    [self loadRFC3339DateFormatter];
    
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
    
    NSString *keyIDHex = nil;
    BOOL headerStarted = NO, headerEnded = NO;
    NSArray *importedSiteLines = [importedSitesString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableSet *elementsToDelete = [NSMutableSet set];
    NSMutableArray *importedSiteElements = [NSMutableArray arrayWithCapacity:[importedSiteLines count]];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
    for(NSString *importedSiteLine in importedSiteLines) {
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
            NSTextCheckingResult *headerElements = [[headerPattern matchesInString:importedSiteLine options:0 range:NSMakeRange(0, [importedSiteLine length])] lastObject];
            NSString *key = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:1]];
            NSString *value = [importedSiteLine substringWithRange:[headerElements rangeAtIndex:2]];
            if ([key isEqualToString:@"Key ID"]) {
                if (![(keyIDHex = value) isEqualToString:[keyIDForPassword(password) encodeHex]])
                    return MPImportResultInvalidPassword;
            }
            
            continue;
        }
        if (!headerEnded)
            continue;
        if (!keyIDHex)
            return MPImportResultMalformedInput;
        if (![importedSiteLine length])
            continue;
        
        // Site
        if ([sitePattern numberOfMatchesInString:importedSiteLine options:0 range:NSMakeRange(0, [importedSiteLine length])] != 1) {
            err(@"Invalid site format in line: %@", importedSiteLine);
            return MPImportResultMalformedInput;
        }
        NSTextCheckingResult *siteElements = [[sitePattern matchesInString:importedSiteLine options:0 range:NSMakeRange(0, [importedSiteLine length])] lastObject];
        NSString *lastUsed      = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:1]];
        NSString *uses          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:2]];
        NSString *type          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:3]];
        NSString *name          = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:4]];
        NSString *exportContent = [importedSiteLine substringWithRange:[siteElements rangeAtIndex:5]];
        
        // Find existing site.
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name == %@ AND keyID == %@", name, keyIDHex];
        NSArray *existingSites = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (error)
            err(@"Couldn't search existing sites: %@", error);
        if (!existingSites)
            return MPImportResultInternalError;
        
        [elementsToDelete addObjectsFromArray:existingSites];
        [importedSiteElements addObject:[NSArray arrayWithObjects:lastUsed, uses, type, name, exportContent, nil]];
    }
    
    // Ask for confirmation to import these sites.
    if (!confirmation([importedSiteElements count], [elementsToDelete count]))
        return MPImportResultCancelled;
    
    // Delete existing sites.
    [elementsToDelete enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        inf(@"Deleting site: %@, it will be replaced by an imported site.", [obj name]);
        [self.managedObjectContext deleteObject:obj];
    }];
    [self saveContext];
    
    // Import new sites.
    for (NSArray *siteElements in importedSiteElements) {
        NSDate *lastUsed        = [rfc3339DateFormatter dateFromString:[siteElements objectAtIndex:0]];
        NSInteger uses          = [[siteElements objectAtIndex:1] integerValue];
        MPElementType type      = (unsigned)[[siteElements objectAtIndex:2] integerValue];
        NSString *name          = [siteElements objectAtIndex:3];
        NSString *exportContent = [siteElements objectAtIndex:4];
        
        // Create new site.
        inf(@"Importing site: name=%@, lastUsed=%@, uses=%d, type=%u, keyID=%@", name, lastUsed, uses, type, keyIDHex);
        MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:ClassNameFromMPElementType(type)
                                                                 inManagedObjectContext:self.managedObjectContext];
        element.name = name;
        element.keyID = [keyIDHex decodeHex];
        element.type = type;
        element.uses = uses;
        element.lastUsed = [lastUsed timeIntervalSinceReferenceDate];
        if ([exportContent length])
            [element importContent:exportContent];
    }
    [self saveContext];
    
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointSitesImported];
#endif
    
    return MPImportResultSuccess;
}

- (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords {
    
    [self loadRFC3339DateFormatter];
    
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
    [export appendFormat:@"# Key ID: %@\n", [self.keyID encodeHex]];
    [export appendFormat:@"# Date: %@\n", [rfc3339DateFormatter stringFromDate:[NSDate date]]];
    if (showPasswords)
        [export appendFormat:@"# Passwords: VISIBLE\n"];
    else
        [export appendFormat:@"# Passwords: PROTECTED\n"];
    [export appendFormat:@"##\n"];
    [export appendFormat:@"#\n"];
    [export appendFormat:@"#               Last     Times  Password                  Site\tSite\n"];
    [export appendFormat:@"#               used      used      type                  name\tpassword\n"];
    
    // Sites.
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
    fetchRequest.sortDescriptors    = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"keyID == %@", self.keyID];
    __autoreleasing NSError *error = nil;
    NSArray *elements = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error)
        err(@"Error fetching sites for export: %@", error);
    
    for (MPElementEntity *element in elements) {
        NSTimeInterval lastUsed = element.lastUsed;
        int16_t uses  = element.uses;
        MPElementType type = (unsigned)element.type;
        NSString *name = element.name;
        NSString *content = nil;
        
        // Determine the content to export.
        if (!(type & MPElementFeatureDevicePrivate)) {
            if (showPasswords)
                content = element.content;
            else if (type & MPElementFeatureExportContent)
                content = element.exportContent;
        }
        
        [export appendFormat:@"%@  %8d  %8d  %20s\t%@\n",
         [rfc3339DateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:lastUsed]], uses, type, [name cStringUsingEncoding:NSUTF8StringEncoding], content? content: @""];
    }
    
#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPTestFlightCheckpointSitesExported];
#endif
    
    return export;
}

@end
