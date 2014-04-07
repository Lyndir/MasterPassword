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

    if ([_elementOID isEqual:element.objectID])
        return;

    dbg(@"element: %@ -> %@", _elementOID, element.objectID);

    _transientSite = nil;
    _elementOID = element.objectID;

    [self updateAnimated:YES];
    [self reloadData];
}

- (MPElementEntity *)mainElement {

    return [self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
}

- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context {

    if (!_elementOID)
        return nil;

    NSError *error = nil;
    MPElementEntity *element = _elementOID? (MPElementEntity *)[context existingObjectWithID:_elementOID error:&error]: nil;
    if (_elementOID && !element)
    err(@"Failed to load element: %@", error);

    return element;
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
