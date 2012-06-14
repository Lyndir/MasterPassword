//
//  MPConfig.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPConfig.h"

@interface MPiOSConfig : MPConfig

@property (nonatomic, retain) NSNumber *sendInfo;
@property (nonatomic, retain) NSNumber *helpHidden;
@property (nonatomic, retain) NSNumber *showQuickStart;

+ (MPiOSConfig *)get;

@end
