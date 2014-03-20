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
//  MPPasswordGeneratedCell.h
//  MPPasswordGeneratedCell
//
//  Created by lhunath on 2014-03-19.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordStoredCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@interface MPPasswordStoredCell()

@property(strong, nonatomic) IBOutlet UIButton *editButton;

@end

@implementation MPPasswordStoredCell

#pragma mark - Actions

- (IBAction)doEditContent:(UIButton *)sender {

    self.contentField.enabled = YES;
    [self.contentField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {

    [super textFieldDidEndEditing:textField];

    if (textField == self.contentField) {
        [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
            if (mainContext) {
                [[self elementInContext:mainContext] setContentObject:self.contentField.text];
                [mainContext saveToStore];
            }

            [self updateAnimated:YES];
        }];
    }
}

#pragma mark - Properties

- (MPElementStoredEntity *)elementInContext:(NSManagedObjectContext *)context {

    return [self storedElement:[super elementInContext:context]];
}

- (MPElementStoredEntity *)storedElement:(MPElementEntity *)element {

    NSAssert([element isKindOfClass:[MPElementStoredEntity class]], @"Element is not of generated type: %@", element.name);
    if (![element isKindOfClass:[MPElementStoredEntity class]])
        return nil;

    return (MPElementStoredEntity *)element;
}

@end
