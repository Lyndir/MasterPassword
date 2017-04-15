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

@property(nonatomic) MPKeyOrigin origin;
@property(nonatomic, copy) NSString *fullName;
@property(nonatomic, copy) NSData *( ^keyResolver )(id<MPAlgorithm>);

@end

@implementation MPKey {
    NSCache *_keyCache;
};

- (instancetype)initForFullName:(NSString *)fullName withMasterPassword:(NSString *)masterPassword {

    return [self initForFullName:fullName withKeyResolver:^NSData *(id<MPAlgorithm> algorithm) {
        return [algorithm keyDataForFullName:self.fullName withMasterPassword:masterPassword];
    }                  keyOrigin:MPKeyOriginMasterPassword];
}

- (instancetype)initForFullName:(NSString *)fullName withKeyResolver:(NSData *( ^ )(id<MPAlgorithm>))keyResolver
                      keyOrigin:(MPKeyOrigin)origin {

    if (!(self = [super init]))
        return nil;

    _keyCache = [NSCache new];

    self.origin = origin;
    self.fullName = fullName;
    self.keyResolver = keyResolver;

    return self;
}

- (NSData *)keyIDForAlgorithm:(id<MPAlgorithm>)algorithm {

    return [algorithm keyIDForKeyData:[self keyDataForAlgorithm:algorithm]];
}

- (NSData *)keyDataForAlgorithm:(id<MPAlgorithm>)algorithm {

    @synchronized (self) {
        NSData *keyData = [_keyCache objectForKey:algorithm];
        if (keyData)
            return keyData;

        keyData = self.keyResolver( algorithm );
        if (keyData)
            [_keyCache setObject:keyData forKey:algorithm];

        return keyData;
    }
}

- (NSData *)keyDataForAlgorithm:(id<MPAlgorithm>)algorithm trimmedLength:(NSUInteger)subKeyLength {

    NSData *keyData = [self keyDataForAlgorithm:algorithm];
    return [keyData subdataWithRange:NSMakeRange( 0, MIN( subKeyLength, keyData.length ) )];
}

- (BOOL)isEqualToKey:(MPKey *)key {

    return [[self keyIDForAlgorithm:MPAlgorithmDefault] isEqualToData:[key keyIDForAlgorithm:MPAlgorithmDefault]];
}

- (BOOL)isEqual:(id)object {

    if (![object isKindOfClass:[MPKey class]])
        return NO;

    return [self isEqualToKey:object];
}

@end
