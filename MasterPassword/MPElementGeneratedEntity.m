//
//  MPElementGeneratedEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 16/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementGeneratedEntity.h"
#import "MPAppDelegate_Key.h"


@implementation MPElementGeneratedEntity

@dynamic counter;

- (id)content {

    assert(self.type & MPElementTypeClassCalculated);
    
    if (![self.name length])
        return nil;
    
    if (self.type & MPElementTypeClassCalculated)
        return MPCalculateContent(self.type, self.name, [MPAppDelegate get].key, self.counter);
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unsupported type: %d", self.type] userInfo:nil];
}

@end
