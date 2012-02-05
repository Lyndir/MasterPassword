//
//  MPElementStoredEntity.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MPElementEntity.h"


@interface MPElementStoredEntity : MPElementEntity

@property (nonatomic, retain, readwrite) id content;

@end
