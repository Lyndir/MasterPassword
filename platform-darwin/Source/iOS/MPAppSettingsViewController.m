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

#import "MPAppSettingsViewController.h"
#import "UIColor+Expanded.h"

@implementation MPAppSettingsViewController

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
