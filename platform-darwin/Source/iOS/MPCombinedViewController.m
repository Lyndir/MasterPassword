/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPCombinedViewController.h
//  MPCombinedViewController
//
//  Created by lhunath on 2014-03-08.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPCombinedViewController.h"
#import "MPUsersViewController.h"
#import "MPPasswordsViewController.h"
#import "MPEmergencyViewController.h"
#import "MPPasswordsSegue.h"

@implementation MPCombinedViewController

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    _mode = MPCombinedModeUserSelection;
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
        NSAssert( [segue isKindOfClass:[MPPasswordsSegue class]], @"passwords segue should be MPPasswordsSegue: %@", segue );
        NSAssert( [sender isKindOfClass:[NSDictionary class]], @"sender should be dictionary: %@", sender );
        NSAssert( [[sender objectForKey:@"animated"] isKindOfClass:[NSNumber class]], @"sender should contain 'animated': %@", sender );
        [(MPPasswordsSegue *)segue setAnimated:[sender[@"animated"] boolValue]];
        UIViewController *destinationVC = segue.destinationViewController;
        _passwordsVC = [destinationVC isKindOfClass:[MPPasswordsViewController class]]? (MPPasswordsViewController *)destinationVC: nil;
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

    if (_mode == mode && animated)
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
            if (_passwordsVC) {
                MPPasswordsSegue *segue = [[MPPasswordsSegue alloc] initWithIdentifier:@"passwords" source:_passwordsVC destination:self];
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
