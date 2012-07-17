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

@protocol MPAlgorithm;


@interface MPKey : NSObject

@property (nonatomic, readonly, strong) id<MPAlgorithm> algorithm;
@property (nonatomic, readonly, strong) NSData *keyData;
@property (nonatomic, readonly, strong) NSData *keyID;

- (id)initWithKeyData:(NSData *)keyData algorithm:(id<MPAlgorithm>)algorithm;
- (MPKey *)subKeyOfLength:(NSUInteger)subKeyLength;
- (BOOL)isEqualToKey:(MPKey *)key;

@end
