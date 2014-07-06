//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@implementation MPiOSConfig

@dynamic helpHidden, siteInfoHidden, showSetup, actionsTipShown, typeTipShown, loginNameTipShown, traceMode, iCloudEnabled, dictationSearch;

- (id)init {

    if (!(self = [super init]))
        return self;

    [self.defaults registerDefaults:@{
            NSStringFromSelector( @selector(helpHidden) )        : @NO,
            NSStringFromSelector( @selector(siteInfoHidden) )    : @YES,
            NSStringFromSelector( @selector(showSetup) )         : @YES,
            NSStringFromSelector( @selector(iTunesID) )          : @"510296984",
            NSStringFromSelector( @selector(actionsTipShown) )   : @(!self.firstRun),
            NSStringFromSelector( @selector(typeTipShown) )      : @(!self.firstRun),
            NSStringFromSelector( @selector(loginNameTipShown) ) : @NO,
            NSStringFromSelector( @selector(traceMode) )         : @NO,
            NSStringFromSelector( @selector(iCloudEnabled) )     : @NO,
            NSStringFromSelector( @selector(dictationSearch) )   : @NO
    }];

    return self;
}

@end
