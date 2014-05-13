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
//  MPPasswordElementCell.h
//  MPPasswordElementCell
//
//  Created by lhunath on 2014-04-03.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordElementCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPPasswordElementCell {
    NSManagedObjectID *_elementOID;
}

- (void)prepareForReuse {

    _elementOID = nil;
    _transientSite = nil;

    [super prepareForReuse];
}

- (void)setTransientSite:(NSString *)transientSite {

    if ([_transientSite isEqualToString:transientSite])
        return;

    dbg(@"transientSite: %@ -> %@", _transientSite, transientSite);

    _transientSite = transientSite;
    _elementOID = nil;

    [self updateAnimated:YES];
    [self reloadData];
}

- (void)setElement:(MPElementEntity *)element {

    NSManagedObjectID *newElementOID = element.objectID;
    NSAssert(!newElementOID.isTemporaryID, @"Element doesn't have a permanent objectID: %@", element);
    if ([_elementOID isEqual:newElementOID])
        return;

    dbg(@"element: %@ -> %@", _elementOID, newElementOID);

    _transientSite = nil;
    _elementOID = newElementOID;

    [self updateAnimated:YES];
    [self reloadData];
}

- (MPElementEntity *)mainElement {

    return [self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
}

- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context {

    return [MPElementEntity existingObjectWithID:_elementOID inContext:context];
}

- (void)reloadData {

    if (self.transientSite)
        PearlMainQueue( ^{
            [self reloadWithTransientSite:self.transientSite];
        } );
    else
        [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlockAndWait:^(NSManagedObjectContext *mainContext) {
            [self reloadWithElement:[self elementInContext:mainContext]];
        }];
}

@end
