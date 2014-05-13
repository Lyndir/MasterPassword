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
//  MPAvatarCell.h
//  MPAvatarCell
//
//  Created by lhunath on 2014-03-11.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordLargeCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPPasswordLargeGeneratedCell.h"
#import "MPPasswordLargeStoredCell.h"
#import "MPPasswordTypesCell.h"
#import "MPPasswordLargeDeleteCell.h"

@implementation MPPasswordLargeCell

#pragma mark - Life

+ (instancetype)dequeueCellWithType:(MPElementType)type fromCollectionView:(UICollectionView *)collectionView
                        atIndexPath:(NSIndexPath *)indexPath {

    NSString *reuseIdentifier;
    if (indexPath.item == 0)
        reuseIdentifier = NSStringFromClass( [MPPasswordLargeDeleteCell class] );
    else if (type & MPElementTypeClassGenerated)
        reuseIdentifier = NSStringFromClass( [MPPasswordLargeGeneratedCell class] );
    else if (type & MPElementTypeClassStored)
        reuseIdentifier = NSStringFromClass( [MPPasswordLargeStoredCell class] );
    else
            Throw(@"Unexpected password type: %@", [MPAlgorithmDefault nameOfType:type]);

    MPPasswordLargeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.type = type;

    return cell;
}

- (void)awakeFromNib {

    [super awakeFromNib];

    [self prepareForReuse];
}

- (void)prepareForReuse {

    _contentFieldMode = 0;
    self.contentField.text = nil;

    [super prepareForReuse];
}

- (void)reloadWithTransientSite:(NSString *)siteName {

    [super reloadWithTransientSite:siteName];

    self.loginButton.alpha = 0;
    self.upgradeButton.alpha = 0;
    self.typeLabel.text = [MPAlgorithmDefault nameOfType:self.type];
    if (self.type & MPElementTypeClassStored) {
        self.contentField.enabled = YES;
        self.contentField.placeholder = strl( @"Set custom password" );
    }
    else if (self.type & MPElementTypeClassGenerated) {
        self.contentField.enabled = NO;
        self.contentField.placeholder = strl( @"Generating..." );
    }
    else {
        self.contentField.enabled = NO;
        self.contentField.placeholder = nil;
    }

    self.contentField.text = nil;
    [self resolveContentOfCellTypeForTransientSite:siteName usingKey:[MPiOSAppDelegate get].key result:^(NSString *string) {
        PearlMainQueue( ^{ self.contentField.text = string; } );
    }];
}

- (void)reloadWithElement:(MPElementEntity *)mainElement {

    [super reloadWithElement:mainElement];

    if (!mainElement) {
        self.loginButton.alpha = 0;
        self.nameLabel.text = @"";
        self.contentField.text = @"";
        return;
    }

    self.nameLabel.alpha = 1;
    self.loginButton.alpha = 1;
    if (self.type != (MPElementType)NSNotFound)
        self.typeLabel.text = [mainElement.algorithm nameOfType:self.type];

    if (mainElement.requiresExplicitMigration)
        self.upgradeButton.alpha = 1;
    else
        self.upgradeButton.alpha = 0;

    switch (self.contentFieldMode) {
        case MPContentFieldModePassword: {
            if (self.type & MPElementTypeClassStored) {
                self.contentField.enabled = YES;
                self.contentField.placeholder = strl( @"Set custom password" );
            }
            else if (self.type & MPElementTypeClassGenerated) {
                self.contentField.enabled = NO;
                self.contentField.placeholder = strl( @"Generating..." );
            }
            else {
                self.contentField.enabled = NO;
                self.contentField.placeholder = nil;
            }

            self.contentField.text = nil;
            MPKey *key = [MPiOSAppDelegate get].key;
            if (self.type == mainElement.type)
                [mainElement resolveContentUsingKey:key result:^(NSString *string) {
                    PearlMainQueue( ^{ self.contentField.text = string; } );
                }];
            else
                [self resolveContentOfCellTypeForElement:mainElement usingKey:key result:^(NSString *string) {
                    PearlMainQueue( ^{ self.contentField.text = string; } );
                }];
            break;
        }
        case MPContentFieldModeUser: {
            self.contentField.enabled = YES;
            self.contentField.placeholder = strl( @"Enter login name" );
            self.contentField.text = mainElement.loginName;
            break;
        }
    }
}

- (void)resolveContentOfCellTypeForTransientSite:(NSString *)siteName usingKey:(MPKey *)key result:(void (^)(NSString *))resultBlock {

    resultBlock( nil );
}

- (void)resolveContentOfCellTypeForElement:(MPElementEntity *)element usingKey:(MPKey *)key result:(void (^)(NSString *))resultBlock {

    resultBlock( nil );
}

- (MPElementEntity *)saveContentTypeWithElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context {

    return [[MPiOSAppDelegate get] changeElement:element saveInContext:context toType:self.type];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.contentField) {
        NSString *newContent = textField.text;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPElementEntity *element = [[MPPasswordElementCell findAsSuperviewOf:self] elementInContext:context];
            if (!element)
                return;

            switch (self.contentFieldMode) {
                case MPContentFieldModePassword:
                    break;
                case MPContentFieldModeUser: {
                    element.loginName = newContent;
                    [context saveToStore];

                    PearlMainQueue( ^{
                        [self updateAnimated:YES];
                        [PearlOverlay showTemporaryOverlayWithTitle:@"Login Updated" dismissAfter:2];
                    } );
                    break;
                }
            }
        }];
    }
}

#pragma mark - Actions

- (IBAction)doUser:(id)sender {

    switch (self.contentFieldMode) {
        case MPContentFieldModePassword: {
            self.contentFieldMode = MPContentFieldModeUser;
            break;
        }
        case MPContentFieldModeUser: {
            self.contentFieldMode = MPContentFieldModePassword;
            break;
        }
    }
}

- (IBAction)doUpgrade:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        if ([[[MPPasswordElementCell findAsSuperviewOf:self] elementInContext:context] migrateExplicitly:YES]) {
            [context saveToStore];

            PearlMainQueue( ^{
                [[MPPasswordElementCell findAsSuperviewOf:self] reloadData];
                [PearlOverlay showTemporaryOverlayWithTitle:@"Site Upgraded" dismissAfter:2];
            } );
        }
        else
            PearlMainQueue( ^{
                [PearlOverlay showTemporaryOverlayWithTitle:@"Site Not Upgraded" dismissAfter:2];
            } );
    }];
}

#pragma mark - Properties

- (void)setContentFieldMode:(MPContentFieldMode)contentFieldMode {

    if (_contentFieldMode == contentFieldMode)
        return;

    _contentFieldMode = contentFieldMode;

    [[MPPasswordElementCell findAsSuperviewOf:self] reloadData];
}

@end
