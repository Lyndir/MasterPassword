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
//  MPElementModel.h
//  MPElementModel
//
//  Created by lhunath on 2/11/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPElementModel.h"
#import "MPSiteEntity.h"
#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"
#import "MPMacAppDelegate.h"

@implementation MPElementModel {
    NSManagedObjectID *_entityOID;
    BOOL _initialized;
}

- (id)initWithEntity:(MPSiteEntity *)entity {

    if (!(self = [super init]))
        return nil;

    [self setEntity:entity];
    _initialized = YES;

    return self;
}

- (void)setEntity:(MPSiteEntity *)entity {

    if ([_entityOID isEqual:entity.objectID])
        return;
    _entityOID = entity.objectID;

    self.algorithm = entity.algorithm;
    self.siteName = entity.name;
    self.lastUsed = entity.lastUsed;
    self.loginName = entity.loginName;
    self.type = entity.type;
    self.typeName = entity.typeName;
    self.uses = entity.uses_;
    self.counter = [entity isKindOfClass:[MPElementGeneratedEntity class]]? [(MPElementGeneratedEntity *)entity counter]: 0;

    // Find all password types and the index of the current type amongst them.
    [self updateContent:entity];
}

- (MPSiteEntity *)entityInContext:(NSManagedObjectContext *)moc {

    if (!_entityOID)
        return nil;

    NSError *error;
    MPSiteEntity *entity = (MPSiteEntity *)[moc existingObjectWithID:_entityOID error:&error];
    if (!entity)
        err( @"Couldn't retrieve active element: %@", error );

    return entity;
}

- (void)setCounter:(NSUInteger)counter {

    if (counter == _counter)
        return;
    _counter = counter;

    if (!_initialized)
        // This wasn't a change to the entity.
        return;

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPSiteEntity *entity = [self entityInContext:context];
        if ([entity isKindOfClass:[MPElementGeneratedEntity class]]) {
            ((MPElementGeneratedEntity *)entity).counter = counter;
            [context saveToStore];

            [self updateContent:entity];
        }
    }];
}

- (BOOL)generated {

    return self.type & MPSiteTypeClassGenerated;
}

- (BOOL)stored {

    return self.type & MPSiteTypeClassStored;
}

- (void)updateContent {

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        [self updateContent:[MPSiteEntity existingObjectWithID:_entityOID inContext:context]];
    }];
}

- (void)updateContent:(MPSiteEntity *)entity {

    static NSRegularExpression *re_anyChar;
    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        re_anyChar = [NSRegularExpression regularExpressionWithPattern:@"." options:0 error:nil];
    } );

    [entity resolvePasswordUsingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        NSString *displayResult = result;
        if ([[MPConfig get].hidePasswords boolValue] && !([NSEvent modifierFlags] & NSAlternateKeyMask))
            displayResult = [displayResult stringByReplacingMatchesOfExpression:re_anyChar withTemplate:@"●"];

        PearlMainQueue( ^{
            self.content = result;
            self.contentDisplay = displayResult;
        } );
    }];
}

@end
