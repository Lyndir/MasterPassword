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
#import "MPAppDelegate_InApp.h"

@interface MPPreferencesViewController()

@end

@implementation MPPreferencesViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.contentInset = UIEdgeInsetsMake( 64, 0, 49, 0 );
}

- (void)viewWillAppear:(BOOL)animated {

    inf( @"Preferences will appear" );
    [super viewWillAppear:animated];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"tipped.passwordsPreferences"];
    if (![[NSUserDefaults standardUserDefaults] synchronize])
        wrn( @"Couldn't synchronize after preferences appearance." );

    [self reload];
}

- (void)reload {

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForMainThread];
    self.generatedTypeControl.selectedSegmentIndex = [self generatedSegmentIndexForType:activeUser.defaultType];
    self.storedTypeControl.selectedSegmentIndex = [self storedSegmentIndexForType:activeUser.defaultType];
    self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%lu", (unsigned long)activeUser.avatar )];
    self.savePasswordSwitch.on = activeUser.saveKey;
    self.touchIDSwitch.on = activeUser.touchID;
    self.touchIDSwitch.enabled = self.savePasswordSwitch.on && ![[MPiOSAppDelegate get] isFeatureUnlocked:MPProductTouchID];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.signOutCell) {
        [self dismissPopup];
        [[MPiOSAppDelegate get] signOutAnimated:YES];
    }
    if (cell == self.feedbackCell)
        [[MPiOSAppDelegate get] showFeedbackWithLogs:YES forVC:self];
    if (cell == self.exportCell)
        [[MPiOSAppDelegate get] showExportForVC:self];
    if (cell == self.showHelpCell) {
        MPPasswordsViewController *passwordsVC = [self dismissPopup];
        [passwordsVC performSegueWithIdentifier:@"guide" sender:self];
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

            PearlMainQueue(^{
                [self reload];
            });
        }];

    if (sender == self.touchIDSwitch)
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
            if ((activeUser.touchID = self.touchIDSwitch.on))
                [[MPiOSAppDelegate get] storeSavedKeyFor:activeUser];
            else
                [[MPiOSAppDelegate get] forgetSavedKeyFor:activeUser];
            [context saveToStore];

            PearlMainQueue( ^{
                [self reload];
            } );
        }];

    if (sender == self.generatedTypeControl || sender == self.storedTypeControl) {
        if (sender == self.generatedTypeControl)
            self.storedTypeControl.selectedSegmentIndex = -1;
        else if (sender == self.storedTypeControl)
            self.generatedTypeControl.selectedSegmentIndex = -1;

        MPSiteType defaultType = [self typeForSelectedSegment];
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            [[MPiOSAppDelegate get] activeUserInContext:context].defaultType = defaultType;
            [context saveToStore];

            PearlMainQueue( ^{
                [self reload];
            } );
        }];
    }
}

- (IBAction)previousAvatar:(id)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
        activeUser.avatar = (activeUser.avatar - 1 + MPAvatarCount) % MPAvatarCount;
        [context saveToStore];

        NSUInteger avatar = activeUser.avatar;
        PearlMainQueue( ^{
            self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%lu", (unsigned long)avatar )];
        } );
    }];
}

- (IBAction)nextAvatar:(id)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:context];
        activeUser.avatar = (activeUser.avatar + 1 + MPAvatarCount) % MPAvatarCount;
        [context saveToStore];

        NSUInteger avatar = activeUser.avatar;
        PearlMainQueue( ^{
            self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%lu", (unsigned long)avatar )];
        } );
    }];
}

- (IBAction)homePageButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"http://masterpasswordapp.com"]];
}

- (IBAction)securityButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"http://masterpasswordapp.com/security.html"]];
}

- (IBAction)sourceButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"https://github.com/Lyndir/MasterPassword/"]];
}

- (IBAction)thanksButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"http://thanks.lhunath.com"]];
}

#pragma mark - Private

- (MPPasswordsViewController *)dismissPopup {

    for (UIViewController *vc = self; (vc = vc.parentViewController);)
        if ([vc isKindOfClass:[MPPasswordsViewController class]]) {
            MPPasswordsViewController *passwordsVC = (MPPasswordsViewController *)vc;
            [passwordsVC dismissPopdown:self];
            return passwordsVC;
        }

    return nil;
}

- (MPSiteType)typeForSelectedSegment {

    NSInteger selectedGeneratedIndex = self.generatedTypeControl.selectedSegmentIndex;
    NSInteger selectedStoredIndex = self.storedTypeControl.selectedSegmentIndex;

    switch (selectedGeneratedIndex) {
        case 0:
            return MPSiteTypeGeneratedMaximum;
        case 1:
            return MPSiteTypeGeneratedLong;
        case 2:
            return MPSiteTypeGeneratedMedium;
        case 3:
            return MPSiteTypeGeneratedBasic;
        case 4:
            return MPSiteTypeGeneratedShort;
        case 5:
            return MPSiteTypeGeneratedPIN;
        default:

            switch (selectedStoredIndex) {
                case 0:
                    return MPSiteTypeStoredPersonal;
                case 1:
                    return MPSiteTypeStoredDevicePrivate;
                default:
                    Throw( @"unsupported selected type index: generated=%ld, stored=%ld", (long)selectedGeneratedIndex,
                                    (long)selectedStoredIndex );
            }
    }
}

- (NSInteger)generatedSegmentIndexForType:(MPSiteType)type {

    switch (type) {
        case MPSiteTypeGeneratedMaximum:
            return 0;
        case MPSiteTypeGeneratedLong:
            return 1;
        case MPSiteTypeGeneratedMedium:
            return 2;
        case MPSiteTypeGeneratedBasic:
            return 3;
        case MPSiteTypeGeneratedShort:
            return 4;
        case MPSiteTypeGeneratedPIN:
            return 5;
        default:
            return -1;
    }
}

- (NSInteger)storedSegmentIndexForType:(MPSiteType)type {

    switch (type) {
        case MPSiteTypeStoredPersonal:
            return 0;
        case MPSiteTypeStoredDevicePrivate:
            return 1;
        default:
            return -1;
    }
}

@end
