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
#import "MPPasswordCell.h"

@interface MPPasswordsViewController()<NSFetchedResultsControllerDelegate>

@property(strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property(nonatomic, readonly) NSString *query;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation MPPasswordsViewController {
    __weak id _storeObserver;
    __weak id _mocObserver;
    NSArray *_notificationObservers;
    __weak UITapGestureRecognizer *_passwordsDismissRecognizer;
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return [self.fetchedResultsController.sections count] + 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == self.passwordCollectionView) {
        if (section < [self.fetchedResultsController.sections count])
            return ((id<NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[section]).numberOfObjects;

        // New Site.
        return [self.query length]? 1: 0;
    }

    Throw(@"unexpected collection view: %@", collectionView);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.passwordCollectionView) {
        MPPasswordCell *cell;
        if (indexPath.section < [self.fetchedResultsController.sections count]) {
            MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
            if (indexPath.item < 2)
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MPPasswordCell reuseIdentifierForElement:element] forIndexPath:indexPath];
            else
                cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MPPasswordCell reuseIdentifierForElement:element] forIndexPath:indexPath];

            [cell setElement:element];
        } else {
            // New Site.
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MPPasswordCell reuseIdentifier] forIndexPath:indexPath];
            cell.transientSite = self.query;
        }
        return cell;
    }

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

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {

    if (searchBar == self.passwordsSearchBar) {
        self.originalQuery = self.query;
        self.passwordsSearchBar.showsCancelButton = YES;
        _passwordsDismissRecognizer = [self.view dismissKeyboardForField:self.passwordsSearchBar onTouchForced:NO];

//        [UIView animateWithDuration:0.3f animations:^{
//            self.passwordCollectionView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3f];
//        }];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {

    if (searchBar == self.passwordsSearchBar) {
        self.passwordsSearchBar.showsCancelButton = NO;
        if (_passwordsDismissRecognizer)
            [self.view removeGestureRecognizer:_passwordsDismissRecognizer];

        [UIView animateWithDuration:0.3f animations:^{
            self.passwordCollectionView.backgroundColor = [UIColor clearColor];
        }];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];

    if (searchBar == self.passwordsSearchBar) {
        self.passwordsSearchBar.text = self.originalQuery;
        [self updatePasswords];
    }
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

    if (searchBar == self.passwordsSearchBar)
        [self updatePasswords];
}


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

        Weakify(self);

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
                    Strongify(self);
                    self.fetchedResultsController = nil;
                    [self updatePasswords];
                }];
}

- (void)stopObservingStore {

    if (_mocObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:_mocObserver];
    if (_storeObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:_storeObserver];
}

- (void)updatePasswords {

    [self.fetchedResultsController.managedObjectContext performBlock:^{
        NSManagedObjectID *activeUserOID = [MPiOSAppDelegate get].activeUserOID;
        if (!activeUserOID)
            return;

        NSError *error = nil;
        self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:
                @"user == %@ AND name BEGINSWITH[cd] %@", activeUserOID, self.query];
        if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.passwordCollectionView reloadData];
        }];
    }];
}

#pragma mark - Properties

- (NSString *)query {

    return [self.passwordsSearchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSFetchedResultsController *)fetchedResultsController {

    if (!_fetchedResultsController)
        [MPiOSAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
            fetchRequest.sortDescriptors = @[
                    [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector( @selector(lastUsed) ) ascending:NO]
            ];
            fetchRequest.fetchBatchSize = 10;
            _fetchedResultsController = [[NSFetchedResultsController alloc]
                    initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
            _fetchedResultsController.delegate = self;
        }];

    return _fetchedResultsController;
}

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
