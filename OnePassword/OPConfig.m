//
//  OPConfig.m
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPConfig.h"

@implementation OPConfig

@dynamic dataStoreError, keyPhraseHash, rememberKeyPhrase;


-(id) init {
    
    if(!(self = [super init]))
        return self;
    
    [self.defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO],                                  NSStringFromSelector(@selector(dataStoreError)),
                                     [NSNumber numberWithBool:NO],                                  NSStringFromSelector(@selector(rememberKeyPhrase)),
                                     
                                     nil]];
    
    return self;
}

+ (OPConfig *)get {
    
    return (OPConfig *)[super get];
}

@end
