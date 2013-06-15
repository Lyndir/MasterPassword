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

@interface MPAppDelegate_Shared(Store)<UbiquityStoreManagerDelegate>

+ (NSManagedObjectContext *)managedObjectContextForThreadIfReady;
+ (BOOL)managedObjectContextPerformBlock:(void (^)(NSManagedObjectContext *context))mocBlock;
+ (BOOL)managedObjectContextPerformBlockAndWait:(void (^)(NSManagedObjectContext *context))mocBlock;

- (UbiquityStoreManager *)storeManager;

- (void)addElementNamed:(NSString *)siteName completion:(void (^)(MPElementEntity *element))completion;
- (MPElementEntity *)changeElement:(MPElementEntity *)element inContext:(NSManagedObjectContext *)context toType:(MPElementType)type;
- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *(^)(NSString *userName))importPassword
              askUserPassword:(NSString *(^)(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword;
- (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords;

@end
