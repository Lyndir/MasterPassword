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

#import "MPPasswordsViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPPopdownSegue.h"
#import "MPAppDelegate_Key.h"
#import "MPPasswordCell.h"
#import "MPAnswersViewController.h"
#import "MPMessageViewController.h"

static const NSString *MPTransientPasswordItem = @"MPTransientPasswordItem";

typedef NS_OPTIONS( NSUInteger, MPPasswordsTips ) {
    MPPasswordsBadNameTip = 1 << 0,
};

@interface MPPasswordsViewController()<NSFetchedResultsControllerDelegate>

@property(nonatomic, strong) IBOutlet UINavigationBar *navigationBar;

@end

@implementation MPPasswordsViewController {
    __weak UITapGestureRecognizer *_passwordsDismissRecognizer;
    NSFetchedResultsController *_fetchedResultsController;
    UIColor *_backgroundColor;
    UIColor *_darkenedBackgroundColor;
    __weak UIViewController *_popdownVC;
    NSCharacterSet *_siteNameAcceptableCharactersSet;
    NSArray *_fuzzyGroups;
    NSMutableArray<NSMutableArray *> *_passwordCollectionSections;
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
    _passwordCollectionSections = [NSMutableArray new];

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
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
        if (![MPAlgorithmDefault tryMigrateUser:activeUser inContext:context])
            PearlMainQueue( ^{
                [self performSegueWithIdentifier:@"message" sender:
                        [MPMessage messageWithTitle:@"You have sites that can be upgraded." text:
                                        @"Upgrading a site allows it to take advantage of the latest improvements in the Master Password algorithm.\n\n"
                                                "When you upgrade a site, a new and stronger password will be generated for it.  To upgrade a site, first log into the site, navigate to your account preferences where you can change the site's password.  Make sure you fill in any \"current password\" fields on the website first, then press the upgrade button here to get your new site password.\n\n"
                                                "You can then update your site's account with the new and stronger password.\n\n"
                                                "The upgrade button can be found in the site's settings and looks like this:"
                                               info:YES]];
            } );
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [self.passwordCollectionView.collectionViewLayout invalidateLayout];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
    CGFloat itemWidth = UIEdgeInsetsInsetRect( collectionView.bounds, layout.sectionInset ).size.width;
    return CGSizeMake( itemWidth, 100 );
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {

    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)collectionViewLayout;
    UIEdgeInsets occludedInsets = [self.passwordCollectionView occludedInsets];
    UIEdgeInsets insets = layout.sectionInset;
    insets.top = insets.bottom; // Undo storyboard hack for manual top-occluded insets.

    if (section == 0)
        insets.top += occludedInsets.top;

    if (section == collectionView.numberOfSections - 1)
        insets.bottom += occludedInsets.bottom;

    return insets;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {

    return [_passwordCollectionSections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return [_passwordCollectionSections[(NSUInteger)section] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MPPasswordCell *cell = [MPPasswordCell dequeueCellFromCollectionView:collectionView indexPath:indexPath];
    [cell setFuzzyGroups:_fuzzyGroups];
    id item = _passwordCollectionSections[(NSUInteger)indexPath.section][(NSUInteger)indexPath.item];
    if ([item isKindOfClass:[MPSiteEntity class]])
        [cell setSite:item animated:NO];
    else // item == MPTransientPasswordItem
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

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {

    if (controller == _fetchedResultsController)
        PearlMainQueue( ^{
            [self.passwordCollectionView updateDataSource:_passwordCollectionSections
                                               toSections:[self createPasswordCollectionSections]
                                              reloadItems:nil completion:nil];
        } );
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

        [self reloadPasswords];
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

        [self reloadPasswords];
    }
}

#pragma mark - Private

- (void)showTips:(MPPasswordsTips)showTips {

    [UIView animateWithDuration:0.3f animations:^{
        if (showTips & MPPasswordsBadNameTip)
            self.badNameTipContainer.visible = YES;
    }                completion:^(BOOL finished) {
        PearlMainQueueAfter( 5, ^{
            [UIView animateWithDuration:0.3f animations:^{
                if (showTips & MPPasswordsBadNameTip)
                    self.badNameTipContainer.visible = NO;
            }];
        } );
    }];
}

- (NSMutableArray<NSMutableArray *> *)createPasswordCollectionSections {

    NSString *query = self.query;
    BOOL needTransientItem = [query length] > 0;

    NSArray<id<NSFetchedResultsSectionInfo>> *sectionInfos = [self.fetchedResultsController sections];
    NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:[sectionInfos count]];
    for (id<NSFetchedResultsSectionInfo> sectionInfo in sectionInfos) {
        NSArray<MPSiteEntity *> *sites = [sectionInfo.objects copy];
        [sections addObject:sites];

        if (needTransientItem)
            for (MPSiteEntity *site in sites)
                if ([site.name isEqualToString:query]) {
                    needTransientItem = NO;
                    break;
                }
    }

    if (needTransientItem)
        [sections addObject:@[ MPTransientPasswordItem ]];

    return sections;
}

- (void)registerObservers {

    static NSRegularExpression *bareHostRE = nil;
    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        bareHostRE = [NSRegularExpression regularExpressionWithPattern:@"([^\\.]+\\.[^\\.]+)$" options:0 error:nil];
    } );

    PearlRemoveNotificationObservers();
    PearlAddNotificationObserver( UIApplicationWillResignActiveNotification, nil, [NSOperationQueue mainQueue],
            ^(MPPasswordsViewController *self, NSNotification *note) {
                [self.view endEditing:YES];
                self.passwordSelectionContainer.visible = NO;
            } );
    PearlAddNotificationObserver( UIApplicationDidBecomeActiveNotification, nil, [NSOperationQueue mainQueue],
            ^(MPPasswordsViewController *self, NSNotification *note) {
                NSURL *pasteboardURL = nil;
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                if ([pasteboard respondsToSelector:@selector( hasURLs )])
                    pasteboardURL = pasteboard.hasURLs? pasteboard.URL: nil;
                else
                    pasteboardURL = [NSURL URLWithString:pasteboard.string];

                if (pasteboardURL.host)
                    self.query = NSNullToNil( [pasteboardURL.host firstMatchGroupsOfExpression:bareHostRE][0] );
                else
                    [self reloadPasswords];

                [UIView animateWithDuration:0.7f animations:^{
                    self.passwordSelectionContainer.visible = YES;
                }];
            } );
    PearlAddNotificationObserver( MPSignedOutNotification, nil, nil,
            ^(MPPasswordsViewController *self, NSNotification *note) {
                PearlMainQueue( ^{
                    self->_fetchedResultsController = nil;
                    self.query = nil;
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
                [self reloadPasswords];
            } );
    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresDidChangeNotification, nil, nil,
            ^(MPPasswordsViewController *self, NSNotification *note) {
                PearlMainQueue( ^{
                    [self reloadPasswords];
                    [self registerObservers];
                } );
            } );

    [MPiOSAppDelegate managedObjectContextChanged:^(NSDictionary<NSManagedObjectID *, NSString *> *affectedObjects) {
        [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
            // TODO: either move this into the app delegate or remove the duplicate signOutAnimated: call from the app delegate.
            if (![[MPiOSAppDelegate get] activeUserInContext:mainContext])
                [[MPiOSAppDelegate get] signOutAnimated:YES];
        }];
    }];
}

- (void)updateConfigKey:(NSString *)key {

    if (!key || [key isEqualToString:NSStringFromSelector( @selector( dictationSearch ) )])
        self.passwordsSearchBar.keyboardType = [[MPiOSConfig get].dictationSearch boolValue]? UIKeyboardTypeDefault: UIKeyboardTypeURL;
    if (!key || [key isEqualToString:NSStringFromSelector( @selector( hidePasswords ) )])
        [self.passwordCollectionView reloadData];
}

- (void)reloadPasswords {

    [self.fetchedResultsController.managedObjectContext performBlock:^{
        static NSRegularExpression *fuzzyRE;
        static dispatch_once_t once = 0;
        dispatch_once( &once, ^{
            fuzzyRE = [NSRegularExpression regularExpressionWithPattern:@"(.)" options:0 error:nil];
        } );

        NSString *queryString = self.query;
        NSString *queryPattern = [[queryString stringByReplacingMatchesOfExpression:fuzzyRE withTemplate:@"*$1"]
                stringByAppendingString:@"*"];
        NSMutableArray *fuzzyGroups = [NSMutableArray new];
        [fuzzyRE enumerateMatchesInString:queryString options:0 range:NSMakeRange( 0, queryString.length )
                               usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                   [fuzzyGroups addObject:[queryString substringWithRange:result.range]];
                               }];
        _fuzzyGroups = fuzzyGroups;

        NSError *error = nil;
        self.fetchedResultsController.fetchRequest.predicate =
                [NSPredicate predicateWithFormat:@"name LIKE[cd] %@ AND user == %@", queryPattern, [MPiOSAppDelegate get].activeUserOID];
        if (![self.fetchedResultsController performFetch:&error])
            MPError( error, @"Couldn't fetch sites." );

        PearlMainQueue( ^{
            [self.passwordCollectionView updateDataSource:_passwordCollectionSections
                                               toSections:[self createPasswordCollectionSections]
                                              reloadItems:@[ MPTransientPasswordItem ] completion:^(BOOL finished) {
                        for (MPPasswordCell *cell in self.passwordCollectionView.visibleCells)
                            [cell setFuzzyGroups:_fuzzyGroups];
                    }];
        } );
    }];
}

#pragma mark - Properties

- (NSString *)query {

    return [self.passwordsSearchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

- (void)setQuery:(NSString *)query {

    self.passwordsSearchBar.text = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self reloadPasswords];
}

- (NSFetchedResultsController *)fetchedResultsController {

    if (!_fetchedResultsController) {
        [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlockAndWait:^(NSManagedObjectContext *mainContext) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPSiteEntity class] )];
            fetchRequest.sortDescriptors = @[
                    [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector( @selector( lastUsed ) ) ascending:NO]
            ];
            fetchRequest.fetchBatchSize = 10;
            _fetchedResultsController =
                    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:mainContext
                                                          sectionNameKeyPath:nil cacheName:nil];
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
