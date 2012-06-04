//
//  MPConfig.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@interface MPConfig : PearlConfig

@property (nonatomic, retain) NSNumber *rememberLogin;

@property (nonatomic, retain) NSNumber *iCloud;
@property (nonatomic, retain) NSNumber *iCloudDecided;

+ (MPConfig *)get;

@end
