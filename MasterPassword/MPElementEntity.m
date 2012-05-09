//
//  MPElementEntity.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementEntity.h"


@implementation MPElementEntity

@dynamic name;
@dynamic keyID;
@dynamic type;
@dynamic uses;
@dynamic lastUsed;

- (int16_t)use {
    
    self.lastUsed = [[NSDate date] timeIntervalSinceReferenceDate];
    return ++self.uses;
}

- (id)content {
    
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Content implementation missing." userInfo:nil];
}

- (NSString *)exportContent {
    
    return nil;
}

- (void)importContent:(NSString *)content {
    
}

- (NSString *)description {
    
    return str(@"%@:%@", [self class], [self name]);
}

- (NSString *)debugDescription {
    
    return str(@"{%@: name=%@, keyID=%@, type=%d, uses=%d, lastUsed=%@}",
               NSStringFromClass([self class]), self.name, self.keyID, self.type, self.uses, self.lastUsed);
}

@end
