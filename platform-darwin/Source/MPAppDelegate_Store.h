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

@interface MPAppDelegate_Shared(Store)

+ (NSManagedObjectContext *)managedObjectContextForMainThreadIfReady;
+ (BOOL)managedObjectContextForMainThreadPerformBlock:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock;
+ (BOOL)managedObjectContextForMainThreadPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *mainContext))mocBlock;
+ (BOOL)managedObjectContextPerformBlock:(void ( ^ )(NSManagedObjectContext *context))mocBlock;
+ (BOOL)managedObjectContextPerformBlockAndWait:(void ( ^ )(NSManagedObjectContext *context))mocBlock;
- (id)managedObjectContextChanged:(void ( ^ )(NSDictionary<NSManagedObjectID *, NSString *> *affectedObjects))changedBlock;

- (MPFixableResult)findAndFixInconsistenciesSaveInContext:(NSManagedObjectContext *)context;
- (void)deleteAndResetStore;

/** @param completion The block to execute after adding the site, executed from the main thread with the new site in the main MOC. */
- (void)addSiteNamed:(NSString *)siteName completion:(void ( ^ )(MPSiteEntity *site, NSManagedObjectContext *context))completion;
- (MPSiteEntity *)changeSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context toType:(MPResultType)type;
- (void)importSites:(NSString *)importData
            askImportPassword:(NSString *( ^ )(NSString *userName))importPassword
              askUserPassword:(NSString *( ^ )(NSString *userName))userPassword
                       result:(void ( ^ )(NSError *error))resultBlock;
- (void)exportSitesRevealPasswords:(BOOL)revealPasswords
                 askExportPassword:(NSString *( ^ )(NSString *userName))askImportPassword
                            result:(void ( ^ )(NSString *mpsites, NSError *error))resultBlock;

@end
