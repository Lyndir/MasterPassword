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

#import "MPLogsViewController.h"
#import "MPiOSAppDelegate.h"

@implementation MPLogsViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    PearlAddNotificationObserver( NSUserDefaultsDidChangeNotification, nil, [NSOperationQueue mainQueue],
            ^(MPLogsViewController *self, NSNotification *note) {
                self.levelControl.selectedSegmentIndex = [[MPiOSConfig get].traceMode boolValue]? 1: 0;
            } );

    self.logView.contentInset = UIEdgeInsetsMake( 64, 0, 93, 0 );

    [self refresh:nil];

    self.levelControl.selectedSegmentIndex = [[MPiOSConfig get].traceMode boolValue]? 1: 0;
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObservers();
}

#pragma clang diagnostic push
#pragma ide diagnostic ignored "UnavailableInDeploymentTarget"
- (void)viewSafeAreaInsetsDidChange {

    [super viewSafeAreaInsetsDidChange];

    self.logView.contentInset = UIEdgeInsetsMake( 44, 0, 0, 0 );
    self.logView.scrollIndicatorInsets = UIEdgeInsetsMake( 44, 0, 0, 0 );
}
#pragma clang diagnostic pop

- (IBAction)toggleLevelControl:(UISegmentedControl *)sender {

    BOOL traceEnabled = (BOOL)self.levelControl.selectedSegmentIndex;
    if (traceEnabled) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Enable Trace Mode?" message:
                                         @"Trace mode will log the internal operation of the application.\n"
                                         @"Unless you're looking for the cause of a problem, you should leave this off to save memory."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"Enable Trace" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MPiOSConfig get].traceMode = @YES;
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:controller animated:YES completion:nil];
    }
    else
        [MPiOSConfig get].traceMode = @NO;
}

- (IBAction)refresh:(UIBarButtonItem *)sender {

    self.logView.text = [[PearlLogger get] formatMessagesWithLevel:PearlLogLevelTrace];
}

- (IBAction)mail:(UIBarButtonItem *)sender {

    if ([[MPiOSConfig get].traceMode boolValue]) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Hiding Trace Messages" message:
                                         @"Trace-level log messages will not be mailed. "
                                         @"These messages contain sensitive and personal information."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
        [controller addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [[MPiOSAppDelegate get] openFeedbackWithLogs:YES forVC:self];
        }]];
        [self presentViewController:controller animated:YES completion:nil];
    }
    else
        [[MPiOSAppDelegate get] openFeedbackWithLogs:YES forVC:self];
}

@end
