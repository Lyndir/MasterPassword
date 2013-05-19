//
//  MPMacConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@implementation MPMacConfig

@dynamic usedUserName;
@dynamic dialogStyleHUD;
@dynamic showAppWindow;

- (id)init {

    if (!(self = [super init]))
        return self;

    [self.defaults registerDefaults:@{
            NSStringFromSelector( @selector(iTunesID) )       : @"510296984",
            NSStringFromSelector( @selector(dialogStyleHUD) ) : @NO,
            NSStringFromSelector( @selector(showAppWindow) )  : @YES
    }];

    return self;
}

@end
