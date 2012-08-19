//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"

@implementation MPConfig
@dynamic rememberLogin, iCloud, iCloudDecided;

- (id)init {

    if (!(self = [super init]))
        return nil;

    [self.defaults registerDefaults:@{NSStringFromSelector(@selector(askForReviews)): @YES,

                                                   NSStringFromSelector(@selector(rememberLogin)): @NO,
                                                   NSStringFromSelector(@selector(iCloud)): @NO,
                                                   NSStringFromSelector(@selector(iCloudDecided)): @NO}];

    self.delegate = [MPAppDelegate get];

    return self;
}

+ (MPConfig *)get {

    return (MPConfig *)[super get];
}

@end
