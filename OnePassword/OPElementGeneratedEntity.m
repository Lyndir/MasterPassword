//
//  OPElementGeneratedEntity.m
//  OnePassword
//
//  Created by Maarten Billemont on 16/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPElementGeneratedEntity.h"
#import "OPAppDelegate.h"


@implementation OPElementGeneratedEntity

@dynamic counter;

- (id)content {

    if (![self.name length])
        return nil;
    
    if (self.type & OPElementTypeCalculated)
        return OPCalculateContent(self.type, self.name, [OPAppDelegate get].keyPhrase, self.counter);
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unsupported type: %d", self.type] userInfo:nil];
}

@end
