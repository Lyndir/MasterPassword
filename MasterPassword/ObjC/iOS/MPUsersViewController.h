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

#import "LLGitTip.h"

@interface MPUsersViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property(weak, nonatomic) IBOutlet UIView *userSelectionContainer;
@property(weak, nonatomic) IBOutlet UILabel *hintLabel;
@property(weak, nonatomic) IBOutlet UIView *gitTipTip;
@property(weak, nonatomic) IBOutlet LLGitTip *gitTipButton;
@property(weak, nonatomic) IBOutlet UITextField *entryField;
@property(weak, nonatomic) IBOutlet UILabel *entryLabel;
@property(weak, nonatomic) IBOutlet UIView *entryContainer;
@property(weak, nonatomic) IBOutlet UIView *footerContainer;
@property(weak, nonatomic) IBOutlet UICollectionView *avatarCollectionView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *avatarCollectionCenterConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navigationBarToTopConstraint;

@property(assign, nonatomic) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated;

@end
