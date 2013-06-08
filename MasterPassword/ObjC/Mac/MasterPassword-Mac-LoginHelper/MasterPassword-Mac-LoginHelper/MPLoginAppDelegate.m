//
//  MPAppDelegate.m
//  MasterPassword-Mac-LoginHelper
//
//  Created by Maarten Billemont on 2013-06-07.
//  Copyright (c) 2013 Maarten Billemont. All rights reserved.
//

#import "MPLoginAppDelegate.h"

@implementation MPLoginAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    NSLog(@"LoginHelper did start");
    for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications])
        if ([[app bundleIdentifier] isEqualToString:@"com.lyndir.lhunath.MasterPassword.Mac"]) {
            NSLog(@"Already running.");
            [NSApp terminate:nil];
            return;
        }

    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSLog(@"Path: %@", path);
    NSArray *p = [path pathComponents];
    NSLog(@"PathComponents: %@", p);
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
    [pathComponents removeLastObject];
    [pathComponents removeLastObject];
    [pathComponents removeLastObject];
    [pathComponents addObject:@"MacOS"];
    [pathComponents addObject:@"MasterPassword"];
    NSLog(@"PathComponents modified: %@", pathComponents);
    NSString *newPath = [NSString pathWithComponents:pathComponents];
    NSLog(@"newPath: %@", newPath);
    NSLog(@"launchApplication: %@", @([[NSWorkspace sharedWorkspace] launchApplication:newPath]));
}

@end
