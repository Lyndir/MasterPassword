//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAnswersViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "UIColor+Expanded.h"
#import "MPPasswordsViewController.h"
#import "MPCoachmarkViewController.h"

@interface MPAnswersViewController()

@end

@implementation MPAnswersViewController

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.item == 0)
        return [MPGlobalAnswersCell dequeueCellFromTableView:tableView indexPath:indexPath];
    if (indexPath.item == 1)
        return [MPSendAnswersCell dequeueCellFromTableView:tableView indexPath:indexPath];
    if (indexPath.item == 2)
        return [MPMultipleAnswersCell dequeueCellFromTableView:tableView indexPath:indexPath];

    MPAnswersQuestionCell *cell = [MPAnswersQuestionCell dequeueCellFromTableView:tableView indexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

@implementation MPGlobalAnswersCell : UITableViewCell

@end

@implementation MPSendAnswersCell : UITableViewCell

@end

@implementation MPMultipleAnswersCell : UITableViewCell

@end

@implementation MPAnswersQuestionCell : UITableViewCell

@end
