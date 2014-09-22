//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"

@interface MPAppDelegate_Shared ()

@property(strong, nonatomic) MPKey *key;
@property(strong, nonatomic) NSManagedObjectID *activeUserOID;

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

    NSError *error;
    if (activeUser.objectID.isTemporaryID && ![activeUser.managedObjectContext obtainPermanentIDsForObjects:@[ activeUser ] error:&error])
    err(@"Failed to obtain a permanent object ID after setting active user: %@", [error fullDescription]);

    self.activeUserOID = activeUser.objectID;
}

- (void)handleCoordinatorError:(NSError *)error {

}

@end
