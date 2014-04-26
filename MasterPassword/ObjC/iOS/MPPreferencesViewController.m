//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPreferencesViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "UIColor+Expanded.h"
#import "MPPasswordsViewController.h"
#import "MPCoachmarkViewController.h"

@interface MPPreferencesViewController()

@end

@implementation MPPreferencesViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    inf( @"Preferences will appear" );
    [super viewWillAppear:animated];

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForMainThread];
    self.generatedTypeControl.selectedSegmentIndex = [self generatedSegmentIndexForType:activeUser.defaultType];
    self.storedTypeControl.selectedSegmentIndex = [self storedSegmentIndexForType:activeUser.defaultType];
    self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%ld", (long)activeUser.avatar )];
    self.savePasswordSwitch.on = activeUser.saveKey;

    self.tableView.contentInset = UIEdgeInsetsMake( 64, 0, 49, 0 );
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRGBAHex:0x78DDFB33];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.feedbackCell)
        [[MPiOSAppDelegate get] showFeedbackWithLogs:YES forVC:self];
    if (cell == self.exportCell)
        [[MPiOSAppDelegate get] showExportForVC:self];
    if (cell == self.coachmarksCell) {
        for (UIViewController *vc = self; (vc = vc.parentViewController);)
            if ([vc isKindOfClass:[MPPasswordsViewController class]]) {
                MPPasswordsViewController *passwordsVC = (MPPasswordsViewController *)vc;
                passwordsVC.coachmark.coached = NO;
                [passwordsVC dismissPopdown:self];
                [vc performSegueWithIdentifier:@"coachmarks" sender:self];
            }
    }
    if (cell == self.checkInconsistencies)
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            if ([[MPiOSAppDelegate get] findAndFixInconsistenciesSaveInContext:context] == MPFixableResultNoProblems)
                [PearlAlert showAlertWithTitle:@"No Inconsistencies" message:
                        @"No inconsistencies were detected in your sites."
                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                             tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
        }];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBActions

- (IBAction)valueChanged:(id)sender {

    if (sender == self.savePasswordSwitch)
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
            if ((activeUser.saveKey = self.savePasswordSwitch.on))
                [[MPiOSAppDelegate get] storeSavedKeyFor:activeUser];
            else
                [[MPiOSAppDelegate get] forgetSavedKeyFor:activeUser];
            [context saveToStore];
        }];

    if (sender == self.generatedTypeControl || sender == self.storedTypeControl) {
        if (sender == self.generatedTypeControl)
            self.storedTypeControl.selectedSegmentIndex = -1;
        else if (sender == self.storedTypeControl)
            self.generatedTypeControl.selectedSegmentIndex = -1;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPElementType defaultType = [[MPiOSAppDelegate get] activeUserInContext:context].defaultType = [self typeForSelectedSegment];
            [context saveToStore];

            PearlMainQueue( ^{
                self.generatedTypeControl.selectedSegmentIndex = [self generatedSegmentIndexForType:defaultType];
                self.storedTypeControl.selectedSegmentIndex = [self storedSegmentIndexForType:defaultType];
            } );
        }];
    }
}

- (IBAction)previousAvatar:(id)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
        activeUser.avatar = (activeUser.avatar - 1 + MPAvatarCount) % MPAvatarCount;
        [context saveToStore];

        long avatar = activeUser.avatar;
        PearlMainQueue( ^{
            self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%ld", avatar )];
        } );
    }];
}

- (IBAction)nextAvatar:(id)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
        activeUser.avatar = (activeUser.avatar + 1 + MPAvatarCount) % MPAvatarCount;
        [context saveToStore];

        long avatar = activeUser.avatar;
        PearlMainQueue( ^{
            self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%ld", avatar )];
        } );
    }];
}

#pragma mark - Private

- (enum MPElementType)typeForSelectedSegment {

    NSInteger selectedGeneratedIndex = self.generatedTypeControl.selectedSegmentIndex;
    NSInteger selectedStoredIndex = self.storedTypeControl.selectedSegmentIndex;

    switch (selectedGeneratedIndex) {
        case 0:
            return MPElementTypeGeneratedMaximum;
        case 1:
            return MPElementTypeGeneratedLong;
        case 2:
            return MPElementTypeGeneratedMedium;
        case 3:
            return MPElementTypeGeneratedBasic;
        case 4:
            return MPElementTypeGeneratedShort;
        case 5:
            return MPElementTypeGeneratedPIN;
        default:

            switch (selectedStoredIndex) {
                case 0:
                    return MPElementTypeStoredPersonal;
                case 1:
                    return MPElementTypeStoredDevicePrivate;
                default:
                    Throw( @"unsupported selected type index: generated=%ld, stored=%ld", (long)selectedGeneratedIndex, (long)selectedStoredIndex );
            }
    }
}

- (NSInteger)generatedSegmentIndexForType:(MPElementType)type {

    switch (type) {
        case MPElementTypeGeneratedMaximum:
            return 0;
        case MPElementTypeGeneratedLong:
            return 1;
        case MPElementTypeGeneratedMedium:
            return 2;
        case MPElementTypeGeneratedBasic:
            return 3;
        case MPElementTypeGeneratedShort:
            return 4;
        case MPElementTypeGeneratedPIN:
            return 5;
        default:
            return -1;
    }
}

- (NSInteger)storedSegmentIndexForType:(MPElementType)type {

    switch (type) {
        case MPElementTypeStoredPersonal:
            return 0;
        case MPElementTypeStoredDevicePrivate:
            return 1;
        default:
            return -1;
    }
}

@end
