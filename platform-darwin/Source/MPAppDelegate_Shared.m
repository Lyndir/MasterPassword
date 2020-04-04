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

#import <Countly/Countly.h>

@interface MPAppDelegate_Shared()

@property(strong, atomic) MPKey *key;
@property(strong, atomic) NSManagedObjectID *activeUserOID;
@property(strong, atomic) NSPersistentStoreCoordinator *storeCoordinator;

@end

@implementation MPAppDelegate_Shared

static MPAppDelegate_Shared *instance;

+ (MPAppDelegate_Shared *)get {

    return instance;
}

- (instancetype)init {

    if (!(self = instance = [super init]))
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
        [self signOut];

    return activeUser;
}

- (void)setActiveUser:(MPUserEntity *)activeUser {

    NSManagedObjectID *activeUserOID = activeUser.permanentObjectID;
    if ([self.activeUserOID isEqual:activeUserOID])
        return;

    if (self.key)
        self.key = nil;

    if ([[MPConfig get].sendInfo boolValue])
        [Countly.sharedInstance userLoggedOut];

    [[NSNotificationCenter defaultCenter] postNotificationName:MPSignedOutNotification object:self];

    self.activeUserOID = activeUserOID;
}

- (void)handleCoordinatorError:(NSError *)error {
}

@end
