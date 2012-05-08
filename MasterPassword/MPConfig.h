//
//  MPConfig.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@interface MPConfig : PearlConfig

@property (nonatomic, retain) NSNumber *saveKey;
@property (nonatomic, retain) NSNumber *rememberKey;

+ (MPConfig *)get;

@end
