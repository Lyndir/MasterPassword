//
//  MPElementStoredEntity.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2014-09-14.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPElementEntity.h"


@interface MPElementStoredEntity : MPElementEntity

@property (nonatomic, retain) NSData * contentObject;

@end
