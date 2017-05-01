//
//  MPSiteEntity+CoreDataProperties.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-04-30.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPSiteEntity+CoreDataProperties.h"

@implementation MPSiteEntity (CoreDataProperties)

+ (NSFetchRequest<MPSiteEntity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MPSiteEntity"];
}

@dynamic content;
@dynamic lastUsed;
@dynamic loginGenerated_;
@dynamic loginName;
@dynamic name;
@dynamic requiresExplicitMigration_;
@dynamic type_;
@dynamic uses_;
@dynamic version_;
@dynamic url;
@dynamic questions;
@dynamic user;

@end
