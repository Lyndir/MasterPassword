//
//  MPUserEntity+CoreDataProperties.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-04-30.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPUserEntity+CoreDataProperties.h"

@implementation MPUserEntity (CoreDataProperties)

+ (NSFetchRequest<MPUserEntity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MPUserEntity"];
}

@dynamic avatar_;
@dynamic defaultType_;
@dynamic keyID;
@dynamic lastUsed;
@dynamic name;
@dynamic saveKey_;
@dynamic touchID_;
@dynamic version_;
@dynamic sites;

@end
