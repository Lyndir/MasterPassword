//
//  MPConfig.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "Pearl.h"

@interface MPConfig : PearlConfig

@property(nonatomic, retain) NSNumber *sendInfo;
@property(nonatomic, retain) NSNumber *rememberLogin;

@property(nonatomic, retain) NSNumber *iCloudDecided;
@property(nonatomic, retain) NSNumber *checkInconsistency;

@end
