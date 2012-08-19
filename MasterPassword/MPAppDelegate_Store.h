//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

#import "UbiquityStoreManager.h"

typedef enum {
    MPImportResultSuccess,
    MPImportResultCancelled,
    MPImportResultInvalidPassword,
    MPImportResultMalformedInput,
    MPImportResultInternalError,
} MPImportResult;

@interface MPAppDelegate_Shared (Store)<UbiquityStoreManagerDelegate>

+ (NSManagedObjectContext *)managedObjectContextIfReady;
+ (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContextIfReady;
- (NSManagedObjectModel *)managedObjectModel;

- (UbiquityStoreManager *)storeManager;
- (void)saveContext;

- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *(^)(NSString *userName))importPassword
              askUserPassword:(NSString *(^)(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword;
- (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords;

@end
