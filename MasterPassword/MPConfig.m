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

    [self.defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSNumber numberWithBool:YES], NSStringFromSelector(@selector(askForReviews)),

                                                   [NSNumber numberWithBool:NO], NSStringFromSelector(@selector(rememberLogin)),
                                                   [NSNumber numberWithBool:NO], NSStringFromSelector(@selector(iCloud)),
                                                   [NSNumber numberWithBool:NO], NSStringFromSelector(@selector(iCloudDecided)),
                                                   nil]];

    self.delegate = [MPAppDelegate get];

    return self;
}

+ (MPConfig *)get {

    return (MPConfig *)[super get];
}

@end
