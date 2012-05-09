//
//  MPElementGeneratedEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 16/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementGeneratedEntity.h"
#import "MPAppDelegate_Shared.h"


@implementation MPElementGeneratedEntity

@dynamic counter;

- (id)content {

    if (!(self.type & MPElementTypeClassGenerated)) {
        err(@"Corrupt element: %@, type: %d, does not match class: %@", self.name, self.type, [self class]);
        return nil;
    }
    
    if (![self.name length])
        return nil;
    
    return MPCalculateContent((unsigned)self.type, self.name, [MPAppDelegate get].key, self.counter);
}

@end
