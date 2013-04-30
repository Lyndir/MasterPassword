//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"

@implementation MPAppDelegate_Shared {
    NSManagedObjectID *_activeUserOID;
}

+ (MPAppDelegate_Shared *)get {

#if TARGET_OS_IPHONE
    return (MPAppDelegate_Shared *)[UIApplication sharedApplication].delegate;
#elif defined (__MAC_OS_X_VERSION_MIN_REQUIRED)
    return (MPAppDelegate_Shared *)[NSApplication sharedApplication].delegate;
#else
#error Unsupported OS.
#endif
}

- (MPUserEntity *)activeUserForThread {

    return [self activeUserInContext:[MPAppDelegate_Shared managedObjectContextForThreadIfReady]];
}

- (MPUserEntity *)activeUserInContext:(NSManagedObjectContext *)moc {

    if (!_activeUserOID || !moc)
        return nil;

    NSError *error;
    MPUserEntity *activeUser = (MPUserEntity *)[moc existingObjectWithID:_activeUserOID error:&error];
    if (!activeUser)
    err(@"Failed to retrieve active user: %@", error);

    return activeUser;
}

- (void)setActiveUser:(MPUserEntity *)activeUser {

    NSError *error;
    if (activeUser.objectID.isTemporaryID && ![activeUser.managedObjectContext obtainPermanentIDsForObjects:@[ activeUser ] error:&error])
    err(@"Failed to obtain a permanent object ID after setting active user: %@", error);

    _activeUserOID = activeUser.objectID;
}

@end
