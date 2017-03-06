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

@interface MPUsersViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>

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
