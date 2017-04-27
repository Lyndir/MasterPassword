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

@class MPSiteEntity;
@class MPCoachmark;

@interface MPPasswordsViewController : UIViewController<UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(strong, nonatomic) IBOutlet UIView *passwordSelectionContainer;
@property(strong, nonatomic) IBOutlet UICollectionView *passwordCollectionView;
@property(strong, nonatomic) IBOutlet UISearchBar *passwordsSearchBar;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *passwordsToBottomConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *navigationBarToTopConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *popdownToTopConstraint;
@property(strong, nonatomic) IBOutlet UIView *badNameTipContainer;
@property(strong, nonatomic) IBOutlet UIView *popdownView;
@property(strong, nonatomic) IBOutlet UIView *popdownContainer;

@property(assign, nonatomic) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated completion:(void ( ^ )(BOOL finished))completion;
- (void)reloadPasswords;

- (IBAction)dismissPopdown:(id)sender;

@end
