//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Store.h"
#import "MPElementEntity.h"

@implementation MPAppDelegate (Store)

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
#else
    [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillBecomeActiveNotification
                                                      object:[NSApplication sharedApplication] queue:nil
#endif
                                                  usingBlock:^(NSNotification *note) {
                                                      [storeManager checkiCloudStatus];
                                                  }];
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                      object:[UIApplication sharedApplication] queue:nil
#else
     [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification
                                                       object:[NSApplication sharedApplication] queue:nil
#endif
                                                  usingBlock:^(NSNotification *note) {
                                                      [self saveContext];
                                                  }];
    
    return storeManager;
}

- (NSManagedObjectContext *)managedObjectContextForUbiquityStoreManager:(UbiquityStoreManager *)usm {
    
    return self.managedObjectContext;
}

- (void)saveContext {
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges])
            if (![self.managedObjectContext save:&error])
                err(@"Unresolved error %@", error);
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
                    trc(@"For descriptor: %@, found: %@: %@ (%@)", entity.name, [o class], e.name, e.mpHashHex);
                } else {
                    trc(@"For descriptor: %@, found: %@", entity.name, [o class]);
                }
            }
        }
        trc(@"---");
        if ([MPAppDelegate get].keyHashHex) {
            trc(@"=== Known sites ===");
            NSFetchRequest *fetchRequest = [[self managedObjectModel]
                                            fetchRequestFromTemplateWithName:@"MPElements"
                                            substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   @"",                                     @"query",
                                                                   [MPAppDelegate get].keyHashHex,          @"mpHashHex",
                                                                   nil]];
            [fetchRequest setSortDescriptors:
             [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
            
            NSError *error = nil;
            for (MPElementEntity *e in [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error]) {
                trc(@"Found site: %@ (%@): %@", e.name, e.mpHashHex, e);
            }
            trc(@"---");
        } else
            trc(@"Not printing sites: master password not set.");
    }];
}
     
     - (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords {
         
         static NSDateFormatter *rfc3339DateFormatter = nil;
         if (!rfc3339DateFormatter) {
             rfc3339DateFormatter = [NSDateFormatter new];
             NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
             [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
             [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
             [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
         }
         
         // Header.
         NSMutableString *export = [NSMutableString new];
         [export appendFormat:@"# MasterPassword %@\n", [PearlInfoPlist get].CFBundleVersion];
         if (showPasswords)
             [export appendFormat:@"# Export of site names and passwords in clear-text.\n"];
         else
             [export appendFormat:@"# Export of site names and stored passwords (unless device-private) encrypted with the master key.\n"];
         [export appendFormat:@"\n"];
         [export appendFormat:@"# Key ID: %@\n", self.keyHashHex];
         [export appendFormat:@"# Date: %@\n", [rfc3339DateFormatter stringFromDate:[NSDate date]]];
         if (showPasswords)
             [export appendFormat:@"# Passwords: VISIBLE\n"];
         else
             [export appendFormat:@"# Passwords: PROTECTED\n"];
         [export appendFormat:@"\n"];
         
         // Sites.
         NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
         fetchRequest.sortDescriptors    = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]];
         fetchRequest.predicate = [NSPredicate predicateWithFormat:@"mpHashHex == %@", self.keyHashHex];
         __autoreleasing NSError *error = nil;
         NSArray *elements = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
         if (error)
             err(@"Error fetching sites for export: %@", error);
         
         for (MPElementEntity *element in elements) {
             NSString *name = element.name;
             MPElementType type = (unsigned)element.type;
             int16_t uses  = element.uses;
             NSTimeInterval lastUsed = element.lastUsed;
             NSString *content = nil;
             
             // Determine the content to export.
             if (!(type & MPElementFeatureDevicePrivate)) {
                 if (showPasswords)
                     content = element.content;
                 else if (type & MPElementFeatureExportContent)
                     content = element.exportContent;
             }
             
             [export appendFormat:@"%@\t%d\t%d\t%@\t%@\n",
              name, type, uses, [rfc3339DateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:lastUsed]], content];
             
         }
         
         return export;
     }

@end
