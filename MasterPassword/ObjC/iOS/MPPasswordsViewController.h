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

@interface MPPasswordsViewController : UIViewController<UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>

@property(strong, nonatomic) IBOutlet UIView *passwordSelectionContainer;
@property(strong, nonatomic) IBOutlet UICollectionView *passwordCollectionView;
@property (strong, nonatomic) IBOutlet UISearchBar *passwordsSearchBar;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *passwordsToBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navigationBarToTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navigationBarToPasswordsConstraint;

@property(assign, nonatomic) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated;

@end
