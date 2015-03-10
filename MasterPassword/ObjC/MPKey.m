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

#import "MPAlgorithm.h"

@interface MPKey()

@property(nonatomic) NSString *fullName;
@property(nonatomic) NSString *masterPassword;

@end

@implementation MPKey {
    NSCache *_keyCache;
};

- (instancetype)initForFullName:(NSString *)fullName withMasterPassword:(NSString *)masterPassword {

    if (!(self = [super init]))
        return nil;

    _keyCache = [NSCache new];
    self.fullName = fullName;
    self.masterPassword = masterPassword;

    return self;
}

- (instancetype)initForFullName:(NSString *)fullName withKeyData:(NSData *)keyData forAlgorithm:(id<MPAlgorithm>)algorithm {

    if (!(self = [self initForFullName:fullName withMasterPassword:nil]))
        return nil;

    [_keyCache setObject:keyData forKey:algorithm];

    return self;
}

- (NSData *)keyIDForAlgorithm:(id<MPAlgorithm>)algorithm {

    return [algorithm keyIDForKeyData:[self keyDataForAlgorithm:algorithm]];
}

- (NSData *)keyDataForAlgorithm:(id<MPAlgorithm>)algorithm {

    NSData *keyData = [_keyCache objectForKey:algorithm];
    if (!keyData)
        [_keyCache setObject:keyData = [algorithm keyDataForFullName:self.fullName withMasterPassword:self.masterPassword]
                      forKey:algorithm];

    return keyData;
}

- (NSData *)keyDataForAlgorithm:(id<MPAlgorithm>)algorithm trimmedLength:(NSUInteger)subKeyLength {

    NSData *keyData = [self keyDataForAlgorithm:algorithm];
    return [keyData subdataWithRange:NSMakeRange( 0, MIN( subKeyLength, keyData.length ) )];
}

- (BOOL)isEqualToKey:(MPKey *)key {

    return [self.fullName isEqualToString:key.fullName] && [self.masterPassword isEqualToString:self.masterPassword];
}

- (BOOL)isEqual:(id)object {

    if (![object isKindOfClass:[MPKey class]])
        return NO;

    return [self isEqualToKey:object];
}

@end
