//
//  OPConfig.h
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

@interface OPConfig : Config

@property (nonatomic, retain) NSNumber *dataStoreError;
@property (nonatomic, retain) NSString *keyPhraseHash;
@property (nonatomic, retain) NSNumber *rememberKeyPhrase;

+ (OPConfig *)get;

@end
