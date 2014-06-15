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
//  MPPasswordLargeGeneratedCell.h
//  MPPasswordLargeGeneratedCell
//
//  Created by lhunath on 2014-03-19.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordLargeStoredCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPPasswordTypesCell.h"

@interface MPPasswordLargeStoredCell()

@property(strong, nonatomic) IBOutlet UIButton *editButton;

@end

@implementation MPPasswordLargeStoredCell

#pragma mark - Lifecycle

- (void)resolveContentOfCellTypeForElement:(MPElementEntity *)element usingKey:(MPKey *)key result:(void ( ^ )(NSString *))resultBlock {

    if (element.type & MPElementTypeClassStored)
        [element resolveContentUsingKey:key result:resultBlock];
    else
        [super resolveContentOfCellTypeForElement:element usingKey:key result:resultBlock];
}

- (MPElementEntity *)saveContentTypeWithElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context {

    element = [super saveContentTypeWithElement:element saveInContext:context];
    MPElementStoredEntity *storedElement = [self storedElement:element];
    [storedElement.algorithm saveContent:self.contentField.text toElement:storedElement usingKey:[MPiOSAppDelegate get].key];
    [context saveToStore];

    return element;
}

#pragma mark - Actions

- (IBAction)doEditContent:(UIButton *)sender {

    UITextField *textField = self.contentField;
    textField.enabled = YES;
    [textField becomeFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {

    [super textFieldDidEndEditing:textField];

    if (textField == self.contentField) {
        NSString *newContent = textField.text;

        if (self.contentFieldMode == MPContentFieldModePassword)
            [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                MPElementStoredEntity *storedElement = [self storedElementInContext:context];
                if (!storedElement)
                    return;

                [storedElement.algorithm saveContent:newContent toElement:storedElement usingKey:[MPiOSAppDelegate get].key];
                [context saveToStore];

                PearlMainQueue( ^{
                    [self updateAnimated:YES];
                    [PearlOverlay showTemporaryOverlayWithTitle:@"Password Updated" dismissAfter:2];
                } );
            }];
    }
}

#pragma mark - Properties

- (MPElementStoredEntity *)storedElementInContext:(NSManagedObjectContext *)context {

    return [self storedElement:[[MPPasswordTypesCell findAsSuperviewOf:self] elementInContext:context]];
}

- (MPElementStoredEntity *)storedElement:(MPElementEntity *)element {

    if (![element isKindOfClass:[MPElementStoredEntity class]])
        return nil;

    return (MPElementStoredEntity *)element;
}

@end
