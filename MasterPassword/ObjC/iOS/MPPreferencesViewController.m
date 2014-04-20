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

@interface MPPreferencesViewController()

@end

@implementation MPPreferencesViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Preferences will appear");
    [super viewWillAppear:animated];

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForMainThread];
    self.typeControl.selectedSegmentIndex = [self segmentIndexForType:activeUser.defaultType];
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
    if (cell == self.exportCell)
        [[MPiOSAppDelegate get] export];

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

    if (sender == self.typeControl)
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            [[MPiOSAppDelegate get] activeUserInContext:context].defaultType = [self typeForSelectedSegment];
            [context saveToStore];
        }];
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

    switch (self.typeControl.selectedSegmentIndex) {
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
            Throw(@"Unsupported type index: %ld", (long)self.typeControl.selectedSegmentIndex);
    }
}

- (NSInteger)segmentIndexForType:(MPElementType)type {

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
            Throw(@"Unsupported type index: %ld", (long)self.typeControl.selectedSegmentIndex);
    }
}

@end
