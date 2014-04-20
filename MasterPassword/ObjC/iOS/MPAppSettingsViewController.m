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
//  MPAppSettingsViewController.h
//  MPAppSettingsViewController
//
//  Created by lhunath on 2014-04-18.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPAppSettingsViewController.h"
#import "UIColor+Expanded.h"

@interface MPTableView:UITableView
@end

@implementation MPTableView

- (void)layoutSubviews {

    [super layoutSubviews];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {

    [super setContentInset:contentInset];
}

@end

@implementation MPAppSettingsViewController {
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.tableView.contentInset = UIEdgeInsetsMake( 64, 0, 49, 0 );
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];

    if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRGBAHex:0x78DDFB33];
    }

    return cell;
}

@end
