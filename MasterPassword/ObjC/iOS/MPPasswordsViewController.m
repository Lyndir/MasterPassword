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
//  MPPasswordsViewController.h
//  MPPasswordsViewController
//
//  Created by lhunath on 2014-03-08.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordsViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@interface MPPasswordsViewController()
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@end

@implementation MPPasswordsViewController {
    __weak id _storeObserver;
    __weak id _mocObserver;
    NSArray *_notificationObservers;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self registerObservers];
    [self observeStore];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [self removeObservers];
    [self stopObservingStore];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (tableView == self.searchDisplayController.searchResultsTableView)
        return 0;

    NSAssert(NO, @"Unexpected table view: %@", tableView);
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (tableView == self.searchDisplayController.searchResultsTableView) {

    }

    NSAssert(NO, @"Unexpected table view: %@", tableView);
    return nil;
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    return NO;
}

// This isn't really in UITextFieldDelegate.  We fake it from UITextFieldTextDidChangeNotification.
- (void)textFieldDidChange:(UITextField *)textField {

}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == self.passwordCollectionView)
        return 0;

    Throw(@"unexpected collection view: %@", collectionView);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.passwordCollectionView)
        return nil;

    Throw(@"unexpected collection view: %@", collectionView);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - UILongPressGestureRecognizer

- (void)didLongPress:(UILongPressGestureRecognizer *)recognizer {

}

#pragma mark - UIScrollViewDelegate


#pragma mark - Private

- (void)registerObservers {

    if ([_notificationObservers count])
        return;

    Weakify(self);
    _notificationObservers = @[
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:UIApplicationWillResignActiveNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                self.passwordSelectionContainer.alpha = 0;
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

//                [self updateMode]; TODO: reload passwords list
                [UIView animateWithDuration:1 animations:^{
                    self.passwordSelectionContainer.alpha = 1;
                }];
            }],
    ];
}

- (void)removeObservers {

    for (id observer in _notificationObservers)
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    _notificationObservers = nil;
}

- (void)observeStore {

//        Weakify(self);

        NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForMainThreadIfReady];
        if (!_mocObserver && mainContext)
            _mocObserver = [[NSNotificationCenter defaultCenter]
                    addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:mainContext
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//                        Strongify(self);
//                [self updateMode]; TODO: reload passwords list
                    }];
        if (!_storeObserver)
            _storeObserver = [[NSNotificationCenter defaultCenter]
                    addObserverForName:USMStoreDidChangeNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//                        Strongify(self);
//                [self updateMode]; TODO: reload passwords list
                    }];
}

- (void)stopObservingStore {

    if (_mocObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:_mocObserver];
    if (_storeObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:_storeObserver];
}

#pragma mark - Properties

- (void)setActive:(BOOL)active {

    [self setActive:active animated:YES];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {

    _active = active;

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        self.navigationBarToPasswordsConstraint.priority = active? UILayoutPriorityDefaultHigh: 1;
        self.navigationBarToTopConstraint.priority = active? 1: UILayoutPriorityDefaultHigh;
        self.passwordsToBottomConstraint.priority = active? 1: UILayoutPriorityDefaultHigh;

        [self.navigationBarToPasswordsConstraint apply];
        [self.navigationBarToTopConstraint apply];
        [self.passwordsToBottomConstraint apply];
    }];
}

#pragma mark - Actions

@end
