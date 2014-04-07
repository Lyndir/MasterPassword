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
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

#define MPElementUpgradeOldContentKey @"MPElementUpgradeOldContentKey"
#define MPElementUpgradeNewContentKey @"MPElementUpgradeNewContentKey"

@implementation MPElementListAllViewController

- (BOOL)prefersStatusBarHidden {

    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    if ([self.filter isEqualToString:MPElementListFilterNone]) {
        self.navigationItem.title = @"All Sites";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
    }
    else if ([self.filter isEqualToString:MPElementListFilterOutdated]) {
        self.navigationItem.title = @"Outdated";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                initWithTitle:@"Upgrade All" style:UIBarButtonItemStyleBordered target:self action:@selector(upgradeAll:)];
    }

    [self updateData];
}

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)add:(id)sender {

    [PearlAlert showAlertWithTitle:@"Add Site" message:nil viewStyle:UIAlertViewStylePlainTextInput initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (alert.cancelButtonIndex == buttonIndex)
                         return;

                     __weak MPElementListAllViewController *wSelf = self;
                     [[MPiOSAppDelegate get] addElementNamed:[alert textFieldAtIndex:0].text completion:^(MPElementEntity *element) {
                         if (element)
                             PearlMainQueue( ^{
                                 [wSelf.delegate didSelectElement:element];
                                 [wSelf close:nil];
                             } );
                     }];
                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonOkay, nil];
}

- (IBAction)upgradeAll:(id)sender {

    [PearlAlert showAlertWithTitle:@"Upgrading All Sites"
                           message:@"You are about to upgrade all outdated sites.  This will cause passwords to change.  "
                                           @"Afterwards, you can get an overview of the changes."
                         viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:
            ^(UIAlertView *alert, NSInteger buttonIndex) {
                if (buttonIndex == [alert cancelButtonIndex])
                    return;

                PearlOverlay *activity = [PearlOverlay showProgressOverlayWithTitle:@"Upgrading Sites"];
                [self performUpgradeAllWithCompletion:^(BOOL success, NSDictionary *changes) {
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [self showUpgradeChanges:changes];
                        [activity cancelOverlayAnimated:YES];
                    } );
                }];
            }          cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

- (void)performUpgradeAllWithCompletion:(void (^)(BOOL success, NSDictionary *changes))completion {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
        fetchRequest.fetchBatchSize = 20;

        NSError *error = nil;
        NSArray *elements = [moc executeFetchRequest:fetchRequest error:&error];
        if (!elements) {
            err(@"Failed to fetch outdated sites for upgrade: %@", error);
            completion( NO, nil );
            return;
        }

        MPKey *key = [MPAppDelegate_Shared get].key;
        NSMutableDictionary *elementChanges = [NSMutableDictionary dictionaryWithCapacity:[elements count]];
        for (MPElementEntity *element in elements) {
            id oldContent = [element.algorithm resolveContentForElement:element usingKey:key];
            [element migrateExplicitly:YES];
            id newContent = [element.algorithm resolveContentForElement:element usingKey:key];

            if (!(element.type & MPElementFeatureDevicePrivate) && (!oldContent || ![oldContent isEqual:newContent]))
                elementChanges[element.name] = @{
                        MPElementUpgradeOldContentKey : oldContent,
                        MPElementUpgradeNewContentKey : newContent,
                };
        }

        [moc saveToStore];
        completion( YES, elementChanges );
    }];
}

- (void)showUpgradeChanges:(NSDictionary *)changes {

    if (![changes count])
        return;

    NSMutableString *formattedChanges = [NSMutableString new];
    for (NSString *changedElementName in changes) {
        NSDictionary *elementChanges = changes[changedElementName];
        id oldContent = elementChanges[MPElementUpgradeOldContentKey];
        id newContent = elementChanges[MPElementUpgradeNewContentKey];
        [formattedChanges appendFormat:@"%@: %@ -> %@\n", changedElementName, oldContent, newContent];
    }

    [PearlAlert showAlertWithTitle:@"Sites Upgraded"
                           message:PearlString( @"This upgrade has caused %lu passwords to change.\n"
                                   @"To make updating the actual passwords of these accounts easier, "
                                   @"you can email a summary of these changes to yourself.", (unsigned long)[changes count] )
                         viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [PearlEMail sendEMailTo:nil subject:@"[Master Password] Upgrade Changes" body:formattedChanges];
    }                  cancelTitle:@"Don't Email" otherTitles:@"Send Email", nil];
}

- (NSFetchedResultsController *)fetchedResultsControllerByUses {

    return nil;
}

- (void)configureFetchRequest:(NSFetchRequest *)fetchRequest {

    fetchRequest.fetchBatchSize = 10;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self close:nil];
}

@end
