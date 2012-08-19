//
//  MPElementStoredEntity.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2012-08-19.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPElementEntity.h"


@interface MPElementStoredEntity : MPElementEntity

@property (nonatomic, retain) id contentObject;

@end
