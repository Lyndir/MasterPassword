//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

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
+ (BOOL)managedObjectContextForMainThreadPerformBlock:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock;
+ (BOOL)managedObjectContextForMainThreadPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock;
+ (BOOL)managedObjectContextPerformBlock:(void ( ^ )(NSManagedObjectContext *context))mocBlock;
+ (BOOL)managedObjectContextPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *context))mocBlock;

- (MPFixableResult)findAndFixInconsistenciesSaveInContext:(NSManagedObjectContext *)context;
- (void)deleteAndResetStore;

/** @param completion The block to execute after adding the site, executed from the main thread with the new site in the main MOC. */
- (void)addSiteNamed:(NSString *)siteName completion:(void ( ^ )(MPSiteEntity *site, NSManagedObjectContext *context))completion;
- (MPSiteEntity *)changeSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context toType:(MPSiteType)type;
- (MPImportResult)importSites:(NSString *)importedSitesString
            askImportPassword:(NSString *( ^ )(NSString *userName))importPassword
              askUserPassword:(NSString *( ^ )(NSString *userName, NSUInteger importCount, NSUInteger deleteCount))userPassword;
- (NSString *)exportSitesRevealPasswords:(BOOL)revealPasswords;

@end
