//
//  MPSiteQuestionEntity+CoreDataProperties.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-04-30.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPSiteQuestionEntity+CoreDataProperties.h"

@implementation MPSiteQuestionEntity (CoreDataProperties)

+ (NSFetchRequest<MPSiteQuestionEntity *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"MPSiteQuestionEntity"];
}

@dynamic keyword;
@dynamic site;

@end
