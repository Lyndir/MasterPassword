//
//  MPTypeViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 27/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPTypeViewController.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_Key.h"


@interface MPTypeViewController ()

- (MPElementType)typeAtIndexPath:(NSIndexPath *)indexPath;

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
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.2f animations:^{
                        self.recommendedTipContainer.alpha = 0;
                    }];
                });
            }
        }];

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Type Selection"];

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

    MPElementEntity *selectedElement = nil;
    if ([self.delegate respondsToSelector:@selector(selectedElement)])
        selectedElement = [self.delegate selectedElement];

    MPElementType cellType = [self typeAtIndexPath:indexPath];
    MPElementType selectedType = selectedElement? selectedElement.type: [self.delegate selectedType];
    cell.selected = (selectedType == cellType);

    if (cellType != NSNotFound && cellType & MPElementTypeClassGenerated) {
        [(UITextField *) [cell viewWithTag:2] setText:@"..."];

        NSString *name = selectedElement.name;
        NSUInteger counter = ((MPElementGeneratedEntity *)selectedElement).counter;

        dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ), ^{
            NSString *typeContent = [MPAlgorithmDefault generateContentNamed:name ofType:cellType
                                                                 withCounter:counter usingKey:[MPAppDelegate get].key];

            dispatch_async( dispatch_get_main_queue(), ^{
                [(UITextField *)[[tableView cellForRowAtIndexPath:indexPath] viewWithTag:2] setText:typeContent];
            } );
        } );
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    assert(self.navigationController.topViewController == self);

    MPElementType type = [self typeAtIndexPath:indexPath];
    if (type == NSNotFound)
        // Selected a non-type row.
        return;

    [self.delegate didSelectType:type];
    [self.navigationController popViewControllerAnimated:YES];
}

- (MPElementType)typeAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.section) {
        case 0: {
            // Generated
            switch (indexPath.row) {
                case 0:
                    return (MPElementType)NSNotFound;
                case 1:
                    return MPElementTypeGeneratedMaximum;
                case 2:
                    return MPElementTypeGeneratedLong;
                case 3:
                    return MPElementTypeGeneratedMedium;
                case 4:
                    return MPElementTypeGeneratedBasic;
                case 5:
                    return MPElementTypeGeneratedShort;
                case 6:
                    return MPElementTypeGeneratedPIN;
                case 7:
                    return (MPElementType)NSNotFound;

                default: {
                    Throw(@"Unsupported row: %d, when selecting generated element type.", indexPath.row);
                }
            }
        }

        case 1: {
            // Stored
            switch (indexPath.row) {
                case 0:
                    return (MPElementType)NSNotFound;
                case 1:
                    return MPElementTypeStoredPersonal;
                case 2:
                    return MPElementTypeStoredDevicePrivate;
                case 3:
                    return (MPElementType)NSNotFound;

                default: {
                    Throw(@"Unsupported row: %d, when selecting stored element type.", indexPath.row);
                }
            }
        }

        default:
            Throw(@"Unsupported section: %d, when selecting element type.", indexPath.section);
    }
}

@end
