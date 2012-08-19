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
@property (nonatomic, retain) NSNumber *siteInfoHidden;
@property (nonatomic, retain) NSNumber *showQuickStart;
@property (nonatomic, retain) NSNumber *actionsTipShown;
@property (nonatomic, retain) NSNumber *typeTipShown;
@property (nonatomic, retain) NSNumber *loginNameTipShown;

+ (MPiOSConfig *)get;

@end
