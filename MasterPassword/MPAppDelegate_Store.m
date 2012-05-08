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

@end
