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
@end

@implementation MPElementModel {
}

- (id)initWithEntity:(MPElementEntity *)entity {

    if (!(self = [super init]))
        return nil;

    self.site = entity.name;
    self.lastUsed = entity.lastUsed;
    self.loginName = entity.loginName;
    self.type = entity.typeName;
    self.uses = entity.uses_;
    self.content = [entity.algorithm resolveContentForElement:entity usingKey:[MPAppDelegate_Shared get].key];
    self.entityOID = entity.objectID;

    return self;
}

- (MPElementEntity *)entityForMainThread {

    return [self entityInContext:[MPMacAppDelegate managedObjectContextForMainThreadIfReady]];
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

@end
