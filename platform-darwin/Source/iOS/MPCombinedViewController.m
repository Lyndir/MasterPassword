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

#import "MPCombinedViewController.h"
#import "MPUsersViewController.h"
#import "MPSitesViewController.h"
#import "MPEmergencyViewController.h"
#import "MPSitesSegue.h"

@implementation MPCombinedViewController

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    self.mode = MPCombinedModeUserSelection;
    [self performSegueWithIdentifier:@"users" sender:self];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [[self navigationController] setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    PearlAddNotificationObserver( MPSignedInNotification, nil, [NSOperationQueue mainQueue],
            ^(MPCombinedViewController *self, NSNotification *note) {
                [self setMode:MPCombinedModePasswordSelection];
            } );
    PearlAddNotificationObserver( MPSignedOutNotification, nil, [NSOperationQueue mainQueue],
            ^(MPCombinedViewController *self, NSNotification *note) {
                [self setMode:MPCombinedModeUserSelection animated:[note.userInfo[@"animated"] boolValue]];
            } );
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObservers();
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"users"])
        self.usersVC = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"passwords"]) {
        NSAssert( [segue isKindOfClass:[MPSitesSegue class]], @"passwords segue should be MPSitesSegue: %@", segue );
        NSAssert( [sender isKindOfClass:[NSDictionary class]], @"sender should be dictionary: %@", sender );
        NSAssert( [[sender objectForKey:@"animated"] isKindOfClass:[NSNumber class]], @"sender should contain 'animated': %@", sender );
        [(MPSitesSegue *)segue setAnimated:[sender[@"animated"] boolValue]];
        UIViewController *destinationVC = segue.destinationViewController;
        self.sitesVC = [destinationVC isKindOfClass:[MPSitesViewController class]]? (MPSitesViewController *)destinationVC: nil;
    }
    if ([segue.identifier isEqualToString:@"emergency"])
        self.emergencyVC = segue.destinationViewController;
}

- (BOOL)prefersStatusBarHidden {

    return self.mode == MPCombinedModeUserSelection;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

- (BOOL)canBecomeFirstResponder {

    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {

    if (motion == UIEventSubtypeMotionShake && !self.emergencyVC)
        [self performSegueWithIdentifier:@"emergency" sender:self];
}

#pragma mark - Actions

- (IBAction)unwindToCombined:(UIStoryboardSegue *)sender {

    dbg( @"unwindToCombined:%@", sender );
}

#pragma mark - State

- (void)setMode:(MPCombinedMode)mode {

    [self setMode:mode animated:YES];
}

- (void)setMode:(MPCombinedMode)mode animated:(BOOL)animated {

    if (self.mode == mode && animated)
        return;
    _mode = mode;

    [self setNeedsStatusBarAppearanceUpdate];
    [self becomeFirstResponder];
    [self.usersVC setNeedsStatusBarAppearanceUpdate];
    [self.usersVC.view setNeedsUpdateConstraints];
    [self.usersVC.view setNeedsLayout];

    switch (self.mode) {
        case MPCombinedModeUserSelection: {
            self.usersVC.view.userInteractionEnabled = YES;
            [self.usersVC setActive:YES animated:animated];
            if (self.sitesVC) {
                MPSitesSegue *segue = [[MPSitesSegue alloc] initWithIdentifier:@"passwords" source:self.sitesVC destination:self];
                [self prepareForSegue:segue sender:@{ @"animated": @(animated) }];
                [segue perform];
            }
            break;
        }
        case MPCombinedModePasswordSelection: {
            self.usersVC.view.userInteractionEnabled = NO;
            [self.usersVC setActive:NO animated:animated];
            [self performSegueWithIdentifier:@"passwords" sender:@{ @"animated": @(animated) }];
            break;
        }
    }
}

#pragma mark - Private

@end
