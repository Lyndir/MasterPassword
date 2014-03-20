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

#import "MPPasswordGeneratedCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@interface MPPasswordGeneratedCell()

@property(strong, nonatomic) IBOutlet UILabel *counterLabel;
@property(strong, nonatomic) IBOutlet UIButton *counterButton;
@property(strong, nonatomic) IBOutlet UIButton *upgradeButton;

@end

@implementation MPPasswordGeneratedCell

- (void)populateWithElement:(MPElementEntity *)element {

    [super populateWithElement:element];

    MPElementGeneratedEntity *generatedElement = [self generatedElement:element];
    self.counterLabel.text = strf(@"%lu", (unsigned long)generatedElement.counter);

    if (element.requiresExplicitMigration) {
        self.upgradeButton.alpha = 1;
        self.counterButton.alpha = 0;
    } else {
        self.upgradeButton.alpha = 0;
        self.counterButton.alpha = 1;
    }
}

#pragma mark - Actions

- (IBAction)doUpgrade:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
        [[self elementInContext:mainContext] migrateExplicitly:YES];
        [mainContext saveToStore];

        [self updateAnimated:YES];
    }];
}

- (IBAction)doIncrementCounter:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
        ++[self elementInContext:mainContext].counter;
        [mainContext saveToStore];

        [self updateAnimated:YES];
    }];
}

#pragma mark - Properties

- (MPElementGeneratedEntity *)elementInContext:(NSManagedObjectContext *)context {

    return [self generatedElement:[super elementInContext:context]];
}

- (MPElementGeneratedEntity *)generatedElement:(MPElementEntity *)element {

    NSAssert([element isKindOfClass:[MPElementGeneratedEntity class]], @"Element is not of generated type: %@", element.name);
    if (![element isKindOfClass:[MPElementGeneratedEntity class]])
        return nil;

    return (MPElementGeneratedEntity *)element;
}

@end
