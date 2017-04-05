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
