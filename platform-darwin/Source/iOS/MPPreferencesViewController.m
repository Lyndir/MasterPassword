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

#import "MPPreferencesViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "UIColor+Expanded.h"
#import "MPSitesViewController.h"
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
    self.avatarImage.image = [UIImage imageNamed:strf( @"avatar-%lu", (unsigned long)activeUser.avatar )];
    self.savePasswordSwitch.on = activeUser.saveKey;
    self.touchIDSwitch.on = activeUser.touchID;
    self.touchIDSwitch.enabled = self.savePasswordSwitch.on && [[MPiOSAppDelegate get] isFeatureUnlocked:MPProductTouchID];

    MPResultType defaultType = activeUser.defaultType;
    self.generated1TypeControl.selectedSegmentIndex = [self generated1SegmentIndexForType:defaultType];
    self.generated2TypeControl.selectedSegmentIndex = [self generated2SegmentIndexForType:defaultType];
    self.storedTypeControl.selectedSegmentIndex = [self storedSegmentIndexForType:defaultType];
    PearlNotMainQueue( ^{
        NSString *examplePassword = nil;
        if (defaultType & MPResultTypeClassTemplate)
            examplePassword = [MPAlgorithmDefault mpwTemplateForSiteNamed:@"test" ofType:defaultType
                                                              withCounter:1 usingKey:[MPiOSAppDelegate get].key];
        PearlMainQueue( ^{
            self.typeSamplePassword.text = [examplePassword length]? [NSString stringWithFormat:@"eg. %@", examplePassword]: nil;
        } );
    } );
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
        MPSitesViewController *passwordsVC = [self dismissPopup];
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

            PearlMainQueue( ^{
                [self reload];
            } );
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

    if (sender == self.generated1TypeControl || sender == self.generated2TypeControl || sender == self.storedTypeControl) {
        if (sender != self.generated1TypeControl)
            self.generated1TypeControl.selectedSegmentIndex = -1;
        if (sender != self.generated2TypeControl)
            self.generated2TypeControl.selectedSegmentIndex = -1;
        if (sender != self.storedTypeControl)
            self.storedTypeControl.selectedSegmentIndex = -1;

        MPResultType defaultType = [self typeForSelectedSegment];
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
            [NSURL URLWithString:@"https://masterpassword.app"]];
}

- (IBAction)securityButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"https://masterpassword.app/security.html"]];
}

- (IBAction)sourceButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"https://github.com/Lyndir/MasterPassword/"]];
}

- (IBAction)thanksButton:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"https://thanks.lhunath.com"]];
}

#pragma mark - Private

- (MPSitesViewController *)dismissPopup {

    for (UIViewController *vc = self; (vc = vc.parentViewController);)
        if ([vc isKindOfClass:[MPSitesViewController class]]) {
            MPSitesViewController *passwordsVC = (MPSitesViewController *)vc;
            [passwordsVC dismissPopdown:self];
            return passwordsVC;
        }

    return nil;
}

- (MPResultType)typeForSelectedSegment {

    NSInteger selectedGenerated1Index = self.generated1TypeControl.selectedSegmentIndex;
    NSInteger selectedGenerated2Index = self.generated2TypeControl.selectedSegmentIndex;
    NSInteger selectedStoredIndex = self.storedTypeControl.selectedSegmentIndex;

    switch (selectedGenerated1Index) {
        case 0:
            return MPResultTypeTemplatePhrase;
        case 1:
            return MPResultTypeTemplateName;
        default:
            switch (selectedGenerated2Index) {
                case 0:
                    return MPResultTypeTemplateMaximum;
                case 1:
                    return MPResultTypeTemplateLong;
                case 2:
                    return MPResultTypeTemplateMedium;
                case 3:
                    return MPResultTypeTemplateBasic;
                case 4:
                    return MPResultTypeTemplateShort;
                case 5:
                    return MPResultTypeTemplatePIN;
                default:

                    switch (selectedStoredIndex) {
                        case 0:
                            return MPResultTypeStatefulPersonal;
                        case 1:
                            return MPResultTypeStatefulDevice;
                        default:
                            Throw( @"unsupported selected type index: generated1=%ld, generated2=%ld, stored=%ld",
                                    (long)selectedGenerated1Index, (long)selectedGenerated2Index, (long)selectedStoredIndex );
                    }
            }
    }
}

- (NSInteger)generated1SegmentIndexForType:(MPResultType)type {

    switch (type) {
        case MPResultTypeTemplatePhrase:
            return 0;
        case MPResultTypeTemplateName:
            return 1;
        default:
            return -1;
    }
}

- (NSInteger)generated2SegmentIndexForType:(MPResultType)type {

    switch (type) {
        case MPResultTypeTemplateMaximum:
            return 0;
        case MPResultTypeTemplateLong:
            return 1;
        case MPResultTypeTemplateMedium:
            return 2;
        case MPResultTypeTemplateBasic:
            return 3;
        case MPResultTypeTemplateShort:
            return 4;
        case MPResultTypeTemplatePIN:
            return 5;
        default:
            return -1;
    }
}

- (NSInteger)storedSegmentIndexForType:(MPResultType)type {

    switch (type) {
        case MPResultTypeStatefulPersonal:
            return 0;
        case MPResultTypeStatefulDevice:
            return 1;
        default:
            return -1;
    }
}

@end
