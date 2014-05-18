//
//  MPElementStoredEntity.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2013-01-29.
//  Copyright (c) 2013 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPElementEntity.h"

@interface MPElementStoredEntity : MPElementEntity

@property(nonatomic, retain) NSData *contentObject;

@end
