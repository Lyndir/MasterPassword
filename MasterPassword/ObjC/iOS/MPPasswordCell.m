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

#import "MPPasswordCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPPasswordGeneratedCell.h"
#import "MPPasswordStoredCell.h"

@interface MPPasswordCell()

@property(strong, nonatomic) IBOutlet UILabel *nameLabel;
@property(strong, nonatomic) IBOutlet UIButton *loginButton;

@property(nonatomic, strong) NSManagedObjectID *elementOID;
@end

@implementation MPPasswordCell

+ (NSString *)reuseIdentifier {

    return NSStringFromClass( self );
}

+ (NSString *)reuseIdentifierForElement:(MPElementEntity *)element {

    if ([element isKindOfClass:[MPElementGeneratedEntity class]])
        return [MPPasswordGeneratedCell reuseIdentifier];

    if ([element isKindOfClass:[MPElementStoredEntity class]])
        return [MPPasswordStoredCell reuseIdentifier];

    return [self reuseIdentifier];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.contentField && [self.contentField.text length]) {
        [self.contentField resignFirstResponder];
        return YES;
    }

    return NO;
}

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    self.layer.cornerRadius = 5;
}

- (void)dealloc {

    [self removeKeyPathObservers];
}

#pragma mark - Actions

- (IBAction)doUser:(id)sender {
}

#pragma mark - Properties

- (void)setTransientSite:(NSString *)name {

    _transientSite = name;
    _elementOID = nil;

    [self updateAnimated:YES];
}

- (void)setElement:(MPElementEntity *)element {

    self.elementOID = [element objectID];
}

- (void)setElementOID:(NSManagedObjectID *)elementOID {

    _transientSite = nil;
    _elementOID = elementOID;

    [self updateAnimated:YES];
}

- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context {

    NSError *error = nil;
    MPElementEntity *element = _elementOID? (MPElementEntity *)[context existingObjectWithID:_elementOID error:&error]: nil;
    if (_elementOID && !element)
    err(@"Failed to load element: %@", error);

    return element;
}

#pragma mark - Private

- (void)updateAnimated:(BOOL)animated {

    Weakify(self);

    if (self.transientSite) {
        self.alpha = 1;
        self.nameLabel.text = self.transientSite;
        self.contentField.text = nil;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPKey *key = [MPiOSAppDelegate get].key;
            if (!key) {
                self.alpha = 0;
                return;
            }

            MPElementType type = [[MPiOSAppDelegate get] activeUserInContext:context].defaultType;
            if (!type)
                type = MPElementTypeGeneratedLong;
            NSString *newContent = [MPAlgorithmDefault generateContentNamed:self.transientSite ofType:type withCounter:1 usingKey:key];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.contentField.text = newContent;
            }];
        }];
    }
    else if (self.elementOID) {
        NSManagedObjectContext *mainContext = [MPiOSAppDelegate managedObjectContextForMainThreadIfReady];
        [mainContext performBlock:^{
            [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
                Strongify(self);
                NSError *error = nil;
                MPKey *key = [MPiOSAppDelegate get].key;
                if (!key) {
                    self.alpha = 0;
                    return;
                }

                MPElementEntity *element = (MPElementEntity *)[mainContext existingObjectWithID:_elementOID error:&error];
                if (!element) {
                    err(@"Failed to load element: %@", error);
                    self.alpha = 0;
                    return;
                }

                self.alpha = 1;
                [self populateWithElement:element];

                [element resolveContentUsingKey:key result:^(NSString *result) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        Strongify(self);
                        self.contentField.text = result;
                    }];
                }];
            }];
        }];
    }
    else {
        [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
            self.alpha = 0;
        }];
    }
}

- (void)populateWithElement:(MPElementEntity *)element {

    self.nameLabel.text = element.name;
    self.contentField.text = nil;
}

@end
