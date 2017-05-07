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
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"
#import "NSManagedObjectModel+KCOrderedAccessorFix.h"

@interface MPAppDelegate_Shared()

@property(strong, atomic) MPKey *key;
@property(strong, atomic) NSManagedObjectID *activeUserOID;
@property(strong, atomic) NSPersistentStoreCoordinator *storeCoordinator;

@end

@implementation MPAppDelegate_Shared

+ (MPAppDelegate_Shared *)get {

#if TARGET_OS_IPHONE
    return (MPAppDelegate_Shared *)UIApp.delegate;
#elif defined (__MAC_OS_X_VERSION_MIN_REQUIRED)
    return (MPAppDelegate_Shared *)[NSApplication sharedApplication].delegate;
#else
#error Unsupported OS.
#endif
}

- (instancetype)init {

    if (!(self = [super init]))
        return nil;

    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    [model kc_generateOrderedSetAccessors];
    self.storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    return self;
}

- (MPUserEntity *)activeUserForMainThread {

    return [self activeUserInContext:[MPAppDelegate_Shared managedObjectContextForMainThreadIfReady]];
}

- (MPUserEntity *)activeUserInContext:(NSManagedObjectContext *)context {

    NSManagedObjectID *activeUserOID = self.activeUserOID;
    if (!activeUserOID || !context)
        return nil;

    MPUserEntity *activeUser = [MPUserEntity existingObjectWithID:activeUserOID inContext:context];
    if (!activeUser)
        [self signOutAnimated:YES];

    return activeUser;
}

- (void)setActiveUser:(MPUserEntity *)activeUser {

    self.activeUserOID = activeUser.permanentObjectID;
}

- (void)handleCoordinatorError:(NSError *)error {
}

@end
