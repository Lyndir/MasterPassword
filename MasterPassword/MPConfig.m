//
//  MPConfig.m
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPConfig.h"
#import "MPAppDelegate.h"

@implementation MPConfig
@dynamic saveKey, rememberKey, iCloud, iCloudDecided;

- (id)init {
    
    if(!(self = [super init]))
        return nil;
    
    [self.defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO],                          NSStringFromSelector(@selector(saveKey)),
                                     [NSNumber numberWithBool:YES],                         NSStringFromSelector(@selector(rememberKey)),
                                     [NSNumber numberWithBool:NO],                          NSStringFromSelector(@selector(iCloud)),
                                     [NSNumber numberWithBool:NO],                          NSStringFromSelector(@selector(iCloudDecided)),
                                     nil]];
    
    self.delegate = [MPAppDelegate get];
    
    return self;
}

+ (MPConfig *)get {
    
    return (MPConfig *)[super get];
}

@end
