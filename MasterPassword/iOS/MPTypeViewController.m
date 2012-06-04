//
//  MPTypeViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 27/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPTypeViewController.h"


@interface MPTypeViewController ()

- (MPElementType)typeAtIndexPath:(NSIndexPath *)indexPath;

@end

@implementation MPTypeViewController
@synthesize delegate;
@synthesize recommendedTipContainer;

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    
    self.recommendedTipContainer.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    
    if ([[MPiOSConfig get].firstRun boolValue])
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.recommendedTipContainer.alpha = 1;
        } completion:^(BOOL finished) {
            if (finished) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.2f animations:^{
                        self.recommendedTipContainer.alpha = 0;
                    }];
                });
            }
        }];
    
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ui_background"]];
    
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return YES;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if ([delegate respondsToSelector:@selector(selectedType)])
        if ([delegate selectedType] == [self typeAtIndexPath:indexPath])
            [cell enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
                if ([subview isKindOfClass:[UIImageView class]]) {
                    UIImageView *imageView = ((UIImageView *)subview);
                    if (!imageView.highlightedImage)
                        imageView.highlightedImage = [imageView.image highlightedImage];
                    imageView.highlighted = YES;
                    *stop = YES;
                }
            } recurse:NO];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    assert(self.navigationController.topViewController == self);
    
    [delegate didSelectType:[self typeAtIndexPath:indexPath]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (MPElementType)typeAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case 0: {
            // Generated
            switch (indexPath.row) {
                case 0:
                    return MPElementTypeGeneratedLong;
                case 1:
                    return MPElementTypeGeneratedMedium;
                case 2:
                    return MPElementTypeGeneratedShort;
                case 3:
                    return MPElementTypeGeneratedBasic;
                case 4:
                    return MPElementTypeGeneratedPIN;
                    
                default:
                    [NSException raise:NSInternalInconsistencyException
                                format:@"Unsupported row: %d, when selecting generated element type.", indexPath.row];
            }
            break;
        }
            
        case 1: {
            // Stored
            switch (indexPath.row) {
                case 0:
                    return MPElementTypeStoredPersonal;
                case 1:
                    return MPElementTypeStoredDevicePrivate;
                    
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
    
    @throw nil;
}

- (void)viewDidUnload {
    [self setRecommendedTipContainer:nil];
    [super viewDidUnload];
}
@end
