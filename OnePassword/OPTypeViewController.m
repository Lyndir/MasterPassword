//
//  OPTypeViewController.m
//  OnePassword
//
//  Created by Maarten Billemont on 27/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPTypeViewController.h"

@implementation OPTypeViewController
@synthesize delegate;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];

    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    assert(self.navigationController.topViewController == self);

    OPElementType type;
    switch (indexPath.section) {
        case 0: {
            // Calculated
            switch (indexPath.row) {
                case 0:
                    type = OPElementTypeCalculatedLong;
                    break;
                case 1:
                    type = OPElementTypeCalculatedMedium;
                    break;
                case 2:
                    type = OPElementTypeCalculatedShort;
                    break;
                case 3:
                    type = OPElementTypeCalculatedBasic;
                    break;
                case 4:
                    type = OPElementTypeCalculatedPIN;
                    break;
                    
                default:
                    [NSException raise:NSInternalInconsistencyException
                                format:@"Unsupported row: %d, when selecting calculated element type.", indexPath.row];
            }
            break;
        }
            
        case 1: {
            // Stored
            switch (indexPath.row) {
                case 0:
                    type = OPElementTypeStoredPersonal;
                    break;
                case 1:
                    type = OPElementTypeStoredDevicePrivate;
                    break;
                    
                default:
                    [NSException raise:NSInternalInconsistencyException
                                format:@"Unsupported row: %d, when selecting stored element type.", indexPath.row];
            }
            break;
        }
            
        default:
            [NSException raise:NSInternalInconsistencyException
                        format:@"Unsupported section: %d, when selecting element type.", indexPath.section];
    }
    
    [delegate didSelectType:type];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
