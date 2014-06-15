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
#import "MPPasswordLargeCell.h"
#import "MPPasswordTypesCell.h"
#import "MPPopdownSegue.h"
#import "MPAppDelegate_Key.h"
#import "MPCoachmarkViewController.h"

@interface MPPasswordsViewController()<NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property(nonatomic, readonly) NSString *query;

@end

@implementation MPPasswordsViewController {
    __weak id _storeObserver;
    __weak id _mocObserver;
    NSArray *_notificationObservers;
    __weak UITapGestureRecognizer *_passwordsDismissRecognizer;
    NSFetchedResultsController *_fetchedResultsController;
    BOOL _exactMatch;
    UIColor *_backgroundColor;
    UIColor *_darkenedBackgroundColor;
    __weak UIViewController *_popdownVC;
}

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    _backgroundColor = self.passwordCollectionView.backgroundColor;
    _darkenedBackgroundColor = [_backgroundColor colorWithAlphaComponent:0.6f];
    _coachmark = [MPCoachmark coachmarkForClass:[self class] version:0];

    self.view.backgroundColor = [UIColor clearColor];
    [self.passwordCollectionView automaticallyAdjustInsetsForKeyboard];
    [self.passwordsSearchBar enumerateViews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if ([subview isKindOfClass:[UITextField class]])
            ((UITextField *)subview).keyboardAppearance = UIKeyboardAppearanceDark;
    } recurse:YES];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self registerObservers];
    [self observeStore];
    [self updateConfigKey:nil];
    [self updatePasswords];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    PearlMainQueueAfter( 1, ^{
        if (!self.coachmark.coached)
            [self performSegueWithIdentifier:@"coachmarks" sender:self];
    } );
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [self removeObservers];
    [self stopObservingStore];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"popdown"])
        _popdownVC = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"coachmarks"])
        ((MPCoachmarkViewController *)segue.destinationViewController).coachmark = self.coachmark;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    [self.passwordCollectionView.collectionViewLayout invalidateLayout];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)       collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {

    return CGSizeMake( collectionView.bounds.size.width, CGPointFromCGRectBottom( self.passwordsSearchBar.frame ).y );
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.passwordCollectionView) {
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
        CGFloat itemWidth = UIEdgeInsetsInsetRect(self.passwordCollectionView.bounds, layout.sectionInset).size.width;
        return CGSizeMake( itemWidth, 100 );
    }

    Throw(@"Unexpected collection view: %@", collectionView);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    if (collectionView == self.passwordCollectionView)
        return [self.fetchedResultsController.sections count];

    Throw(@"Unexpected collection view: %@", collectionView);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == self.passwordCollectionView)
        return ![MPiOSAppDelegate get].activeUserOID? 0:
               ((id<NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[section]).numberOfObjects +
               (!_exactMatch && [[self query] length]? 1: 0);

    Throw(@"Unexpected collection view: %@", collectionView);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.passwordCollectionView) {
        [UIView setAnimationsEnabled:NO];
        MPPasswordTypesCell *cell;
        if (indexPath.item < ((id<NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[indexPath.section]).numberOfObjects) {
            MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
            cell = [MPPasswordTypesCell dequeueCellForElement:element fromCollectionView:collectionView atIndexPath:indexPath];
        }
        else
            // New Site.
            cell = [MPPasswordTypesCell dequeueCellForTransientSite:self.query fromCollectionView:collectionView atIndexPath:indexPath];
        cell.passwordsViewController = self;

        [UIView setAnimationsEnabled:YES];
        return cell;
    }

    Throw(@"Unexpected collection view: %@", collectionView);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath {

    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"MPPasswordHeader" forIndexPath:indexPath];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

    if (controller == _fetchedResultsController) {
        [self.passwordCollectionView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]];
        if (![newIndexPath isEqual:indexPath])
            [self.passwordCollectionView reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section]];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    if (controller == _fetchedResultsController)
        [self.passwordCollectionView reloadData];
}

#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {

    if (searchBar == self.passwordsSearchBar) {
        searchBar.text = nil;
        return YES;
    }

    return NO;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {

    if (searchBar == self.passwordsSearchBar) {
        [self.passwordsSearchBar setShowsCancelButton:YES animated:YES];
        [UIView animateWithDuration:0.3f animations:^{
            self.passwordCollectionView.backgroundColor = _darkenedBackgroundColor;
        }];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {

    if (searchBar == self.passwordsSearchBar) {
        [self.passwordsSearchBar setShowsCancelButton:NO animated:YES];
        if (_passwordsDismissRecognizer)
            [self.view removeGestureRecognizer:_passwordsDismissRecognizer];

        [UIView animateWithDuration:0.3f animations:^{
            self.passwordCollectionView.backgroundColor = _backgroundColor;
        }];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];
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
                    addObserverForName:MPSignedOutNotification object:nil
                                 queue:nil usingBlock:^(NSNotification *note) {
                Strongify(self);

                _fetchedResultsController = nil;
                self.passwordsSearchBar.text = nil;
                [self updatePasswords];
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                [self updatePasswords];
                [UIView animateWithDuration:1 animations:^{
                    self.passwordSelectionContainer.alpha = 1;
                }];
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:MPCheckConfigNotification object:nil queue:[NSOperationQueue mainQueue]
                            usingBlock:^(NSNotification *note) {
                [self updateConfigKey:note.object];
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
//                    Strongify(self);
//                    [self updatePasswords];
                }];
    if (!_storeObserver)
        _storeObserver = [[NSNotificationCenter defaultCenter]
                addObserverForName:USMStoreDidChangeNotification object:nil
                             queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                    Strongify(self);
                    _fetchedResultsController = nil;
                    [self updatePasswords];
                }];
}

- (void)stopObservingStore {

    if (_mocObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:_mocObserver];
    if (_storeObserver)
        [[NSNotificationCenter defaultCenter] removeObserver:_storeObserver];
}

- (void)updateConfigKey:(NSString *)key {

    if (!key || [key isEqualToString:NSStringFromSelector( @selector(dictationSearch) )])
        self.passwordsSearchBar.keyboardType = [[MPiOSConfig get].dictationSearch boolValue]? UIKeyboardTypeDefault: UIKeyboardTypeURL;
    if (!key || [key isEqualToString:NSStringFromSelector( @selector(hidePasswords) )])
        [self updatePasswords];
}

- (void)updatePasswords {

    NSString *query = self.query;
    NSManagedObjectID *activeUserOID = [MPiOSAppDelegate get].activeUserOID;
    if (!activeUserOID) {
        self.passwordsSearchBar.text = nil;
        PearlMainQueue( ^{
            [self.passwordCollectionView reloadData];
            [self.passwordCollectionView setContentOffset:CGPointMake( 0, -self.passwordCollectionView.contentInset.top ) animated:YES];
        } );
        return;
    }

    [self.fetchedResultsController.managedObjectContext performBlock:^{
        NSError *error = nil;
        self.fetchedResultsController.fetchRequest.predicate =
                [query length]?
                [NSPredicate predicateWithFormat:@"user == %@ AND name BEGINSWITH[cd] %@", activeUserOID, query]:
                [NSPredicate predicateWithFormat:@"user == %@", activeUserOID];
        if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);

        _exactMatch = NO;
        for (MPElementEntity *entity in self.fetchedResultsController.fetchedObjects)
            if ([entity.name isEqualToString:query]) {
                _exactMatch = YES;
                break;
            }

        PearlMainQueue( ^{
            [self.passwordCollectionView performBatchUpdates:^{
                NSInteger fromSections = self.passwordCollectionView.numberOfSections;
                NSInteger toSections = [self numberOfSectionsInCollectionView:self.passwordCollectionView];
                for (int section = 0; section < MAX(toSections, fromSections); section++) {
                    if (section >= fromSections) {
                        dbg(@"insertSections:%d", section);
                        [self.passwordCollectionView insertSections:[NSIndexSet indexSetWithIndex:section]];
                    }
                    else if (section >= toSections) {
                        dbg(@"deleteSections:%d", section);
                        [self.passwordCollectionView deleteSections:[NSIndexSet indexSetWithIndex:section]];
                    }
                    else {
                        dbg(@"reloadSections:%d", section);
                        [self.passwordCollectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
                    }
                }
            }                                     completion:^(BOOL finished) {
                if (finished)
                    [self.passwordCollectionView setContentOffset:CGPointMake( 0, -self.passwordCollectionView.contentInset.top )
                                                         animated:YES];
            }];
        } );
    }];
}

#pragma mark - Properties

- (NSString *)query {

    return [self.passwordsSearchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSFetchedResultsController *)fetchedResultsController {

    if (!_fetchedResultsController) {
        [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlockAndWait:^(NSManagedObjectContext *mainContext) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
            fetchRequest.sortDescriptors = @[
                    [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector( @selector(lastUsed) ) ascending:NO]
            ];
            fetchRequest.fetchBatchSize = 10;
            _fetchedResultsController = [[NSFetchedResultsController alloc]
                    initWithFetchRequest:fetchRequest managedObjectContext:mainContext sectionNameKeyPath:nil cacheName:nil];
            _fetchedResultsController.delegate = self;
        }];
        [self observeStore];
    }

    return _fetchedResultsController;
}

- (void)setActive:(BOOL)active {

    [self setActive:active animated:NO completion:nil];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {

    _active = active;

    [UIView animateWithDuration:animated? 0.4f: 0 animations:^{
        [self.navigationBarToTopConstraint layoutWithPriority:active? 1: UILayoutPriorityDefaultHigh];
        [self.passwordsToBottomConstraint layoutWithPriority:active? 1: UILayoutPriorityDefaultHigh];
    }                completion:completion];
}

#pragma mark - Actions

- (IBAction)dismissPopdown:(id)sender {

    if (_popdownVC)
        [[[MPPopdownSegue alloc] initWithIdentifier:@"unwind-popdown" source:_popdownVC destination:self] perform];
    else
        self.popdownToTopConstraint.priority = UILayoutPriorityDefaultHigh;
}

- (IBAction)signOut:(id)sender {

    [[MPiOSAppDelegate get] signOutAnimated:YES];
}

@end
