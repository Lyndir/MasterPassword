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
#import "MPEmergencySegue.h"
#import "MPEmergencyViewController.h"
#import "MPPasswordsSegue.h"

@interface MPCombinedViewController()

@property(nonatomic, weak) MPUsersViewController *usersVC;
@property(nonatomic, weak) MPEmergencyViewController *emergencyVC;
@end

@implementation MPCombinedViewController {
    NSArray *_notificationObservers;
    MPPasswordsViewController *_passwordsVC;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [self setMode:MPCombinedModeUserSelection animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [[self navigationController] setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [self registerObservers];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [self removeObservers];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"users"])
        self.usersVC = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"passwords"]) {
        NSAssert([segue isKindOfClass:[MPPasswordsSegue class]], @"passwords segue should be MPPasswordsSegue: %@", segue);
        NSAssert([sender isKindOfClass:[NSDictionary class]], @"sender should be dictionary: %@", sender);
        NSAssert([[sender objectForKey:@"animated"] isKindOfClass:[NSNumber class]], @"sender should contain 'animated': %@", sender);
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

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController
                                      fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {

    if ([identifier isEqualToString:@"unwind-emergency"]) {
        MPEmergencySegue *segue = [[MPEmergencySegue alloc] initWithIdentifier:identifier
                                                                        source:fromViewController destination:toViewController];
        segue.unwind = YES;
        dbg_return(segue);
    }

    dbg_return((id)nil);
}

#pragma mark - Properties

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
    dbg(@"top layout length: %f", self.usersVC.topLayoutGuide.length);

    switch (self.mode) {
        case MPCombinedModeUserSelection: {
            [self.usersVC setActive:YES animated:animated];
            if (_passwordsVC) {
                MPPasswordsSegue *segue = [[MPPasswordsSegue alloc] initWithIdentifier:@"passwords" source:_passwordsVC destination:self];
                [self prepareForSegue:segue sender:@{ @"animated" : @(animated) }];
                [segue perform];
            }
            break;
        }
        case MPCombinedModePasswordSelection: {
            [self.usersVC setActive:NO animated:animated];
            [self performSegueWithIdentifier:@"passwords" sender:@{ @"animated" : @(animated) }];
            break;
        }
    }
}

#pragma mark - Private

- (void)registerObservers {

    if ([_notificationObservers count])
        return;

    Weakify(self);
    _notificationObservers = @[
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:MPSignedInNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                [self setMode:MPCombinedModePasswordSelection];
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:MPSignedOutNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                [self setMode:MPCombinedModeUserSelection animated:[note.userInfo[@"animated"] boolValue]];
            }],
    ];
}

- (void)removeObservers {

    for (id observer in _notificationObservers)
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    _notificationObservers = nil;
}

@end
