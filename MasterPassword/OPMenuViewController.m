//
//  OPMenuViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 05/02/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPMenuViewController.h"


@implementation OPMenuViewController

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 4)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Apps&path=MasterPassword"]];
}

@end
