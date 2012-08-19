//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@implementation MPiOSConfig
@dynamic sendInfo, helpHidden, siteInfoHidden, showQuickStart, actionsTipShown, typeTipShown, loginNameTipShown;

- (id)init {

    if (!(self = [super init]))
        return self;

    [self.defaults registerDefaults:@{NSStringFromSelector(@selector(sendInfo)): @NO,
                                                   NSStringFromSelector(@selector(helpHidden)): @NO,
                                                   NSStringFromSelector(@selector(siteInfoHidden)): @YES,
                                                   NSStringFromSelector(@selector(showQuickStart)): @YES,
                                                   NSStringFromSelector(@selector(iTunesID)): @"510296984",
                                                   NSStringFromSelector(@selector(actionsTipShown)): PearlBoolNot(self.firstRun),
                                                   NSStringFromSelector(@selector(typeTipShown)): PearlBoolNot(self.firstRun),
                                                   NSStringFromSelector(@selector(loginNameTipShown)): PearlBool(NO)}];

    return self;
}

+ (MPiOSConfig *)get {

    return (MPiOSConfig *)[super get];
}

@end
