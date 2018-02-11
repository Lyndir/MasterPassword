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

#import <Crashlytics/Answers.h>
#import "MPUsersViewController.h"
#import "MPEntities.h"
#import "MPAvatarCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"
#import "MPWebViewController.h"

typedef NS_OPTIONS( NSUInteger, MPUsersTips ) {
    MPUsersThanksTip = 1 << 0,
    MPUsersAvatarTip = 1 << 1,
    MPUsersMasterPasswordTip = 1 << 2,
    MPUsersPreferencesTip = 1 << 3,
};

typedef NS_ENUM( NSUInteger, MPActiveUserState ) {
    /** The users are all inactive */
            MPActiveUserStateNone,
    /** The selected user is activated and being logged in with */
            MPActiveUserStateLogin,
    /** The selected user is activated and its user name is being asked for */
            MPActiveUserStateUserName,
    /** The selected user is activated and its new master password is being asked for */
            MPActiveUserStateMasterPasswordChoice,
    /** The selected user is activated and the confirmation of the previously entered master password is being asked for */
            MPActiveUserStateMasterPasswordConfirmation,
    /** The selected user is activated displayed at the top with the rest of the UI inactive */
            MPActiveUserStateMinimized,
};

@interface MPUsersViewController()

@property(nonatomic) MPActiveUserState activeUserState;
@property(nonatomic, strong) NSArray *userIDs;
@property(nonatomic, strong) NSTimer *marqueeTipTimer;
@property(nonatomic, strong) NSArray *marqueeTipTexts;
@property(nonatomic) NSUInteger marqueeTipTextIndex;
@property(nonatomic, copy) NSString *masterPasswordChoice;
@property(nonatomic, strong) NSOperationQueue *afterUpdates;
@property(nonatomic, weak) id contextChangedObserver;

@end

@implementation MPUsersViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.afterUpdates = [NSOperationQueue new];

    self.marqueeTipTexts = @[
            strl( @"Thanks, lhunath ➚" ),
            strl( @"Press and hold to delete or reset user." ),
            strl( @"Shake for emergency generator." ),
    ];

    self.view.backgroundColor = [UIColor clearColor];
    self.avatarCollectionView.allowsMultipleSelection = YES;
    [self.entryField addTarget:self action:@selector( textFieldEditingChanged: ) forControlEvents:UIControlEventEditingChanged];

    self.preferencesTipContainer.visible = NO;

    [self setActive:YES animated:NO];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"tipped.thanks"])
        [self showTips:MPUsersThanksTip];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.userSelectionContainer.visible = NO;
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [self registerObservers];
    [self reloadUsers];

    [self.marqueeTipTimer invalidate];
    self.marqueeTipTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector( firedMarqueeTimer: )
                                                          userInfo:nil repeats:YES];
    [self firedMarqueeTimer:nil];
}

- (void)viewWillLayoutSubviews {

    [self.avatarCollectionView.collectionViewLayout invalidateLayout];
    [super viewWillLayoutSubviews];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [self.avatarCollectionView.collectionViewLayout invalidateLayout];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"thanks"])
        ((MPWebViewController *)segue.destinationViewController).initialURL =
                [NSURL URLWithString:@"https://thanks.lhunath.com"];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [self removeObservers];

    [self.marqueeTipTimer invalidate];
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
                self.entryField.enabled = NO;
                [self selectedAvatar].spinnerActive = YES;
                NSString *masterPassword = self.entryField.text;
                if (![MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    BOOL signedIn = NO, isNew = NO;
                    MPUserEntity *user = [self selectedUserInContext:context isNew:&isNew];
                    if (!isNew && user)
                        signedIn = [[MPiOSAppDelegate get] signInAsUser:user saveInContext:context
                                                    usingMasterPassword:masterPassword];

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        self.entryField.text = @"";
                        self.entryField.enabled = YES;
                        [self selectedAvatar].spinnerActive = NO;

                        if (!signedIn) {
                            // Sign in failed.
                            [self showEntryTip:strl( @"Looks like a typo!\nTry again; that password was incorrect." )];
                            return;
                        }
                    }];
                }]) {
                    self.entryField.enabled = YES;
                    [self selectedAvatar].spinnerActive = NO;
                }
                break;
            }
            case MPActiveUserStateUserName: {
                NSString *userName = self.entryField.text;
                if (![userName length]) {
                    // No name entered.
                    [self showEntryTip:strl( @"First, enter your name." )];
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
                    [self showEntryTip:strl( @"Pick a master password." )];
                    return NO;
                }

                self.activeUserState = MPActiveUserStateMasterPasswordConfirmation;
                break;
            }
            case MPActiveUserStateMasterPasswordConfirmation: {
                NSString *masterPassword = self.entryField.text;
                if (![masterPassword length]) {
                    // No password entered.
                    [self showEntryTip:strl( @"Confirm your master password." )];
                    return NO;
                }

                if (![masterPassword isEqualToString:self.masterPasswordChoice]) {
                    // Master password confirmation failed.
                    [self showEntryTip:strl( @"Looks like a typo!\nTry again; enter your master password twice." )];
                    self.activeUserState = MPActiveUserStateMasterPasswordChoice;
                    return NO;
                }

                self.entryField.enabled = NO;
                MPAvatarCell *avatarCell = [self selectedAvatar];
                avatarCell.spinnerActive = YES;
                NSUInteger newUserAvatar = avatarCell.avatar;
                NSString *newUserName = avatarCell.name;
                if (![MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    BOOL isNew = NO;
                    MPUserEntity *user = [self userForAvatar:avatarCell inContext:context isNew:&isNew];
                    if (isNew) {
                        user = [MPUserEntity insertNewObjectInContext:context];
                        user.algorithm = MPAlgorithmDefault;
                        user.defaultType = user.algorithm.defaultType;
                        user.avatar = newUserAvatar;
                        user.name = newUserName;

                        if ([[MPConfig get].sendInfo boolValue]) {
#ifdef CRASHLYTICS
                            [Answers logSignUpWithMethod:@"Manual"
                                                 success:@YES
                                        customAttributes:@{
                                                @"algorithm": @(user.algorithm.version),
                                                @"avatar"   : @(user.avatar),
                                        }];
#endif
                        }
                    }

                    BOOL signedIn = [[MPiOSAppDelegate get] signInAsUser:user saveInContext:context
                                                     usingMasterPassword:masterPassword];
                    PearlMainQueue( ^{
                        self.entryField.text = @"";
                        self.entryField.enabled = YES;
                        avatarCell.spinnerActive = NO;

                        if (!signedIn) {
                            // Sign in failed, shouldn't happen for a new user.
                            [self showEntryTip:strl( @"Couldn't create new user." )];
                            self.activeUserState = MPActiveUserStateNone;
                            return;
                        }
                    } );
                }]) {
                    self.entryField.enabled = YES;
                    avatarCell.spinnerActive = NO;
                }

                break;
            }
            case MPActiveUserStateMinimized: {
                [textField resignFirstResponder];
                break;
            }
        }
    }

    return NO;
}

// This isn't really in UITextFieldDelegate.  We fake it from UITextFieldTextDidChangeNotification.
- (void)textFieldEditingChanged:(UITextField *)textField {

    if ([[textField.text lowercaseString] isEqualToString:@"hangtest"])
        [NSThread sleepForTimeInterval:10];

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
            case MPActiveUserStateMinimized:
                break;
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)       collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section {

    CGSize parentSize = self.avatarCollectionView.bounds.size;
    return CGSizeMake( parentSize.width / 4, parentSize.height );
}

- (CGSize)       collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section {

    CGSize parentSize = self.avatarCollectionView.bounds.size;
    return CGSizeMake( parentSize.width / 4, parentSize.height );
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    CGSize parentSize = self.avatarCollectionView.bounds.size;
    return CGSizeMake( parentSize.width / 2, parentSize.height );
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (collectionView == self.avatarCollectionView)
        return [self.userIDs count] + 1;

    Throw( @"unexpected collection view: %@", collectionView );
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.avatarCollectionView) {
        MPAvatarCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[MPAvatarCell reuseIdentifier] forIndexPath:indexPath];
        cell.contentView.frame = cell.bounds;
        [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( didLongPress: )]];
        [self updateModeForAvatar:cell atIndexPath:indexPath animated:NO];
        [self updateVisibilityForAvatar:cell atIndexPath:indexPath animated:NO];

        BOOL isNew = NO;
        MPUserEntity *user = [self userForIndexPath:indexPath inContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]
                                              isNew:&isNew];
        if (isNew)
            // New User
            cell.avatar = MPAvatarAdd;
        else {
            // Existing User
            cell.avatar = user.avatar;
            cell.name = user.name;
        }

        return cell;
    }

    Throw( @"unexpected collection view: %@", collectionView );
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.avatarCollectionView) {
        [self.avatarCollectionView scrollToItemAtIndexPath:indexPath
                                          atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];

        // Deselect all other cells.
        for (NSUInteger otherItem = 0; otherItem < [collectionView numberOfItemsInSection:indexPath.section]; ++otherItem)
            if (otherItem != indexPath.item) {
                NSIndexPath *otherIndexPath = [NSIndexPath indexPathForItem:otherItem inSection:indexPath.section];
                [collectionView deselectItemAtIndexPath:otherIndexPath animated:YES];
            }

        BOOL isNew = NO;
        NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForMainThreadIfReady];
        MPUserEntity *mainUser = [self userForIndexPath:indexPath inContext:mainContext isNew:&isNew];

        if (isNew)
            self.activeUserState = MPActiveUserStateUserName;
        else if (!mainUser.keyID)
            self.activeUserState = MPActiveUserStateMasterPasswordChoice;
        else {
            self.activeUserState = MPActiveUserStateLogin;

            self.entryField.enabled = NO;
            MPAvatarCell *userAvatar = [self selectedAvatar];
            userAvatar.spinnerActive = YES;
            if (!isNew && mainUser && [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                MPUserEntity *user = [MPUserEntity existingObjectWithID:mainUser.permanentObjectID inContext:context];
                BOOL signedIn = [[MPiOSAppDelegate get] signInAsUser:user saveInContext:context usingMasterPassword:nil];

                PearlMainQueue( ^{
                    self.entryField.text = @"";
                    self.entryField.enabled = YES;
                    userAvatar.spinnerActive = NO;

                    if (!signedIn)
                        [self.entryField becomeFirstResponder];
                } );
            }])
                return;

            self.entryField.text = @"";
            self.entryField.enabled = YES;
            userAvatar.spinnerActive = NO;

            [self.entryField becomeFirstResponder];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {

    if (collectionView == self.avatarCollectionView)
        self.activeUserState = MPActiveUserStateNone;
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
        if (isNew || !user)
            return;

        NSManagedObjectID *userID = user.permanentObjectID;
        [PearlSheet showSheetWithTitle:user.name
                             viewStyle:UIActionSheetStyleBlackTranslucent
                             initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                    if (buttonIndex == [sheet cancelButtonIndex])
                        return;

                    if (buttonIndex == [sheet destructiveButtonIndex]) {
                        // Delete User
                        [PearlAlert showParentalGateWithTitle:@"Deleting User" message:
                                        @"The user and its sites will be deleted.\nPlease confirm by solving:"
                                                   completion:^(BOOL continuing) {
                                                       if (continuing)
                                                           [self deleteUser:userID];
                                                   }];
                        return;
                    }

                    if (buttonIndex == [sheet firstOtherButtonIndex])
                        // Reset Password
                        [PearlAlert showParentalGateWithTitle:@"Resetting User" message:
                                        @"The user's master password will be reset.\nPlease confirm by solving:"
                                                   completion:^(BOOL continuing) {
                                                       if (continuing)
                                                           [self resetUser:userID avatar:avatarCell];
                                                   }];
                }          cancelTitle:[PearlStrings get].commonButtonCancel
                      destructiveTitle:@"Delete User" otherTitles:@"Reset Password", nil];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    if (scrollView == self.avatarCollectionView) {
        CGPoint offsetToCenter = self.avatarCollectionView.center;
        NSIndexPath *avatarIndexPath = [self.avatarCollectionView indexPathForItemAtPoint:
                CGPointPlusCGPoint( *targetContentOffset, offsetToCenter )];
        CGPoint targetCenter = [self.avatarCollectionView layoutAttributesForItemAtIndexPath:avatarIndexPath].center;
        *targetContentOffset = CGPointMinusCGPoint( targetCenter, offsetToCenter );
        NSAssert( [self.avatarCollectionView indexPathForItemAtPoint:targetCenter].item == avatarIndexPath.item, @"should be same item" );
    }
}

#pragma mark - Private

- (void)deleteUser:(NSManagedObjectID *)userID {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *user = [MPUserEntity existingObjectWithID:userID inContext:context];
        if (!user)
            return;

        [context deleteObject:user];
        [context saveToStore];
    }];
}

- (void)resetUser:(NSManagedObjectID *)userID avatar:(MPAvatarCell *)avatarCell {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *user = [MPUserEntity existingObjectWithID:userID inContext:context];
        if (!user)
            return;

        [[MPiOSAppDelegate get] changeMasterPasswordFor:user saveInContext:context didResetBlock:^{
            PearlMainQueue( ^{
                NSIndexPath *avatarIndexPath = [self.avatarCollectionView indexPathForCell:avatarCell];
                [self.avatarCollectionView selectItemAtIndexPath:avatarIndexPath animated:NO
                                                  scrollPosition:UICollectionViewScrollPositionNone];
                [self collectionView:self.avatarCollectionView didSelectItemAtIndexPath:avatarIndexPath];
            } );
        }];
    }];
}

- (void)showTips:(MPUsersTips)showTips {

    [UIView animateWithDuration:0.3f animations:^{
        if (showTips & MPUsersThanksTip)
            self.thanksTipContainer.visible = YES;
        if (showTips & MPUsersAvatarTip)
            self.avatarTipContainer.visible = YES;
        if (showTips & MPUsersMasterPasswordTip)
            self.entryTipContainer.visible = YES;
        if (showTips & MPUsersPreferencesTip)
            self.preferencesTipContainer.visible = YES;
    }                completion:^(BOOL finished) {
        if (finished)
            PearlMainQueueAfter( 5, ^{
                [UIView animateWithDuration:0.3f animations:^{
                    if (showTips & MPUsersThanksTip)
                        self.thanksTipContainer.visible = NO;
                    if (showTips & MPUsersAvatarTip)
                        self.avatarTipContainer.visible = NO;
                    if (showTips & MPUsersMasterPasswordTip)
                        self.entryTipContainer.visible = NO;
                    if (showTips & MPUsersPreferencesTip)
                        self.preferencesTipContainer.visible = NO;
                }];
            } );
    }];
}

- (void)showEntryTip:(NSString *)message {

    NSUInteger newlineIndex = [message rangeOfString:@"\n"].location;
    NSString *messageTitle = newlineIndex == NSNotFound? message: [message substringToIndex:newlineIndex];
    NSString *messageSubtitle = newlineIndex == NSNotFound? nil: [message substringFromIndex:newlineIndex];
    self.entryTipTitleLabel.text = messageTitle;
    self.entryTipSubtitleLabel.text = messageSubtitle;
    [self showTips:MPUsersMasterPasswordTip];
}

- (void)firedMarqueeTimer:(NSTimer *)timer {

    NSString *nextMarqueeString = self.marqueeTipTexts[self.marqueeTipTextIndex++ % [self.marqueeTipTexts count]];
    if ([nextMarqueeString isEqualToString:[self.marqueeButton titleForState:UIControlStateNormal]])
        return;

    [UIView animateWithDuration:timer? 0.5f: 0 animations:^{
        self.marqueeButton.visible = NO;
    }                completion:^(BOOL finished) {
        if (!finished)
            return;

        [self.marqueeButton setTitle:nextMarqueeString forState:UIControlStateNormal];
        [UIView animateWithDuration:timer? 0.5f: 0 animations:^{
            self.marqueeButton.visible = YES;
        }];
    }];
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

    return [MPUserEntity existingObjectWithID:self.userIDs[indexPath.item] inContext:context];
}

- (void)updateAvatarVisibility {

    for (NSIndexPath *indexPath in self.avatarCollectionView.indexPathsForVisibleItems) {
        MPAvatarCell *cell = (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:indexPath];
        [self updateVisibilityForAvatar:cell atIndexPath:indexPath animated:NO];
    }
}

- (void)updateModeForAvatar:(MPAvatarCell *)avatarCell atIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {

    switch (self.activeUserState) {
        case MPActiveUserStateNone: {
            [self.avatarCollectionView deselectItemAtIndexPath:indexPath animated:YES];
            [avatarCell setMode:MPAvatarModeLowered animated:animated];
            break;
        }
        case MPActiveUserStateLogin:
        case MPActiveUserStateUserName:
        case MPActiveUserStateMasterPasswordChoice:
        case MPActiveUserStateMasterPasswordConfirmation: {
            if ([self.avatarCollectionView.indexPathsForSelectedItems containsObject:indexPath])
                [avatarCell setMode:MPAvatarModeRaisedAndActive animated:animated];
            else
                [avatarCell setMode:MPAvatarModeRaisedButInactive animated:animated];
            break;
        }
        case MPActiveUserStateMinimized: {
            if ([self.avatarCollectionView.indexPathsForSelectedItems containsObject:indexPath])
                [avatarCell setMode:MPAvatarModeRaisedAndMinimized animated:animated];
            else
                [avatarCell setMode:MPAvatarModeRaisedAndHidden animated:animated];
            break;
        }
    }
}

- (void)updateVisibilityForAvatar:(MPAvatarCell *)cell atIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {

    CGFloat current = [self.avatarCollectionView layoutAttributesForItemAtIndexPath:indexPath].center.x -
                      self.avatarCollectionView.contentOffset.x;
    CGFloat max = self.avatarCollectionView.bounds.size.width;

    CGFloat visibility = MAX( 0, MIN( 1, 1 - ABS( current / (max / 2) - 1 ) ) );
    [cell setVisibility:visibility animated:animated];

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        self.nextAvatarButton.visible = self.previousAvatarButton.visible = cell.newUser && cell.mode == MPAvatarModeRaisedAndActive;
        self.nextAvatarButton.alpha = self.previousAvatarButton.alpha = visibility * 0.7f;
    }];
}

- (void)afterUpdatesMainQueue:(void ( ^ )(void))block {

    [self.afterUpdates addOperationWithBlock:^{
        PearlMainQueue( block );
    }];
}

- (void)removeObservers {

    [self removeKeyPathObservers];
    PearlRemoveNotificationObservers();
    [[NSNotificationCenter defaultCenter] removeObserver:self.contextChangedObserver];
}

- (void)registerObservers {

    [self removeObservers];
    [self observeKeyPath:@"avatarCollectionView.contentOffset" withBlock:
            ^(id from, id to, NSKeyValueChange cause, MPUsersViewController *self) {
                [self updateAvatarVisibility];
            }];

    PearlAddNotificationObserver( UIApplicationDidEnterBackgroundNotification, nil, [NSOperationQueue mainQueue],
            ^(MPUsersViewController *self, NSNotification *note) {
                self.userSelectionContainer.visible = NO;
            } );
    PearlAddNotificationObserver( UIApplicationWillEnterForegroundNotification, nil, [NSOperationQueue mainQueue],
            ^(MPUsersViewController *self, NSNotification *note) {
                [self reloadUsers];
            } );
    PearlAddNotificationObserver( UIApplicationDidBecomeActiveNotification, nil, [NSOperationQueue mainQueue],
            ^(MPUsersViewController *self, NSNotification *note) {
                [UIView animateWithDuration:0.5f animations:^{
                    self.userSelectionContainer.visible = YES;
                }];
            } );
    PearlAddNotificationObserver( UIKeyboardWillShowNotification, nil, [NSOperationQueue mainQueue],
            ^(MPUsersViewController *self, NSNotification *note) {
                CGRect keyboardRect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
                CGFloat keyboardHeight = CGRectGetHeight( self.view.window.screen.bounds ) - CGRectGetMinY( keyboardRect );
                [self.keyboardHeightConstraint updateConstant:keyboardHeight];
            } );

    if ((self.contextChangedObserver
            = [[MPiOSAppDelegate get] managedObjectContextChanged:^(NSDictionary<NSManagedObjectID *, NSString *> *affectedObjects) {
                if ([[[affectedObjects allKeys] filteredArrayUsingPredicate:
                        [NSPredicate predicateWithBlock:^BOOL(NSManagedObjectID *objectID, NSDictionary *bindings) {
                            return [objectID.entity.name isEqualToString:NSStringFromClass( [MPUserEntity class] )];
                        }]] count])
                    [self reloadUsers];
            }]))
        [UIView animateWithDuration:0.3f animations:^{
            self.avatarCollectionView.visible = YES;
            [self.storeLoadingActivity stopAnimating];
        }];
    else
        [UIView animateWithDuration:0.3f animations:^{
            self.avatarCollectionView.visible = NO;
            [self.storeLoadingActivity startAnimating];
        }];

    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresWillChangeNotification, [MPiOSAppDelegate get].storeCoordinator, nil,
            ^(MPUsersViewController *self, NSNotification *note) {
                self.userIDs = nil;
            } );
    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresDidChangeNotification, [MPiOSAppDelegate get].storeCoordinator, nil,
            ^(MPUsersViewController *self, NSNotification *note) {
                [self registerObservers];
                [self reloadUsers];
            } );
}

- (void)reloadUsers {

    [self afterUpdatesMainQueue:^{
        if (![MPiOSAppDelegate managedObjectContextForMainThreadPerformBlockAndWait:^(NSManagedObjectContext *mainContext) {
            NSError *error = nil;
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
            fetchRequest.sortDescriptors = @[
                    [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector( @selector( lastUsed ) ) ascending:NO]
            ];
            NSArray *users = [mainContext executeFetchRequest:fetchRequest error:&error];
            if (!users) {
                MPError( error, @"Failed to load users." );
                self.userIDs = nil;
            }

            NSMutableArray *userIDs = [NSMutableArray arrayWithCapacity:[users count]];
            for (MPUserEntity *user in users)
                [userIDs addObject:user.permanentObjectID];
            self.userIDs = userIDs;
        }])
            self.userIDs = nil;
    }];
}

#pragma mark - Properties

- (void)setActive:(BOOL)active animated:(BOOL)animated {

    _active = active;

    if (active)
        [self setActiveUserState:MPActiveUserStateNone animated:animated];
    else
        [self setActiveUserState:MPActiveUserStateMinimized animated:animated];
}

- (void)setUserIDs:(NSArray *)userIDs {

    _userIDs = userIDs;

    PearlMainQueue( ^{
        BOOL isNew = NO;
        NSManagedObjectID *selectUserID = [MPiOSAppDelegate get].activeUserOID;
        if (!selectUserID)
            selectUserID = [self selectedUserInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]
                                                 isNew:&isNew].permanentObjectID;
        [self.avatarCollectionView reloadData];

        NSUInteger selectedAvatarItem = isNew? [self.userIDs count]: selectUserID? [self.userIDs indexOfObject:selectUserID]: NSNotFound;
        if (selectedAvatarItem != NSNotFound)
            [self.avatarCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:selectedAvatarItem inSection:0] animated:NO
                                              scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

        [UIView animateWithDuration:0.3f animations:^{
            self.userSelectionContainer.visible = YES;
        }];
    } );
}

- (void)setActiveUserState:(MPActiveUserState)activeUserState {

    [self setActiveUserState:activeUserState animated:YES];
}

- (void)setActiveUserState:(MPActiveUserState)activeUserState animated:(BOOL)animated {

    _activeUserState = activeUserState;
    self.masterPasswordChoice = nil;

    if (activeUserState != MPActiveUserStateMinimized && (!self.active || [MPiOSAppDelegate get].activeUserOID)) {
        [[MPiOSAppDelegate get] signOutAnimated:YES];
        return;
    }

    // Set the entry container's contents.
    [self.afterUpdates setSuspended:YES];
    __block BOOL requestFirstResponder = NO;
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:animated? 0.4f: 0 animations:^{
        switch (activeUserState) {
            case MPActiveUserStateNone:
                break;
            case MPActiveUserStateLogin: {
                self.entryLabel.text = strl( @"Enter your master password:" );
                self.entryField.secureTextEntry = YES;
                self.entryField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                self.entryField.text = nil;
                break;
            }
            case MPActiveUserStateUserName: {
                self.entryLabel.text = strl( @"Enter your full name:" );
                self.entryField.secureTextEntry = NO;
                self.entryField.autocapitalizationType = UITextAutocapitalizationTypeWords;
                self.entryField.text = nil;
                break;
            }
            case MPActiveUserStateMasterPasswordChoice: {
                self.entryLabel.text = strl( @"Choose your master password:" );
                self.entryField.secureTextEntry = YES;
                self.entryField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                self.entryField.text = nil;
                break;
            }
            case MPActiveUserStateMasterPasswordConfirmation: {
                self.masterPasswordChoice = self.entryField.text;
                self.entryLabel.text = strl( @"Confirm your master password:" );
                self.entryField.secureTextEntry = YES;
                self.entryField.autocapitalizationType = UITextAutocapitalizationTypeNone;
                self.entryField.text = nil;
                break;
            }
            case MPActiveUserStateMinimized:
                break;
        }

        // Manage the entry container depending on whether a user is activate or not.
        switch (activeUserState) {
            case MPActiveUserStateNone: {
                self.avatarCollectionView.scrollEnabled = YES;
                self.entryContainer.visible = NO;
                self.footerContainer.visible = YES;
                break;
            }
            case MPActiveUserStateLogin:
            case MPActiveUserStateUserName:
            case MPActiveUserStateMasterPasswordChoice:
            case MPActiveUserStateMasterPasswordConfirmation: {
                self.avatarCollectionView.scrollEnabled = NO;
                self.entryContainer.visible = YES;
                self.footerContainer.visible = YES;
                requestFirstResponder = YES;
                break;
            }
            case MPActiveUserStateMinimized: {
                self.avatarCollectionView.scrollEnabled = NO;
                self.entryContainer.visible = NO;
                self.footerContainer.visible = NO;
                break;
            }
        }

        // Manage tip visibility.
        switch (activeUserState) {
            case MPActiveUserStateNone:
            case MPActiveUserStateMasterPasswordConfirmation:
            case MPActiveUserStateLogin: {
                break;
            }
            case MPActiveUserStateUserName: {
                [self showTips:MPUsersAvatarTip];
                break;
            }
            case MPActiveUserStateMasterPasswordChoice: {
                [self showEntryTip:strl( @"A short phrase makes a strong, memorable password." )];
                break;
            }
            case MPActiveUserStateMinimized: {
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"tipped.passwordsPreferences"])
                    [self showTips:MPUsersPreferencesTip];

                break;
            }
        }

        [self.view layoutIfNeeded];
    }                completion:^(BOOL finished) {
        [self.afterUpdates setSuspended:NO];
    }];

    [self.entryField resignFirstResponder];
    if (requestFirstResponder)
        [self.entryField becomeFirstResponder];

    // Set avatar modes.
    MPAvatarCell *selectedAvatar = [self selectedAvatar];
    for (NSIndexPath *indexPath in [self.avatarCollectionView indexPathsForVisibleItems]) {
        MPAvatarCell *avatarCell = (MPAvatarCell *)[self.avatarCollectionView cellForItemAtIndexPath:indexPath];
        [self updateModeForAvatar:avatarCell atIndexPath:indexPath animated:animated];
        [self updateVisibilityForAvatar:avatarCell atIndexPath:indexPath animated:animated];

        if (selectedAvatar && avatarCell == selectedAvatar)
            [self.avatarCollectionView scrollToItemAtIndexPath:indexPath
                                              atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

#pragma mark - Actions

- (IBAction)changeAvatar:(UIButton *)sender {

    if (sender == self.previousAvatarButton)
        --[self selectedAvatar].avatar;
    if (sender == self.nextAvatarButton)
        ++[self selectedAvatar].avatar;
}

@end
