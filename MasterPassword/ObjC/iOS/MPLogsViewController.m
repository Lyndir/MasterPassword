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
//  MPLogsViewController.h
//  MPLogsViewController
//
//  Created by lhunath on 2013-04-29.
//  Copyright, lhunath (Maarten Billemont) 2013. All rights reserved.
//

#import "MPLogsViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPLogsViewController {
    PearlOverlay *_switchCloudStoreProgress;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil
                                                       queue:nil usingBlock:
            ^(NSNotification *note) {
                dispatch_async( dispatch_get_main_queue(), ^{
                    self.levelControl.selectedSegmentIndex = [[MPiOSConfig get].traceMode boolValue]? 1: 0;
                } );
            }];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self refresh:nil];

    self.levelControl.selectedSegmentIndex = [[MPiOSConfig get].traceMode boolValue]? 1: 0;
}

- (IBAction)action:(id)sender {

    [PearlSheet showSheetWithTitle:@"Advanced Actions" viewStyle:UIActionSheetStyleAutomatic
                         initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == sheet.cancelButtonIndex)
            return;

        if (buttonIndex == sheet.firstOtherButtonIndex) {
            // Switch
            [PearlAlert showAlertWithTitle:@"Switching iCloud Store" message:
                    @"WARNING: This is an advanced operation and should only be done if you're having trouble with iCloud."
                                 viewStyle:UIAlertViewStyleDefault initAlert:nil
                         tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex_) {
                             if (buttonIndex_ == alert.cancelButtonIndex)
                                 return;

                             _switchCloudStoreProgress = [PearlOverlay showOverlayWithTitle:@"Enumerating Stores"];
                             dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ), ^{
                                 [self switchCloudStore];
                             } );
                         } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
        }

        if (buttonIndex == sheet.firstOtherButtonIndex + 1) {
            // Rebuild
            [PearlAlert showAlertWithTitle:@"Rebuilding iCloud Store" message:
                    @"WARNING: This is an advanced operation and should only be done if you're having trouble with iCloud.\n"
                            @"Your local iCloud data will be removed and redownloaded from iCloud."
                                 viewStyle:UIAlertViewStyleDefault initAlert:nil
                         tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex_) {
                             if (buttonIndex_ == alert.cancelButtonIndex)
                                 return;

                             [[MPiOSAppDelegate get].storeManager deleteCloudContainerLocalOnly:YES];
                         }
                               cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
        }

        if (buttonIndex == sheet.firstOtherButtonIndex + 2) {
            // Wipe
            [PearlAlert showAlertWithTitle:@"Wiping iCloud Clean" message:
                    @"WARNING: This is an advanced operation and should only be done if you're having trouble with iCloud.\n"
                            @"All your iCloud data will be permanently lost.  This is a clean slate!"
                                 viewStyle:UIAlertViewStyleDefault initAlert:nil
                         tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex_) {
                             if (buttonIndex_ == alert.cancelButtonIndex)
                                 return;

                             [[MPiOSAppDelegate get].storeManager deleteCloudContainerLocalOnly:NO];
                         }
                               cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonContinue, nil];
        }
    }                  cancelTitle:[PearlStrings get].commonButtonCancel
                  destructiveTitle:nil otherTitles:@"Switch iCloud Store", @"Rebuild iCloud Container", @"Wipe iCloud Clean", nil];
}

- (void)switchCloudStore {

    NSDictionary *cloudStores = [[MPiOSAppDelegate get].storeManager enumerateCloudStores];
    if (!cloudStores)
    wrn(@"Failed enumerating cloud stores.");

    NSString *currentStoreUUID = nil;
    NSMutableDictionary *stores = [NSMutableDictionary dictionary];
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator *storePSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSFetchRequest *usersFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
    NSFetchRequest *sitesFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
    for (NSURL *cloudStoreURL in cloudStores) {
        NSString *storeUUID = [[cloudStoreURL URLByDeletingPathExtension] lastPathComponent];
        for (NSDictionary *cloudStoreOptions in cloudStores[cloudStoreURL]) {
            NSError *error = nil;
            NSPersistentStore *store = nil;
            NSUInteger firstDash = [storeUUID rangeOfString:@"-" options:0].location;
            NSString *storeDescription = PearlString( @"%@ v%@",
                    firstDash == NSNotFound? storeUUID: [storeUUID substringToIndex:firstDash],
                    cloudStoreOptions[USMCloudVersionKey] );
            if ([cloudStoreOptions[USMCloudCurrentKey] boolValue])
                currentStoreUUID = storeUUID;
            @try {
                if (!(store = [storePSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
                                                               URL:cloudStoreURL options:cloudStoreOptions error:&error])) {
                    wrn(@"Couldn't describe store %@.  While opening: %@", storeDescription, error);
                    continue;
                }

                NSUInteger userCount, siteCount;
                NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                moc.persistentStoreCoordinator = storePSC;
                if ((userCount = [moc countForFetchRequest:usersFetchRequest error:&error]) == NSNotFound) {
                    wrn(@"Couldn't describe store %@.  While determining userCount: %@", storeDescription, error);
                    continue;
                }
                if ((siteCount = [moc countForFetchRequest:sitesFetchRequest error:&error]) == NSNotFound) {
                    wrn(@"Couldn't describe store %@.  While determining siteCount: %@", storeDescription, error);
                    continue;
                }

                storeDescription = PearlString( @"%@: %luU, %luS", storeDescription, (unsigned long)userCount, (unsigned long)siteCount );
            }
            @catch (NSException *exception) {
                wrn(@"Couldn't describe store %@: %@", storeDescription, exception);
            }
            @finally {
                if (store && ![storePSC removePersistentStore:store error:&error]) {
                    wrn(@"Couldn't remove store %@: %@", storeDescription, error);
                    storePSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
                }

                stores[storeDescription] = cloudStoreOptions;
            }
        }
    }

    PearlArrayTVC *vc = [[PearlArrayTVC alloc] initWithStyle:UITableViewStylePlain];
    NSUInteger firstDash = [currentStoreUUID rangeOfString:@"-" options:0].location;
    vc.title = PearlString( @"Active: %@", firstDash == NSNotFound? currentStoreUUID: [currentStoreUUID substringToIndex:firstDash] );
    [stores enumerateKeysAndObjectsUsingBlock:^(id storeDescription, id cloudStoreOptions, BOOL *stop) {
        [vc addRowWithName:storeDescription style:PearlArrayTVCRowStyleLink toggled:[cloudStoreOptions[USMCloudCurrentKey] boolValue]
                 toSection:@"Cloud Stores" activationBlock:^BOOL(BOOL wasToggled) {
            [[MPiOSAppDelegate get].storeManager switchToCloudStoreWithOptions:cloudStoreOptions];
            [self.navigationController popToRootViewControllerAnimated:YES];
            return YES;
        }];
    }];
    dispatch_async( dispatch_get_main_queue(), ^{
        [_switchCloudStoreProgress cancelOverlayAnimated:YES];
        [self.navigationController pushViewController:vc animated:YES];
    } );
}

- (IBAction)toggleLevelControl:(UISegmentedControl *)sender {

    BOOL traceEnabled = (BOOL)self.levelControl.selectedSegmentIndex;
    if (traceEnabled) {
        [PearlAlert showAlertWithTitle:@"Enable Trace Mode?" message:
                @"Trace mode will log the internal operation of the application.\n"
                        @"Unless you're looking for the cause of a problem, you should leave this off to save memory."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         if (buttonIndex == [alert cancelButtonIndex])
                             return;

                         [MPiOSConfig get].traceMode = @YES;
                     } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Enable Trace", nil];
    }
    else
        [MPiOSConfig get].traceMode = @NO;
}

- (IBAction)refresh:(UIBarButtonItem *)sender {

    self.logView.text = [[PearlLogger get] formatMessagesWithLevel:PearlLogLevelTrace];
}

- (IBAction)mail:(UIBarButtonItem *)sender {

    if ([[MPiOSConfig get].traceMode boolValue]) {
        [PearlAlert showAlertWithTitle:@"Hiding Trace Messages" message:
                @"Trace-level log messages will not be mailed. "
                        @"These messages contain sensitive and personal information."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         [[MPiOSAppDelegate get] openFeedbackWithLogs:YES forVC:self];
                     } cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
    }
    else
        [[MPiOSAppDelegate get] openFeedbackWithLogs:YES forVC:self];
}

@end
