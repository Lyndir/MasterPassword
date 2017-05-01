//
//  MPStoredSiteEntity+CoreDataProperties.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-05-01.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPStoredSiteEntity+CoreDataProperties.h"

@implementation MPStoredSiteEntity (CoreDataProperties)

+ (NSFetchRequest<MPStoredSiteEntity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MPStoredSiteEntity"];
}

@dynamic contentObject;

@end
