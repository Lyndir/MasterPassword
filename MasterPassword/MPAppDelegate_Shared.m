//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

@implementation MPAppDelegate (Shared)

+ (MPAppDelegate *)get {
    
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    return (MPAppDelegate *)[UIApplication sharedApplication].delegate;
#elif defined (__MAC_OS_X_VERSION_MIN_REQUIRED)
    return (MPAppDelegate *)[NSApplication sharedApplication].delegate;
#else
#error Unsupported OS.
#endif
}

- (NSURL *)applicationFilesDirectory {

#if __IPHONE_OS_VERSION_MIN_REQUIRED
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
#else
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *applicationFilesDirectory = [appSupportURL URLByAppendingPathComponent:@"com.lyndir.lhunath.MasterPassword"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:applicationFilesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
        err(@"Couldn't create application directory: %@, error occurred: %@", applicationFilesDirectory, error);
    
    return applicationFilesDirectory;
#endif
}

@end
