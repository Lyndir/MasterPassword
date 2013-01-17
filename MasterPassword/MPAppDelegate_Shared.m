//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"

@interface MPAppDelegate_Shared ()

@property (strong, nonatomic) NSManagedObjectID *activeUserID;

@end

@implementation MPAppDelegate_Shared

+ (MPAppDelegate_Shared *)get {

#if TARGET_OS_IPHONE
    return (MPAppDelegate_Shared *)[UIApplication sharedApplication].delegate;
#elif defined (__MAC_OS_X_VERSION_MIN_REQUIRED)
    return (MPAppDelegate_Shared *)[NSApplication sharedApplication].delegate;
#else
#error Unsupported OS.
#endif
}

- (MPUserEntity *)activeUser {

    if (!self.activeUserID)
        return nil;

    return (MPUserEntity *)[self.managedObjectContextIfReady objectWithID:self.activeUserID];
}

- (void)setActiveUser:(MPUserEntity *)activeUser {

    self.activeUserID = activeUser.objectID;
}

@end
