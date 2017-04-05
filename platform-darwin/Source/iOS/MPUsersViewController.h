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

@interface MPUsersViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UIView *userSelectionContainer;
@property(weak, nonatomic) IBOutlet UIButton *marqueeButton;
@property(weak, nonatomic) IBOutlet UITextField *entryField;
@property(weak, nonatomic) IBOutlet UILabel *entryLabel;
@property(weak, nonatomic) IBOutlet UILabel *entryTipTitleLabel;
@property(weak, nonatomic) IBOutlet UILabel *entryTipSubtitleLabel;
@property(weak, nonatomic) IBOutlet UIView *entryContainer;
@property(weak, nonatomic) IBOutlet UIView *footerContainer;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *storeLoadingActivity;
@property(weak, nonatomic) IBOutlet UICollectionView *avatarCollectionView;
@property(weak, nonatomic) IBOutlet UIView *avatarTipContainer;
@property(weak, nonatomic) IBOutlet UIView *entryTipContainer;
@property(weak, nonatomic) IBOutlet UIView *preferencesTipContainer;
@property(weak, nonatomic) IBOutlet UIView *thanksTipContainer;
@property(weak, nonatomic) IBOutlet UIButton *nextAvatarButton;
@property(weak, nonatomic) IBOutlet UIButton *previousAvatarButton;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeightConstraint;

@property(assign, nonatomic, readonly) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (IBAction)changeAvatar:(UIButton *)sender;

@end
