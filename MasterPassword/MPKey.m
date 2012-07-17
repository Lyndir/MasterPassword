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

#import "MPKey.h"
#import "MPAlgorithm.h"


@interface MPKey ()

@property (nonatomic, readwrite, strong) id<MPAlgorithm> algorithm;
@property (nonatomic, readwrite, strong) NSData *keyData;
@property (nonatomic, readwrite, strong) NSData *keyID;

@end

@implementation MPKey
@synthesize algorithm = _algorithm, keyData = _keyData, keyID = _keyID;

- (id)initWithKeyData:(NSData *)keyData algorithm:(id<MPAlgorithm>)algorithm {

    if (!(self = [super init]))
        return  nil;

    self.keyData = keyData;
    self.algorithm = algorithm;
    self.keyID = [self.algorithm keyIDForKeyData:keyData];

    return self;
}

- (MPKey *)subKeyOfLength:(NSUInteger)subKeyLength {

    NSData *subKeyData = [self.keyData subdataWithRange:NSMakeRange(0, MIN(subKeyLength, self.keyData.length))];

    return [self.algorithm keyFromKeyData:subKeyData];
}

- (BOOL)isEqualToKey:(MPKey *)key {

    return [self.keyID isEqualToData:key.keyID];
}

- (BOOL)isEqual:(id)object {

    if (![object isKindOfClass:[MPKey class]])
        return NO;

    return [self isEqualToKey:object];
}


@end
