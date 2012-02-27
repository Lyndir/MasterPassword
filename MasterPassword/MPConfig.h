//
//  MPConfig.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@interface MPConfig : PearlConfig

@property (nonatomic, retain) NSNumber *dataStoreError;
@property (nonatomic, retain) NSNumber *storeKeyPhrase;
@property (nonatomic, retain) NSNumber *rememberKeyPhrase;
@property (nonatomic, retain) NSNumber *forgetKeyPhrase;
@property (nonatomic, retain) NSNumber *helpHidden;
@property (nonatomic, retain) NSNumber *showQuickStart;

+ (MPConfig *)get;

@end
