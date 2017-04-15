/**
 * Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
 *
 * See the enclosed file LICENSE for license information (LGPLv3). If you did
 * not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
 *
 * @author   Maarten Billemont <lhunath@lyndir.com>
 * @license  http://www.gnu.org/licenses/lgpl-3.0.txt
 */

//
//  MPKey
//
//  Created by Maarten Billemont on 16/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPAlgorithm.h"

@protocol MPAlgorithm;

typedef NS_ENUM( NSUInteger, MPKeyOrigin ) {
    MPKeyOriginMasterPassword,
    MPKeyOriginKeyChain,
    MPKeyOriginKeyChainBiometric,
};

@interface MPKey : NSObject

@property(nonatomic, readonly) MPKeyOrigin origin;
@property(nonatomic, readonly, copy) NSString *fullName;

- (instancetype)initForFullName:(NSString *)fullName withMasterPassword:(NSString *)masterPassword;
- (instancetype)initForFullName:(NSString *)fullName withKeyResolver:(NSData *( ^ )(id<MPAlgorithm>))keyResolver
                      keyOrigin:(MPKeyOrigin)origin;

- (NSData *)keyIDForAlgorithm:(id<MPAlgorithm>)algorithm;
- (NSData *)keyDataForAlgorithm:(id<MPAlgorithm>)algorithm;
- (NSData *)keyDataForAlgorithm:(id<MPAlgorithm>)algorithm trimmedLength:(NSUInteger)subKeyLength;

- (BOOL)isEqualToKey:(MPKey *)key;

@end
