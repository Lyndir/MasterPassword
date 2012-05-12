//
//  MPElementGeneratedEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 16/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementGeneratedEntity.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"


@implementation MPElementGeneratedEntity

@dynamic counter;

- (id)content {

    if (!(self.type & MPElementTypeClassGenerated)) {
        err(@"Corrupt element: %@, type: %d is not in MPElementTypeClassGenerated", self.name, self.type);
        return nil;
    }
    
    if (![self.name length])
        return nil;
    
    return MPCalculateContent((unsigned)self.type, self.name, [MPAppDelegate get].key, self.counter);
}

@end
