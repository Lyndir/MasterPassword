//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPConfig.h"

@implementation MPConfig
@dynamic dataStoreError, storeKey, rememberKey;

- (id)init {
    
    if(!(self = [super init]))
        return self;
    
    [self.defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO],                                  NSStringFromSelector(@selector(dataStoreError)),
                                     [NSNumber numberWithBool:NO],                                  NSStringFromSelector(@selector(storeKey)),
                                     [NSNumber numberWithBool:YES],                                 NSStringFromSelector(@selector(rememberKey)),
                                     nil]];
    
    return self;
}

+ (MPConfig *)get {
    
    return (MPConfig *)[super get];
}

@end
