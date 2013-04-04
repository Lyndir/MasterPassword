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
//  MPElementListAllViewController
//
//  Created by Maarten Billemont on 2013-01-31.
//  Copyright 2013 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPElementListAllViewController.h"

@implementation MPElementListAllViewController

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)add:(id)sender {

    [PearlAlert showAlertWithTitle:@"Add Site" message:nil viewStyle:UIAlertViewStylePlainTextInput initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (alert.cancelButtonIndex == buttonIndex)
                         return;

                     __weak MPElementListAllViewController *wSelf = self;
                     [self addElementNamed:[alert textFieldAtIndex:0].text completion:^(BOOL success) {
                         if (success)
                             [wSelf close:nil];
                     }];
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonOkay, nil];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self updateData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self close:nil];
}

@end
