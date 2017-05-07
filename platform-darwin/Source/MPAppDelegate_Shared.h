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

#import "MPEntities.h"

#if TARGET_OS_IPHONE

@interface MPAppDelegate_Shared : PearlAppDelegate

#else

@interface MPAppDelegate_Shared : NSObject<PearlConfigDelegate>

#endif

@property(strong, atomic, readonly) MPKey *key;
@property(strong, atomic, readonly) NSManagedObjectID *activeUserOID;
@property(strong, atomic, readonly) NSPersistentStoreCoordinator *storeCoordinator;

+ (instancetype)get;

- (MPUserEntity *)activeUserForMainThread;
- (MPUserEntity *)activeUserInContext:(NSManagedObjectContext *)context;
- (void)setActiveUser:(MPUserEntity *)activeUser;
- (void)handleCoordinatorError:(NSError *)error;

@end
