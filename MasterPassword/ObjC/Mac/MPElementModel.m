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
#import "MPElementEntity.h"
#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"
#import "MPMacAppDelegate.h"

@implementation MPElementModel {
    NSManagedObjectID *_entityOID;
    NSMutableDictionary *_typesByName;
    BOOL _initialized;
}

- (id)initWithEntity:(MPElementEntity *)entity {

    if (!(self = [super init]))
        return nil;

    [self setEntity:entity];
    _initialized = YES;

    return self;
}

- (void)setEntity:(MPElementEntity *)entity {

    if ([_entityOID isEqual:entity.objectID])
        return;
    _entityOID = entity.objectID;

    self.algorithm = entity.algorithm;
    self.site = entity.name;
    self.lastUsed = entity.lastUsed;
    self.loginName = entity.loginName;
    self.type = entity.type;
    self.typeName = entity.typeName;
    self.uses = entity.uses_;
    self.counter = [entity isKindOfClass:[MPElementGeneratedEntity class]]? [(MPElementGeneratedEntity *)entity counter]: 0;

    // Find all password types and the index of the current type amongst them.
    _typesByName = [NSMutableDictionary dictionary];
    MPElementType type = self.type;
    do {
        [_typesByName setObject:@(type) forKey:[self.algorithm shortNameOfType:type]];
    } while (self.type != (type = [self.algorithm nextType:type]));
    self.typeNames = [_typesByName keysSortedByValueUsingSelector:@selector( compare: )];
    self.typeIndex = [[[_typesByName allValues] sortedArrayUsingSelector:@selector( compare: )] indexOfObject:@(self.type)];

    [entity.algorithm resolveContentForElement:entity usingKey:[MPAppDelegate_Shared get].key
                                        result:^(NSString *result) {
        PearlMainQueue( ^{ self.content = result; } );
    }];
}

- (MPElementEntity *)entityInContext:(NSManagedObjectContext *)moc {

    if (!_entityOID)
        return nil;

    NSError *error;
    MPElementEntity *entity = (MPElementEntity *)[moc existingObjectWithID:_entityOID error:&error];
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
        MPElementEntity *entity = [self entityInContext:context];
        if ([entity isKindOfClass:[MPElementGeneratedEntity class]]) {
            ((MPElementGeneratedEntity *)entity).counter = counter;
            [context saveToStore];

            [entity.algorithm resolveContentForElement:entity usingKey:[MPAppDelegate_Shared get].key
                                                result:^(NSString *result) {
                PearlMainQueue( ^{ self.content = result; } );
            }];
        }
    }];
}

- (void)setTypeIndex:(NSUInteger)typeIndex {

    if (typeIndex == _typeIndex)
        return;
    _typeIndex = typeIndex;

    if (!_initialized)
        // This wasn't a change to the entity.
        return;

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        [self setEntity:[[MPAppDelegate_Shared get] changeElement:[self entityInContext:context] saveInContext:context
                                                           toType:[_typesByName[self.typeNames[typeIndex]] unsignedIntegerValue]]];
    }];
}

@end
