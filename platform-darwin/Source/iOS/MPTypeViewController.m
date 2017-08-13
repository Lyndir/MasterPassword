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

#import "MPTypeViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@interface MPTypeViewController()

- (MPResultType)typeAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation MPTypeViewController

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {

    inf( @"Type selection will appear" );
    self.recommendedTipContainer.visible = NO;

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    if ([[MPiOSConfig get].firstRun boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.recommendedTipContainer.visible = YES;
        }                completion:^(BOOL finished) {
            PearlMainQueueAfter( 5, ^{
                [UIView animateWithDuration:0.2f animations:^{
                    self.recommendedTipContainer.visible = NO;
                }];
            } );
        }];

    [super viewDidAppear:animated];
}

- (void)viewDidLoad {

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf( @"Type selection will disappear" );
    [super viewWillDisappear:animated];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    MPSiteEntity *selectedSite = nil;
    if ([self.delegate respondsToSelector:@selector( selectedSite )])
        selectedSite = [self.delegate selectedSite];

    MPResultType cellType = [self typeAtIndexPath:indexPath];
    MPResultType selectedType = selectedSite? selectedSite.type: [self.delegate selectedType];
    cell.selected = (selectedType == cellType);

    if (cellType != (MPResultType)NSNotFound && cellType & MPResultTypeClassTemplate) {
        [(UITextField *)[cell viewWithTag:2] setText:@"..."];

        NSString *name = selectedSite.name;
        MPCounterValue counter = 0;
        if ([selectedSite isKindOfClass:[MPGeneratedSiteEntity class]])
            counter = ((MPGeneratedSiteEntity *)selectedSite).counter;

        PearlNotMainQueue( ^{
            NSString *typeContent = [MPAlgorithmDefault mpwTemplateForSiteNamed:name ofType:cellType
                                                                    withCounter:counter usingKey:[MPiOSAppDelegate get].key];

            PearlMainQueue( ^{
                [(UITextField *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:2] setText:typeContent];
            } );
        } );
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSAssert( self.navigationController.topViewController == self, @"Not the currently active navigation item." );

    MPResultType type = [self typeAtIndexPath:indexPath];
    if (type == (MPResultType)NSNotFound)
        // Selected a non-type row.
        return;

    [self.delegate didSelectType:type];
    [self.navigationController popViewControllerAnimated:YES];
}

- (MPResultType)typeAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.section) {
        case 0: {
            // Generated
            switch (indexPath.row) {
                case 0:
                    return (MPResultType)NSNotFound;
                case 1:
                    return MPResultTypeTemplateMaximum;
                case 2:
                    return MPResultTypeTemplateLong;
                case 3:
                    return MPResultTypeTemplateMedium;
                case 4:
                    return MPResultTypeTemplateBasic;
                case 5:
                    return MPResultTypeTemplateShort;
                case 6:
                    return MPResultTypeTemplatePIN;
                case 7:
                    return (MPResultType)NSNotFound;

                default: {
                    Throw( @"Unsupported row: %ld, when selecting generated site type.", (long)indexPath.row );
                }
            }
        }

        case 1: {
            // Stored
            switch (indexPath.row) {
                case 0:
                    return (MPResultType)NSNotFound;
                case 1:
                    return MPResultTypeStatefulPersonal;
                case 2:
                    return MPResultTypeStatefulDevice;
                case 3:
                    return (MPResultType)NSNotFound;

                default: {
                    Throw( @"Unsupported row: %ld, when selecting stored site type.", (long)indexPath.row );
                }
            }
        }

        default:
            Throw( @"Unsupported section: %ld, when selecting site type.", (long)indexPath.section );
    }
}

@end
