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
//  MPElementModel.h
//  MPElementModel
//
//  Created by lhunath on 2/11/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MPElementEntity;

@interface MPElementModel : NSObject
@property (nonatomic, readonly) NSString *site;
@property (nonatomic, readonly) MPElementType type;
@property (nonatomic, readonly) NSString *typeName;
@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) NSString *loginName;
@property (nonatomic, readonly) NSNumber *uses;
@property (nonatomic) NSUInteger counter;
@property (nonatomic, readonly) NSDate *lastUsed;
@property (nonatomic, readonly) id<MPAlgorithm> algorithm;
@property (nonatomic, readonly) NSArray *types;
@property (nonatomic) NSUInteger typeIndex;

- (id)initWithEntity:(MPElementEntity *)entity;
- (MPElementEntity *)entityInContext:(NSManagedObjectContext *)moc;

@end
