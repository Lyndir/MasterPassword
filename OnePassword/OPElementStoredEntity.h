//
//  OPElementStoredEntity.h
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "OPElementEntity.h"


@interface OPElementStoredEntity : OPElementEntity

@property (nonatomic, retain) id contentObject;

@end
