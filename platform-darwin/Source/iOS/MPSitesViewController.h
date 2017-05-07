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

@interface MPSitesViewController : UIViewController<UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
@property(nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *sitesToBottomConstraint;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *navigationBarToTopConstraint;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *popdownToTopConstraint;
@property(nonatomic, strong) IBOutlet UIView *badNameTipContainer;
@property(nonatomic, strong) IBOutlet UIView *popdownView;
@property(nonatomic, strong) IBOutlet UIView *popdownContainer;

@property(assign, nonatomic) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated completion:(void ( ^ )(BOOL finished))completion;
- (void)reloadSites;

- (IBAction)dismissPopdown:(id)sender;

@end
