//
//  main.m
//  MasterPassword-Mac-LoginHelper
//
//  Created by Maarten Billemont on 2013-06-07.
//  Copyright (c) 2013 Maarten Billemont. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[]) {

    NSURL *bundleURL = [[[[[[NSBundle mainBundle] bundleURL]
            URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]
            URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];

    NSError *error = nil;
    NSRunningApplication *application = [[NSWorkspace sharedWorkspace]
            launchApplicationAtURL:bundleURL options:NSWorkspaceLaunchWithoutActivation
                     configuration:@{} error:&error];

    if (!application || error) {
        NSLog( @"Error launching main app: %@", [error debugDescription] );
        return (int)error.code?: 1;
    }

    return 0;
}
