//
//  MPTypeViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 27/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPTypeViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@interface MPTypeViewController()

- (MPSiteType)typeAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation MPTypeViewController

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Type selection will appear");
    self.recommendedTipContainer.alpha = 0;

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    if ([[MPiOSConfig get].firstRun boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.recommendedTipContainer.alpha = 1;
        }                completion:^(BOOL finished) {
            if (finished) {
                dispatch_after( dispatch_time( DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC) ), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.2f animations:^{
                        self.recommendedTipContainer.alpha = 0;
                    }];
                } );
            }
        }];

    [super viewDidAppear:animated];
}

- (void)viewDidLoad {

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Type selection will disappear");
    [super viewWillDisappear:animated];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    MPSiteEntity *selectedElement = nil;
    if ([self.delegate respondsToSelector:@selector(selectedElement)])
        selectedElement = [self.delegate selectedElement];

    MPSiteType cellType = [self typeAtIndexPath:indexPath];
    MPSiteType selectedType = selectedElement? selectedElement.type: [self.delegate selectedType];
    cell.selected = (selectedType == cellType);

    if (cellType != (MPSiteType)NSNotFound && cellType & MPSiteTypeClassGenerated) {
        [(UITextField *)[cell viewWithTag:2] setText:@"..."];

        NSString *name = selectedElement.name;
        NSUInteger counter = 0;
        if ([selectedElement isKindOfClass:[MPElementGeneratedEntity class]])
            counter = ((MPElementGeneratedEntity *)selectedElement).counter;

        dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ), ^{
            NSString *typeContent = [MPAlgorithmDefault generatePasswordForSiteNamed:name ofType:cellType
                                                                         withCounter:counter usingKey:[MPiOSAppDelegate get].key];

            dispatch_async( dispatch_get_main_queue(), ^{
                [(UITextField *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:2] setText:typeContent];
            } );
        } );
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSAssert(self.navigationController.topViewController == self, @"Not the currently active navigation item.");

    MPSiteType type = [self typeAtIndexPath:indexPath];
    if (type == (MPSiteType)NSNotFound)
            // Selected a non-type row.
        return;

    [self.delegate didSelectType:type];
    [self.navigationController popViewControllerAnimated:YES];
}

- (MPSiteType)typeAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.section) {
        case 0: {
            // Generated
            switch (indexPath.row) {
                case 0:
                    return (MPSiteType)NSNotFound;
                case 1:
                    return MPSiteTypeGeneratedMaximum;
                case 2:
                    return MPSiteTypeGeneratedLong;
                case 3:
                    return MPSiteTypeGeneratedMedium;
                case 4:
                    return MPSiteTypeGeneratedBasic;
                case 5:
                    return MPSiteTypeGeneratedShort;
                case 6:
                    return MPSiteTypeGeneratedPIN;
                case 7:
                    return (MPSiteType)NSNotFound;

                default: {
                    Throw(@"Unsupported row: %ld, when selecting generated element type.", (long)indexPath.row);
                }
            }
        }

        case 1: {
            // Stored
            switch (indexPath.row) {
                case 0:
                    return (MPSiteType)NSNotFound;
                case 1:
                    return MPSiteTypeStoredPersonal;
                case 2:
                    return MPSiteTypeStoredDevicePrivate;
                case 3:
                    return (MPSiteType)NSNotFound;

                default: {
                    Throw(@"Unsupported row: %ld, when selecting stored element type.", (long)indexPath.row);
                }
            }
        }

        default:
            Throw(@"Unsupported section: %ld, when selecting element type.", (long)indexPath.section);
    }
}

@end
