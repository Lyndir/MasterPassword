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
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"
#import "MPUsersViewController.h"
#import "MPPasswordsViewController.h"

@interface MPCombinedViewController()

@property(strong, nonatomic) IBOutlet NSLayoutConstraint *passwordsTopConstraint;
@property(nonatomic, strong) MPUsersViewController *usersVC;
@property(nonatomic, strong) MPPasswordsViewController *passwordsVC;
@end

@implementation MPCombinedViewController {
    NSArray *_notificationObservers;
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
    if ([segue.identifier isEqualToString:@"passwords"])
        self.passwordsVC = segue.destinationViewController;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}


#pragma mark - Properties

- (void)setMode:(MPCombinedMode)mode {

    [self setMode:mode animated:YES];
}

- (void)setMode:(MPCombinedMode)mode animated:(BOOL)animated {

    _mode = mode;

    [self becomeFirstResponder];

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        switch (self.mode) {
            case MPCombinedModeUserSelection: {
                [self.usersVC setActive:YES animated:NO];
                [self.passwordsVC setActive:NO animated:NO];
//            MPUsersViewController *usersVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MPUsersViewController"];
//            [self setViewControllers:@[ usersVC ] direction:UIPageViewControllerNavigationDirectionReverse
//                            animated:animated completion:nil];
                break;
            }
            case MPCombinedModePasswordSelection: {
                [self.usersVC setActive:NO animated:NO];
                [self.passwordsVC setActive:YES animated:NO];
//            MPPasswordsViewController *passwordsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MPPasswordsViewController"];
//            [self setViewControllers:@[ passwordsVC ] direction:UIPageViewControllerNavigationDirectionForward
//                            animated:animated completion:nil];
                break;
            }
        }

        [self.passwordsTopConstraint apply];
    }];
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


#pragma mark - Actions

- (IBAction)doSignOut:(UIBarButtonItem *)sender {

    [[MPiOSAppDelegate get] signOutAnimated:YES];
}

@end
