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
#import "MPPopdownSegue.h"
#import "MPAppDelegate_Key.h"
#import "MPPasswordCell.h"
#import "MPAnswersViewController.h"
#import "MPMessageViewController.h"

typedef NS_OPTIONS( NSUInteger, MPPasswordsTips ) {
    MPPasswordsBadNameTip = 1 << 0,
};

@interface MPPasswordsViewController()<NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property(nonatomic, readonly) NSString *query;

@end

@implementation MPPasswordsViewController {
    __weak UITapGestureRecognizer *_passwordsDismissRecognizer;
    NSFetchedResultsController *_fetchedResultsController;
    UIColor *_backgroundColor;
    UIColor *_darkenedBackgroundColor;
    __weak UIViewController *_popdownVC;
    BOOL _showTransientItem;
    NSUInteger _transientItem;
    NSCharacterSet *_siteNameAcceptableCharactersSet;
    NSArray *_fuzzyGroups;
}

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    NSMutableCharacterSet *siteNameAcceptableCharactersSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [siteNameAcceptableCharactersSet formIntersectionWithCharacterSet:[[NSCharacterSet uppercaseLetterCharacterSet] invertedSet]];
    [siteNameAcceptableCharactersSet addCharactersInString:@"@.-+~&_;:/"];
    _siteNameAcceptableCharactersSet = siteNameAcceptableCharactersSet;

    _backgroundColor = self.passwordCollectionView.backgroundColor;
    _darkenedBackgroundColor = [_backgroundColor colorWithAlphaComponent:0.6f];
    _transientItem = NSNotFound;

    self.view.backgroundColor = [UIColor clearColor];
    [self.passwordCollectionView automaticallyAdjustInsetsForKeyboard];
    self.passwordsSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if ([self.passwordsSearchBar respondsToSelector:@selector( keyboardAppearance )])
        self.passwordsSearchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    else
        [self.passwordsSearchBar enumerateViews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
            if ([subview isKindOfClass:[UITextField class]])
                ((UITextField *)subview).keyboardAppearance = UIKeyboardAppearanceDark;
        }                               recurse:YES];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self registerObservers];
    [self updateConfigKey:nil];
    [self updatePasswords];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
        if (![MPAlgorithmDefault tryMigrateUser:activeUser inContext:context])
            PearlMainQueue(^{
                [self performSegueWithIdentifier:@"message" sender:
                        [MPMessage messageWithTitle:@"You have sites that can be upgraded." text:
                                        @"Upgrading a site allows it to take advantage of the latest improvements in the Master Password algorithm.\n\n"
                                                "When you upgrade a site, a new and stronger password will be generated for it.  To upgrade a site, first log into the site, navigate to your account preferences where you can change the site's password.  Make sure you fill in any \"current password\" fields on the website first, then press the upgrade button here to get your new site password.\n\n"
                                                "You can then update your site's account with the new and stronger password.\n\n"
                                                "The upgrade button can be found in the site's settings and looks like this:"
                                               info:YES]];
            });
        [context saveToStore];
    }];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObservers();
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"popdown"])
        _popdownVC = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"answers"])
        ((MPAnswersViewController *)segue.destinationViewController).site =
                [[MPPasswordCell findAsSuperviewOf:sender] siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
    if ([segue.identifier isEqualToString:@"message"])
        ((MPMessageViewController *)segue.destinationViewController).message = sender;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    [self.passwordCollectionView.collectionViewLayout invalidateLayout];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
    CGFloat itemWidth = UIEdgeInsetsInsetRect( collectionView.bounds, layout.sectionInset ).size.width;
    return CGSizeMake( itemWidth, 100 );
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return [self.fetchedResultsController.sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (![MPiOSAppDelegate get].activeUserOID || !_fetchedResultsController)
        return 0;

    NSUInteger objects = ((id<NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[section]).numberOfObjects;
    _transientItem = _showTransientItem? objects: NSNotFound;
    return objects + (_showTransientItem? 1: 0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MPPasswordCell *cell = [MPPasswordCell dequeueCellFromCollectionView:collectionView indexPath:indexPath];
    [cell setFuzzyGroups:_fuzzyGroups];
    if (indexPath.item < ((id<NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[indexPath.section]).numberOfObjects)
        [cell setSite:[self.fetchedResultsController objectAtIndexPath:indexPath] animated:NO];
    else
        [cell setTransientSite:self.query animated:NO];

    return cell;
}

#pragma mark - UIScrollDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {

    if (scrollView == self.passwordCollectionView)
        for (MPPasswordCell *cell in [self.passwordCollectionView visibleCells])
            [cell setMode:MPPasswordCellModePassword animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

    if (controller == _fetchedResultsController) {
        @try {
            [self.passwordCollectionView performBatchUpdates:^{
                [self fetchedItemsDidUpdate];
                switch (type) {
                    case NSFetchedResultsChangeInsert:
                        [self.passwordCollectionView insertItemsAtIndexPaths:@[ newIndexPath ]];
                        break;
                    case NSFetchedResultsChangeDelete:
                        [self.passwordCollectionView deleteItemsAtIndexPaths:@[ indexPath ]];
                        break;
                    case NSFetchedResultsChangeMove:
                        [self.passwordCollectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
                        break;
                    case NSFetchedResultsChangeUpdate:
                        [self.passwordCollectionView reloadItemsAtIndexPaths:@[ indexPath ]];
                        break;
                }
            }                                     completion:nil];
        }
        @catch (NSException *exception) {
            wrn( @"While updating password cells: %@", [exception fullDescription] );
            [self.passwordCollectionView reloadData];
        }
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

        [self updatePasswords];
        [UIView animateWithDuration:0.3f animations:^{
            self.passwordCollectionView.backgroundColor = _backgroundColor;
        }];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    searchBar.text = nil;
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

    if (searchBar == self.passwordsSearchBar) {
        if ([[self.query stringByTrimmingCharactersInSet:_siteNameAcceptableCharactersSet] length])
            [self showTips:MPPasswordsBadNameTip];

        [self updatePasswords];
    }
}

#pragma mark - Private

- (void)showTips:(MPPasswordsTips)showTips {

    [UIView animateWithDuration:0.3f animations:^{
        if (showTips & MPPasswordsBadNameTip)
            self.badNameTipContainer.alpha = 1;
    }                completion:^(BOOL finished) {
        if (finished)
            PearlMainQueueAfter( 5, ^{
                [UIView animateWithDuration:0.3f animations:^{
                    if (showTips & MPPasswordsBadNameTip)
                        self.badNameTipContainer.alpha = 0;
                }];
            } );
    }];
}

- (void)fetchedItemsDidUpdate {

    NSString *query = self.query;
    _showTransientItem = [query length] > 0;
    NSUInteger objects = ((id<NSFetchedResultsSectionInfo>)self.fetchedResultsController.sections[0]).numberOfObjects;
    if (_showTransientItem && objects == 1 &&
        [[[self.fetchedResultsController.fetchedObjects firstObject] name] isEqualToString:query])
        _showTransientItem = NO;
    if ([self.passwordCollectionView numberOfSections] > 0) {
        if (!_showTransientItem && _transientItem != NSNotFound)
            [self.passwordCollectionView deleteItemsAtIndexPaths:
                    @[ [NSIndexPath indexPathForItem:_transientItem inSection:0] ]];
        else if (_showTransientItem && _transientItem == NSNotFound)
            [self.passwordCollectionView insertItemsAtIndexPaths:
                    @[ [NSIndexPath indexPathForItem:objects inSection:0] ]];
        else if (_transientItem != NSNotFound)
            [self.passwordCollectionView reloadItemsAtIndexPaths:
                    @[ [NSIndexPath indexPathForItem:_transientItem inSection:0] ]];
    }
}

- (void)registerObservers {

    PearlRemoveNotificationObservers();
    PearlAddNotificationObserver( UIApplicationDidEnterBackgroundNotification, nil, [NSOperationQueue mainQueue],
            ^(MPPasswordsViewController *self, NSNotification *note) {
                self.passwordSelectionContainer.alpha = 0;
            } );
    PearlAddNotificationObserver( UIApplicationWillEnterForegroundNotification, nil, [NSOperationQueue mainQueue],
            ^(MPPasswordsViewController *self, NSNotification *note) {
                [self updatePasswords];
            } );
    PearlAddNotificationObserver( UIApplicationDidBecomeActiveNotification, nil, [NSOperationQueue mainQueue],
            ^(MPPasswordsViewController *self, NSNotification *note) {
                [UIView animateWithDuration:0.7f animations:^{
                    self.passwordSelectionContainer.alpha = 1;
                }];
            } );
    PearlAddNotificationObserver( MPSignedOutNotification, nil, nil,
            ^(MPPasswordsViewController *self, NSNotification *note) {
                PearlMainQueue( ^{
                    _fetchedResultsController = nil;
                    self.passwordsSearchBar.text = nil;
                    [self.passwordCollectionView reloadData];
                } );
            } );
    PearlAddNotificationObserver( MPCheckConfigNotification, nil, nil,
            ^(MPPasswordsViewController *self, NSNotification *note) {
                PearlMainQueue( ^{
                    [self updateConfigKey:note.object];
                } );
            } );
    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresWillChangeNotification, nil, nil,
            ^(MPPasswordsViewController *self, NSNotification *note) {
                self->_fetchedResultsController = nil;
                PearlMainQueue( ^{
                    [self.passwordCollectionView reloadData];
                } );
            } );
    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresDidChangeNotification, nil, nil,
            ^(MPPasswordsViewController *self, NSNotification *note) {
                PearlMainQueue( ^{
                    [self updatePasswords];
                    [self registerObservers];
                } );
            } );

    NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForMainThreadIfReady];
    if (mainContext)
        PearlAddNotificationObserver( NSManagedObjectContextDidSaveNotification, mainContext, nil,
                ^(MPPasswordsViewController *self, NSNotification *note) {
                    if (![[MPiOSAppDelegate get] activeUserInContext:note.object])
                        [[MPiOSAppDelegate get] signOutAnimated:YES];
                } );
}

- (void)updateConfigKey:(NSString *)key {

    if (!key || [key isEqualToString:NSStringFromSelector( @selector( dictationSearch ) )])
        self.passwordsSearchBar.keyboardType = [[MPiOSConfig get].dictationSearch boolValue]? UIKeyboardTypeDefault: UIKeyboardTypeURL;
    if (!key || [key isEqualToString:NSStringFromSelector( @selector( hidePasswords ) )])
        [self.passwordCollectionView reloadData];
}

- (void)updatePasswords {

    NSManagedObjectID *activeUserOID = [MPiOSAppDelegate get].activeUserOID;
    if (!activeUserOID) {
        PearlMainQueue( ^{
            self.passwordsSearchBar.text = nil;
            [self.passwordCollectionView reloadData];
            [self.passwordCollectionView setContentOffset:CGPointMake( 0, -self.passwordCollectionView.contentInset.top ) animated:YES];
        } );
        return;
    }

    static NSRegularExpression *fuzzyRE;
    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        fuzzyRE = [NSRegularExpression regularExpressionWithPattern:@"(.)" options:0 error:nil];
    } );

    NSString *queryString = self.query;
    NSString *queryPattern;
    if ([queryString length] < 13)
        queryPattern = [queryString stringByReplacingMatchesOfExpression:fuzzyRE withTemplate:@"*$1*"];
    else
        // If query is too long, a wildcard per character makes the CoreData fetch take excessively long.
        queryPattern = strf( @"*%@*", queryString );
    NSMutableArray *fuzzyGroups = [NSMutableArray arrayWithCapacity:[queryString length]];
    [fuzzyRE enumerateMatchesInString:queryString options:0 range:NSMakeRange( 0, queryString.length )
                           usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                               [fuzzyGroups addObject:[queryString substringWithRange:result.range]];
                           }];
    _fuzzyGroups = fuzzyGroups;
    [self.fetchedResultsController.managedObjectContext performBlock:^{
        NSArray *oldSectionInfos = [self.fetchedResultsController sections];
        NSMutableArray *oldSections = [[NSMutableArray alloc] initWithCapacity:[oldSectionInfos count]];
        for (id<NSFetchedResultsSectionInfo> sectionInfo in oldSectionInfos)
            [oldSections addObject:[sectionInfo.objects copy]];

        NSError *error = nil;
        self.fetchedResultsController.fetchRequest.predicate =
                [NSPredicate predicateWithFormat:@"(%@ == '' OR name LIKE[cd] %@) AND user == %@",
                                                 queryPattern, queryPattern, activeUserOID];
        if (![self.fetchedResultsController performFetch:&error])
            err( @"Couldn't fetch sites: %@", [error fullDescription] );

        PearlMainQueue(^{
            @try {
                [self.passwordCollectionView performBatchUpdates:^{
                    [self fetchedItemsDidUpdate];
    
                    NSInteger fromSections = self.passwordCollectionView.numberOfSections;
                    NSInteger toSections = [self numberOfSectionsInCollectionView:self.passwordCollectionView];
                    for (NSInteger section = 0; section < MAX( toSections, fromSections ); ++section) {
                        if (section >= fromSections)
                            [self.passwordCollectionView insertSections:[NSIndexSet indexSetWithIndex:section]];
                        else if (section >= toSections)
                            [self.passwordCollectionView deleteSections:[NSIndexSet indexSetWithIndex:section]];
                        else if (section < [oldSections count])
                            [self.passwordCollectionView reloadItemsFromArray:oldSections[section]
                                                                      toArray:[[self.fetchedResultsController sections][section] objects]
                                                                    inSection:section];
                        else
                            [self.passwordCollectionView reloadSections:[NSIndexSet indexSetWithIndex:section]];
                    }
                }                                     completion:^(BOOL finished) {
                    if (finished)
                        [self.passwordCollectionView setContentOffset:CGPointMake( 0, -self.passwordCollectionView.contentInset.top )
                                                             animated:YES];
                    for (MPPasswordCell *cell in self.passwordCollectionView.visibleCells)
                        [cell setFuzzyGroups:_fuzzyGroups];
                }];
            }
            @catch (NSException *exception) {
                wrn( @"While updating password cells: %@", [exception fullDescription] );
                [self.passwordCollectionView reloadData];
            }
        });
    }];
}

#pragma mark - Properties

- (NSString *)query {

    return [self.passwordsSearchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (NSFetchedResultsController *)fetchedResultsController {

    if (!_fetchedResultsController) {
        _showTransientItem = NO;
        [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlockAndWait:^(NSManagedObjectContext *mainContext) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
            fetchRequest.sortDescriptors = @[
                    [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector( @selector( lastUsed ) ) ascending:NO]
            ];
            fetchRequest.fetchBatchSize = 10;
            _fetchedResultsController = [[NSFetchedResultsController alloc]
                    initWithFetchRequest:fetchRequest managedObjectContext:mainContext sectionNameKeyPath:nil cacheName:nil];
            _fetchedResultsController.delegate = self;
        }];
        [self registerObservers];
    }

    return _fetchedResultsController;
}

- (void)setActive:(BOOL)active {

    [self setActive:active animated:NO completion:nil];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated completion:(void ( ^ )(BOOL finished))completion {

    _active = active;

    [UIView animateWithDuration:animated? 0.4f: 0 animations:^{
        [self.navigationBarToTopConstraint updatePriority:active? 1: UILayoutPriorityDefaultHigh];
        [self.passwordsToBottomConstraint updatePriority:active? 1: UILayoutPriorityDefaultHigh];
        [self.view layoutIfNeeded];
    }                completion:completion];
}

#pragma mark - Actions

- (IBAction)dismissPopdown:(id)sender {

    if (_popdownVC)
        [[[MPPopdownSegue alloc] initWithIdentifier:@"unwind-popdown" source:_popdownVC destination:self] perform];
    else
        self.popdownToTopConstraint.priority = UILayoutPriorityDefaultHigh;
}

@end
