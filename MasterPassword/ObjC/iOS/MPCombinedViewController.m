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
#import "MPEntities.h"
#import "MPAvatarCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"

typedef NS_ENUM(NSUInteger, MPActiveUserState) {
    MPActiveUserStateNone,
    MPActiveUserStateLogin,
    MPActiveUserStateUserName,
    MPActiveUserStateMasterPasswordChoice,
    MPActiveUserStateMasterPasswordConfirmation,
};

@interface MPCombinedViewController()

@property(nonatomic) MPActiveUserState activeUserState;
@property(nonatomic, strong) NSArray *userIDs;
@end

@implementation MPCombinedViewController {
    __weak id _storeObserver;
    __weak id _mocObserver;
    NSArray *_notificationObservers;
    NSString *_masterPasswordChoice;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.avatarCollectionView.allowsMultipleSelection = YES;

    [self observeKeyPath:@"avatarCollectionView.contentOffset" withBlock:
            ^(id from, id to, NSKeyValueChange cause, MPCombinedViewController *_self) {
                [_self updateAvatars];
            }];

    self.mode = MPCombinedModeUserSelection;
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [self registerObservers];
    [self updateMode];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [self removeObservers];
    [self needStoreObserved:NO];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.entryField) {
        switch (self.activeUserState) {
            case MPActiveUserStateNone: {
                [textField resignFirstResponder];
                break;
            }
            case MPActiveUserStateLogin: {
                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    BOOL signedIn = NO, isNew = NO;
                    MPUserEntity *user = [self selectedUserInContext:context isNew:&isNew];
                    if (!isNew && user)
                        signedIn = [[MPiOSAppDelegate get] signInAsUser:user saveInContext:context
                                                    usingMasterPassword:self.entryField.text];

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (!signedIn) {
                            // Sign in failed.
                            // TODO: warn user
                            return;
                        }
                    }];
                }];
                break;
            }
            case MPActiveUserStateUserName: {
                NSString *userName = self.entryField.text;
                if (![userName length]) {
                    // No name entered.
                    // TODO: warn user
                    return NO;
                }

                [self selectedAvatar].name = userName;
                self.activeUserState = MPActiveUserStateMasterPasswordChoice;
                break;
            }
            case MPActiveUserStateMasterPasswordChoice: {
                NSString *masterPassword = self.entryField.text;
                if (![masterPassword length]) {
                    // No password entered.
                    // TODO: warn user
                    return NO;
                }

                self.activeUserState = MPActiveUserStateMasterPasswordConfirmation;
                break;
            }
            case MPActiveUserStateMasterPasswordConfirmation: {
                NSString *masterPassword = self.entryField.text;
                if (![masterPassword length]) {
                    // No password entered.
                    // TODO: warn user
                    return NO;
                }

                if (![masterPassword isEqualToString:_masterPasswordChoice]) {
                    // Master password confirmation failed.
                    // TODO: warn user
                    self.activeUserState = MPActiveUserStateMasterPasswordChoice;
                    return NO;
                }

                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    BOOL isNew = NO;
                    MPUserEntity *user = [self selectedUserInContext:context isNew:&isNew];
                    if (isNew) {
                        user = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass( [MPUserEntity class] )
                                                             inManagedObjectContext:context];
                        MPAvatarCell *avatarCell = [self selectedAvatar];
                        user.avatar = avatarCell.avatar;
                        user.name = avatarCell.name;
                    }

                    BOOL signedIn = [[MPiOSAppDelegate get] signInAsUser:user saveInContext:context usingMasterPassword:masterPassword];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (!signedIn) {
                            // Sign in failed, shouldn't happen for a new user.
                            // TODO: warn user
                            self.activeUserState = MPActiveUserStateNone;
                            return;
                        }
                    }];
                }];

                break;
            }
        }
    }

    return NO;
}

// This isn't really in UITextFieldDelegate.  We fake it from UITextFieldTextDidChangeNotification.
- (void)textFieldDidChange:(UITextField *)textField {

    if (textField == self.entryField) {
        switch (self.activeUserState) {
            case MPActiveUserStateNone:
                break;
            case MPActiveUserStateLogin:
                break;
            case MPActiveUserStateUserName: {
                NSString *userName = self.entryField.text;
                [self selectedAvatar].name = [userName length]? userName: strl( @"New User" );
                break;
            }
            case MPActiveUserStateMasterPasswordChoice:
                break;
            case MPActiveUserStateMasterPasswordConfirmation:
                break;
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == self.avatarCollectionView)
        return [self.userIDs count] + 1;

    else if (collectionView == self.passwordCollectionView)
        return 0;

    Throw(@"unexpected collection view: %@", collectionView);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.avatarCollectionView) {
        MPAvatarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MPAvatarCell reuseIdentifier] forIndexPath:indexPath];
        [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)]];
        [self updateAvatar:cell atIndexPath:indexPath];

        BOOL isNew = NO;
        MPUserEntity *user = [self userForIndexPath:indexPath inContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]
                                              isNew:&isNew];
        if (isNew) {
            // New User
            cell.avatar = MPAvatarAdd;
            cell.name = strl( @"New User" );
        }
        else {
            // Existing User
            cell.avatar = user.avatar;
            cell.name = user.name;
        }

        NSArray *selectedIndexPaths = [self.avatarCollectionView indexPathsForSelectedItems];
        if (![selectedIndexPaths count])
            cell.mode = MPAvatarModeLowered;
        else if ([selectedIndexPaths containsObject:indexPath])
            cell.mode = MPAvatarModeRaisedAndActive;
        else
            cell.mode = MPAvatarModeRaisedButInactive;

        return cell;
    }

    else if (collectionView == self.passwordCollectionView)
        return nil;

    Throw(@"unexpected collection view: %@", collectionView);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.avatarCollectionView) {
        [self.avatarCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                  animated:YES];

        [UIView animateWithDuration:0.3f animations:^{
            for (NSUInteger otherItem = 0; otherItem < [collectionView numberOfItemsInSection:indexPath.section]; ++otherItem)
                if (otherItem != indexPath.item) {
                    NSIndexPath *otherIndexPath = [NSIndexPath indexPathForItem:otherItem inSection:indexPath.section];
                    [collectionView deselectItemAtIndexPath:otherIndexPath animated:YES];

                    MPAvatarCell *otherCell = (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:otherIndexPath];
                    otherCell.mode = MPAvatarModeRaisedButInactive;
                }

            MPAvatarCell *cell = (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:indexPath];
            cell.mode = MPAvatarModeRaisedAndActive;
        }];

        BOOL isNew = NO;
        MPUserEntity *user = [self userForIndexPath:indexPath inContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]
                                              isNew:&isNew];
        if (isNew)
            self.activeUserState = MPActiveUserStateUserName;
        else if (!user.keyID)
            self.activeUserState = MPActiveUserStateMasterPasswordChoice;
        else
            self.activeUserState = MPActiveUserStateLogin;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.avatarCollectionView) {
        self.activeUserState = MPActiveUserStateNone;
    }
}

#pragma mark - UILongPressGestureRecognizer

- (void)didLongPress:(UILongPressGestureRecognizer *)recognizer {

    if ([recognizer.view isKindOfClass:[MPAvatarCell class]]) {
        if (recognizer.state != UIGestureRecognizerStateBegan)
                // Don't show the action menu unless the state is Began.
            return;

        MPAvatarCell *avatarCell = (MPAvatarCell *)recognizer.view;
        NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForMainThreadIfReady];

        BOOL isNew = NO;
        MPUserEntity *user = [self userForAvatar:avatarCell inContext:mainContext isNew:&isNew];
        NSManagedObjectID *userID = user.objectID;
        if (isNew || !user)
            return;

        [PearlSheet showSheetWithTitle:user.name
                             viewStyle:UIActionSheetStyleBlackTranslucent
                             initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
            if (buttonIndex == [sheet cancelButtonIndex])
                return;

            if (buttonIndex == [sheet destructiveButtonIndex]) {
                // Delete User
                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    NSManagedObject *user_ = [context existingObjectWithID:userID error:NULL];
                    if (user_) {
                        [context deleteObject:user_];
                        [context saveToStore];
                    }
                }];
                return;
            }

            if (buttonIndex == [sheet firstOtherButtonIndex])
                    // Reset Password
                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPUserEntity *user_ = (MPUserEntity *)[context existingObjectWithID:userID error:NULL];
                    if (user_)
                        [[MPiOSAppDelegate get] changeMasterPasswordFor:user_ saveInContext:context didResetBlock:^{
                            dbg(@"changing mp for user: %@, keyID: %@", user_.name, user_.keyID);
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                NSIndexPath *avatarIndexPath = [self.avatarCollectionView indexPathForCell:avatarCell];
                                [self.avatarCollectionView selectItemAtIndexPath:avatarIndexPath animated:NO
                                                                  scrollPosition:UICollectionViewScrollPositionNone];
                                [self collectionView:self.avatarCollectionView didSelectItemAtIndexPath:avatarIndexPath];
                            }];
                        }];
                }];
        }                  cancelTitle:[PearlStrings get].commonButtonCancel
                      destructiveTitle:@"Delete User" otherTitles:@"Reset Password", nil];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    if (scrollView == self.avatarCollectionView) {
        CGPoint offsetToCenter = CGPointMake(
                self.avatarCollectionView.bounds.size.width / 2,
                self.avatarCollectionView.bounds.size.height / 2 );
        NSIndexPath *avatarIndexPath = [self.avatarCollectionView indexPathForItemAtPoint:
                CGPointPlusCGPoint( *targetContentOffset, offsetToCenter )];
        CGPoint targetCenter = [self.avatarCollectionView layoutAttributesForItemAtIndexPath:avatarIndexPath].center;
        *targetContentOffset = CGPointMinusCGPoint( targetCenter, offsetToCenter );
        NSAssert([self.avatarCollectionView indexPathForItemAtPoint:targetCenter].item == avatarIndexPath.item, @"should be same item");
    }
}

- (MPAvatarCell *)selectedAvatar {

    NSArray *selectedIndexPaths = self.avatarCollectionView.indexPathsForSelectedItems;
    if (![selectedIndexPaths count]) {
        // No selected user.
        return nil;
    }

    return (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:selectedIndexPaths.firstObject];
}

- (MPUserEntity *)selectedUserInContext:(NSManagedObjectContext *)context isNew:(BOOL *)isNew {

    MPAvatarCell *selectedAvatar = [self selectedAvatar];
    if (!selectedAvatar) {
        // No selected user.
        *isNew = NO;
        return nil;
    }

    return [self userForAvatar:selectedAvatar inContext:context isNew:isNew];
}

- (MPUserEntity *)userForAvatar:(MPAvatarCell *)cell inContext:(NSManagedObjectContext *)context isNew:(BOOL *)isNew {

    return [self userForIndexPath:[self.avatarCollectionView indexPathForCell:cell] inContext:context isNew:isNew];
}

- (MPUserEntity *)userForIndexPath:(NSIndexPath *)indexPath inContext:(NSManagedObjectContext *)context isNew:(BOOL *)isNew {

    if ((*isNew = indexPath.item >= [self.userIDs count]))
        return nil;

    NSError *error = nil;
    MPUserEntity *user = (MPUserEntity *)[context existingObjectWithID:self.userIDs[indexPath.item] error:&error];
    if (error)
    wrn(@"Failed to load user into context: %@", error);

    return user;
}

- (void)updateAvatars {

    for (NSIndexPath *indexPath in self.avatarCollectionView.indexPathsForVisibleItems)
        [self updateAvatarAtIndexPath:indexPath];
}

- (void)updateAvatarAtIndexPath:(NSIndexPath *)indexPath {

    MPAvatarCell *cell = (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:indexPath];
    [self updateAvatar:cell atIndexPath:indexPath];
}

- (void)updateAvatar:(MPAvatarCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    CGFloat current = [self.avatarCollectionView layoutAttributesForItemAtIndexPath:indexPath].center.x -
                      self.avatarCollectionView.contentOffset.x;
    CGFloat max = self.avatarCollectionView.bounds.size.width;
    cell.visibility = MAX(0, MIN( 1, 1 - ABS( current / (max / 2) - 1 ) ));
}

- (void)registerObservers {

    if ([_notificationObservers count])
        return;

    Weakify(self);
    _notificationObservers = @[
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:UIApplicationWillResignActiveNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

//                [self emergencyCloseAnimated:NO];
                self.userSelectionContainer.alpha = 0;
                self.passwordSelectionContainer.alpha = 0;
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:UIApplicationDidBecomeActiveNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                [self updateMode];
                [UIView animateWithDuration:1 animations:^{
                    self.userSelectionContainer.alpha = 1;
                    self.passwordSelectionContainer.alpha = 1;
                }];
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:MPSignedInNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                self.mode = MPCombinedModePasswordSelection;
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:MPSignedOutNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                self.mode = MPCombinedModeUserSelection;
            }],
            [[NSNotificationCenter defaultCenter]
                    addObserverForName:UITextFieldTextDidChangeNotification object:self.entryField
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                Strongify(self);

                [self textFieldDidChange:note.object];
            }],
    ];
}

- (void)removeObservers {

    for (id observer in _notificationObservers)
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    _notificationObservers = nil;
}

- (void)needStoreObserved:(BOOL)observeStore {

    if (observeStore) {
        Weakify(self);

        NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForMainThreadIfReady];
        if (!_mocObserver && mainContext)
            _mocObserver = [[NSNotificationCenter defaultCenter]
                    addObserverForName:NSManagedObjectContextObjectsDidChangeNotification object:mainContext
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                        Strongify(self);
                        [self updateMode];
                    }];
        if (!_storeObserver)
            _storeObserver = [[NSNotificationCenter defaultCenter]
                    addObserverForName:USMStoreDidChangeNotification object:nil
                                 queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
                        Strongify(self);
                        [self updateMode];
                    }];
    }
    if (!observeStore) {
        if (_mocObserver)
            [[NSNotificationCenter defaultCenter] removeObserver:_mocObserver];
        if (_storeObserver)
            [[NSNotificationCenter defaultCenter] removeObserver:_storeObserver];
    }
}

- (void)setUserIDs:(NSArray *)userIDs {

    _userIDs = userIDs;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.avatarCollectionView reloadData];
    }];
}

- (void)setMode:(MPCombinedMode)mode {

    _mode = mode;

    [self updateMode];
}

- (void)updateMode {

    // Ensure we're on the main thread.
    if (![NSThread isMainThread]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateMode];
        }];
        return;
    }

    self.userSelectionContainer.hidden = YES;
    self.passwordSelectionContainer.hidden = YES;

    [self becomeFirstResponder];

    switch (self.mode) {
        case MPCombinedModeUserSelection: {
            [[self navigationController] setNavigationBarHidden:YES animated:YES];
            self.userSelectionContainer.hidden = NO;
            [self needStoreObserved:YES];

            [self setActiveUserState:MPActiveUserStateNone animated:NO];
            [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                NSError *error = nil;
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
                fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO] ];
                NSArray *users = [context executeFetchRequest:fetchRequest error:&error];
                if (!users) {
                    err(@"Failed to load users: %@", error);
                    self.userIDs = nil;
                }

                NSMutableArray *userIDs = [NSMutableArray arrayWithCapacity:[users count]];
                for (MPUserEntity *user in users)
                    [userIDs addObject:user.objectID];
                self.userIDs = userIDs;
            }];

            break;
        }
        case MPCombinedModePasswordSelection: {
            [[self navigationController] setNavigationBarHidden:NO animated:YES];
            self.passwordSelectionContainer.hidden = NO;
            [self needStoreObserved:NO];
            break;
        }
    }
}

- (void)setActiveUserState:(MPActiveUserState)activeUserState {

    [self setActiveUserState:activeUserState animated:YES];
}

- (void)setActiveUserState:(MPActiveUserState)activeUserState animated:(BOOL)animated {

    _activeUserState = activeUserState;
    _masterPasswordChoice = nil;

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        // Set the entry container's contents.
        switch (activeUserState) {
            case MPActiveUserStateNone: {
                for (NSUInteger item = 0; item < [self.avatarCollectionView numberOfItemsInSection:0]; ++item) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:0];
                    [self.avatarCollectionView deselectItemAtIndexPath:indexPath animated:YES];

                    MPAvatarCell *avatarCell = (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:indexPath];
                    avatarCell.mode = MPAvatarModeLowered;
                }
                break;
            }
            case MPActiveUserStateLogin: {
                self.entryField.text = strl( @"Enter your master password:" );
                self.entryField.text = nil;
                self.entryField.secureTextEntry = YES;
                break;
            }
            case MPActiveUserStateUserName: {
                self.entryLabel.text = strl( @"Enter your full name:" );
                self.entryField.text = nil;
                self.entryField.secureTextEntry = NO;
                break;
            }
            case MPActiveUserStateMasterPasswordChoice: {
                self.entryLabel.text = strl( @"Choose your master password:" );
                self.entryField.text = nil;
                self.entryField.secureTextEntry = YES;
                break;
            }
            case MPActiveUserStateMasterPasswordConfirmation: {
                _masterPasswordChoice = self.entryField.text;
                self.entryLabel.text = strl( @"Confirm your master password:" );
                self.entryField.text = nil;
                self.entryField.secureTextEntry = YES;
                break;
            }
        }

        // Manage the random avatar for the new user if selected.
        MPAvatarCell *selectedAvatar = [self selectedAvatar];
        if (selectedAvatar.avatar == MPAvatarAdd) {
            selectedAvatar.avatar = arc4random() % MPAvatarCount;
        }
        else {
            NSIndexPath *newUserIndexPath = [NSIndexPath indexPathForItem:[_userIDs count] inSection:0];
            MPAvatarCell *newUserAvatar = (MPAvatarCell *)[[self avatarCollectionView] cellForItemAtIndexPath:newUserIndexPath];
            newUserAvatar.avatar = MPAvatarAdd;
            newUserAvatar.name = strl( @"New User" );
        }

        // Manage the entry container depending on whether a user is activate or not.
        if (activeUserState == MPActiveUserStateNone) {
            self.avatarCollectionCenterConstraint.priority = UILayoutPriorityDefaultHigh;
            self.entryContainer.alpha = 0;
        }
        else {
            self.avatarCollectionCenterConstraint.priority = UILayoutPriorityDefaultLow;
            self.entryContainer.alpha = 1;
        }
        [self.avatarCollectionCenterConstraint apply];

        // Toggle the keyboard.
        if (activeUserState == MPActiveUserStateNone)
            [self.entryField resignFirstResponder];
    }                completion:^(BOOL finished) {
        if (activeUserState != MPActiveUserStateNone)
            [self.entryField becomeFirstResponder];
    }];
}

- (IBAction)doSignOut:(UIBarButtonItem *)sender {

    [[MPiOSAppDelegate get] signOutAnimated:YES];
}

@end
