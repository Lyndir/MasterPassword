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

@interface MPElementModel()

@property(nonatomic, strong) NSManagedObjectID *entityOID;
@property(nonatomic, readwrite) NSString *content;
@property(nonatomic, readwrite) MPElementType type;
@property(nonatomic, readwrite) NSString *typeName;
@end

@implementation MPElementModel {
    NSMutableDictionary *_typesByName;
}

- (id)initWithEntity:(MPElementEntity *)entity {

    if (!(self = [super init]))
        return nil;

    _site = entity.name;
    _lastUsed = entity.lastUsed;
    _loginName = entity.loginName;
    _type = entity.type;
    _typeName = entity.typeName;
    _uses = entity.uses_;
    _counter = [entity isKindOfClass:[MPElementGeneratedEntity class]]? [(MPElementGeneratedEntity *)entity counter]: 0;
    _content = [entity.algorithm resolveContentForElement:entity usingKey:[MPAppDelegate_Shared get].key];
    _algorithm = entity.algorithm;
    _entityOID = entity.objectID;

    // Find all password types and the index of the current type amongst them.
    _typesByName = [NSMutableDictionary dictionary];
    MPElementType type = _type;
    do {
        [_typesByName setObject:@(type) forKey:[_algorithm shortNameOfType:type]];
    } while (_type != (type = [_algorithm nextType:type]));
    _types = [_typesByName keysSortedByValueUsingSelector:@selector(compare:)];
    _typeIndex = [[[_typesByName allValues] sortedArrayUsingSelector:@selector(compare:)] indexOfObject:@(_type)];

    return self;
}

- (MPElementEntity *)entityInContext:(NSManagedObjectContext *)moc {

    if (!_entityOID)
        return nil;

    NSError *error;
    MPElementEntity *entity = (MPElementEntity *)[moc existingObjectWithID:_entityOID error:&error];
    if (!entity)
    err(@"Couldn't retrieve active element: %@", error);

    return entity;
}

- (void)setCounter:(NSUInteger)counter {

    if (counter == _counter)
        return;
    _counter = counter;

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPElementEntity *entity = [self entityInContext:context];
        if ([entity isKindOfClass:[MPElementGeneratedEntity class]]) {
            ((MPElementGeneratedEntity *)entity).counter = counter;
            [context saveToStore];

            self.content = [entity.algorithm resolveContentForElement:entity usingKey:[MPAppDelegate_Shared get].key];
        }
    }];
}

- (void)setTypeIndex:(NSUInteger)typeIndex {

    if (typeIndex == _typeIndex)
        return;
    _typeIndex = typeIndex;

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPElementEntity *entity = [self entityInContext:context];
        entity.type_ = _typesByName[_types[typeIndex]];
        [context saveToStore];

        self.type = entity.type;
        self.typeName = entity.typeName;
        self.content = [entity.algorithm resolveContentForElement:entity usingKey:[MPAppDelegate_Shared get].key];
    }];
}

@end
