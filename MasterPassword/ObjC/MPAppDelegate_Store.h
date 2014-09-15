//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

#import "MPFixable.h"

typedef NS_ENUM( NSUInteger, MPImportResult ) {
    MPImportResultSuccess,
    MPImportResultCancelled,
    MPImportResultInvalidPassword,
    MPImportResultMalformedInput,
    MPImportResultInternalError,
};

@interface MPAppDelegate_Shared(Store)

+ (NSManagedObjectContext *)managedObjectContextForMainThreadIfReady;
+ (BOOL)managedObjectContextForMainThreadPerformBlock:(void (^)(NSManagedObjectContext *mainContext))mocBlock;
+ (BOOL)managedObjectContextForMainThreadPerformBlockAndWait:(void (^)(NSManagedObjectContext *mainContext))mocBlock;
+ (BOOL)managedObjectContextPerformBlock:(void (^)(NSManagedObjectContext *context))mocBlock;
+ (BOOL)managedObjectContextPerformBlockAndWait:(void (^)(NSManagedObjectContext *context))mocBlock;

- (MPFixableResult)findAndFixInconsistenciesSaveInContext:(NSManagedObjectContext *)context;

/** @param completion The block to execute after adding the element, executed from the main thread with the new element in the main MOC. */
- (void)addElementNamed:(NSString *)siteName completion:(void ( ^ )(MPElementEntity *element, NSManagedObjectContext *context))completion;
- (MPElementEntity *)changeElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context toType:(MPElementType)type;
- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *(^)(NSString *userName))importPassword
              askUserPassword:(NSString *(^)(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword;
- (NSString *)exportSitesRevealPasswords:(BOOL)revealPasswords;

@end
