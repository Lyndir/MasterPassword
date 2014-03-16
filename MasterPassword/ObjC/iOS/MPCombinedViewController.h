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

typedef NS_ENUM(NSUInteger, MPCombinedMode) {
    MPCombinedModeUserSelection,
    MPCombinedModePasswordSelection,
};

@interface MPCombinedViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate>

@property(assign, nonatomic) MPCombinedMode mode;

#pragma mark - UserSelection

@property(strong, nonatomic) IBOutlet UIView *userSelectionContainer;
@property(weak, nonatomic) IBOutlet UILabel *hintLabel;
@property(weak, nonatomic) IBOutlet UIView *gitTipTip;
@property(weak, nonatomic) IBOutlet LLGitTip *gitTipButton;
@property(weak, nonatomic) IBOutlet UITextField *entryField;
@property(weak, nonatomic) IBOutlet UILabel *entryLabel;
@property(weak, nonatomic) IBOutlet UIView *entryContainer;
@property(weak, nonatomic) IBOutlet UICollectionView *avatarCollectionView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *avatarCollectionCenterConstraint;

#pragma mark - PasswordSelection

@property(strong, nonatomic) IBOutlet UIView *passwordSelectionContainer;
@property(strong, nonatomic) IBOutlet UICollectionView *passwordCollectionView;

- (IBAction)doSignOut:(UIBarButtonItem *)sender;

@end
