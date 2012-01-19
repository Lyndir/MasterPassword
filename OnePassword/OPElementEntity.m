//
//  OPElementEntity.m
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPElementEntity.h"


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
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Content implementation missing." userInfo:nil];
}

- (NSString *)contentDescription {
    
    return [[self content] description];
}

@end
