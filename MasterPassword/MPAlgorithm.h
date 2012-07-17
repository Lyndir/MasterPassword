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
//  MPAlgorithm
//
//  Created by Maarten Billemont on 16/07/12.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPKey.h"
#import "MPElementGeneratedEntity.h"

#define MPAlgorithmDefaultVersion 1
#define MPAlgorithmDefault MPAlgorithmForVersion(MPAlgorithmDefaultVersion)

@protocol MPAlgorithm<NSObject>

@required
- (NSUInteger)version;
- (BOOL)migrateElement:(MPElementEntity *)element explicit:(BOOL)explicit;

- (MPKey *)keyForPassword:(NSString *)password ofUserNamed:(NSString *)userName;
- (MPKey *)keyFromKeyData:(NSData *)keyData;
- (NSData *)keyIDForKeyData:(NSData *)keyData;

- (NSString *)nameOfType:(MPElementType)type;
- (NSString *)shortNameOfType:(MPElementType)type;
- (NSString *)classNameOfType:(MPElementType)type;
- (Class)classOfType:(MPElementType)type;

- (NSString *)generateContentForElement:(MPElementGeneratedEntity *)element usingKey:(MPKey *)key;

@end

id<MPAlgorithm> MPAlgorithmForVersion(NSUInteger version);
id<MPAlgorithm> MPAlgorithmDefaultForBundleVersion(NSString *bundleVersion);
