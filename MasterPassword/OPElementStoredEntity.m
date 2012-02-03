//
//  OPElementStoredEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPElementStoredEntity.h"


@implementation OPElementStoredEntity

@dynamic contentObject;

- (id)content {
    
    assert(self.type & OPElementTypeClassStored);

    return self.contentObject;
}

@end
