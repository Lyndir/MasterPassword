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

typedef NS_ENUM(NSUInteger, MPCombinedMode) {
    MPCombinedModeUserSelection,
    MPCombinedModePasswordSelection,
};

@interface MPCombinedViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *usersView;
@property (strong, nonatomic) IBOutlet UIView *passwordsView;

@property(assign, nonatomic) MPCombinedMode mode;

- (IBAction)doSignOut:(UIBarButtonItem *)sender;

@end
