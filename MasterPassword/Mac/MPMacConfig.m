//
//  MPMacConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@implementation MPMacConfig

@dynamic usedUserName;

- (id)init {

    if (!(self = [super init]))
        return self;

    [self.defaults registerDefaults:@{NSStringFromSelector(@selector(iTunesID)): @"510296984"}];

    return self;
}

+ (MPMacConfig *)get {

    return (MPMacConfig *)[super get];
}

@end
