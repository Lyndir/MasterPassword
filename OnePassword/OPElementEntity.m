//
//  OPElementEntity.m
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPElementEntity.h"
#import "OPAppDelegate.h"


@implementation OPElementEntity

@dynamic name;
@dynamic type;
@dynamic uses;
@dynamic lastUsed;
@dynamic contentUTI;
@dynamic contentType;

- (void)use {
    
    ++self.uses;
    self.lastUsed = [[NSDate date] timeIntervalSinceReferenceDate];
}

- (id)content {
    
    if (![self.name length])
        return nil;
    
    if (self.type & OPElementTypeCalculated)
        return OPCalculateContent(self.type, self.name, [OPAppDelegate get].keyPhrase);

    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Unsupported type: %d", self.type] userInfo:nil];
}

- (NSString *)contentDescription {
    
    return [[self content] description];
}

@end
