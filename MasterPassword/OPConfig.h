//
//  OPConfig.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@interface OPConfig : Config

@property (nonatomic, retain) NSNumber *dataStoreError;
@property (nonatomic, retain) NSNumber *storeKeyPhrase;
@property (nonatomic, retain) NSNumber *rememberKeyPhrase;
@property (nonatomic, retain) NSNumber *forgetKeyPhrase;
@property (nonatomic, retain) NSNumber *helpHidden;
@property (nonatomic, retain) NSNumber *showQuickstart;

+ (OPConfig *)get;

@end
