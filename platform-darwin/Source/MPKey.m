//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPAlgorithm.h"

@interface MPKey()

@property(nonatomic) MPKeyOrigin origin;
@property(nonatomic, copy) NSString *fullName;
@property(nonatomic, copy) NSData *( ^keyResolver )(id<MPAlgorithm>);
@property(nonatomic, strong) NSCache *keyCache;

@end

@implementation MPKey;

- (instancetype)initForFullName:(NSString *)fullName withMasterPassword:(NSString *)masterPassword {

    return [self initForFullName:fullName withKeyResolver:^NSData *(id<MPAlgorithm> algorithm) {
        return [algorithm keyDataForFullName:self.fullName withMasterPassword:masterPassword];
    }                  keyOrigin:MPKeyOriginMasterPassword];
}

- (instancetype)initForFullName:(NSString *)fullName withKeyResolver:(NSData *( ^ )(id<MPAlgorithm>))keyResolver
                      keyOrigin:(MPKeyOrigin)origin {

    if (!(self = [super init]))
        return nil;

    self.keyCache = [NSCache new];

    self.origin = origin;
    self.fullName = fullName;
    self.keyResolver = keyResolver;

    return self;
}

- (NSData *)keyIDForAlgorithm:(id<MPAlgorithm>)algorithm {

    return [algorithm keyIDForKey:[self keyForAlgorithm:algorithm]];
}

- (MPMasterKey)keyForAlgorithm:(id<MPAlgorithm>)algorithm {

    @synchronized (self) {
        NSData *keyData = [self.keyCache objectForKey:algorithm];
        if (!keyData) {
            keyData = self.keyResolver( algorithm );
            if (keyData)
                [self.keyCache setObject:keyData forKey:algorithm];
        }

        return keyData.length == MPMasterKeySize? keyData.bytes: NULL;
    }
}

- (BOOL)isEqualToKey:(MPKey *)key {

    return [[self keyIDForAlgorithm:MPAlgorithmDefault] isEqualToData:[key keyIDForAlgorithm:MPAlgorithmDefault]];
}

- (BOOL)isEqual:(id)object {

    return [object isKindOfClass:[MPKey class]] && [self isEqualToKey:object];
}

@end
