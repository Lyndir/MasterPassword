//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPiOSConfig.h"

@implementation MPiOSConfig
@dynamic helpHidden, showQuickStart;

- (id)init {
    
    if(!(self = [super init]))
        return self;
    
    [self.defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO],                                  NSStringFromSelector(@selector(helpHidden)),
                                     [NSNumber numberWithBool:YES],                                 NSStringFromSelector(@selector(showQuickStart)),
                                     nil]];
    
    return self;
}

+ (MPiOSConfig *)get {
    
    return (MPiOSConfig *)[super get];
}

@end
