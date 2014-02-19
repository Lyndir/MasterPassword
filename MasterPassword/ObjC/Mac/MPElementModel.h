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
@property (nonatomic) NSString *site;
@property (nonatomic) MPElementType type;
@property (nonatomic) NSString *typeName;
@property (nonatomic) NSString *content;
@property (nonatomic) NSString *loginName;
@property (nonatomic) NSNumber *uses;
@property (nonatomic) NSNumber *counter;
@property (nonatomic) NSDate *lastUsed;
@property (nonatomic, strong) id<MPAlgorithm> algorithm;

- (MPElementEntity *)entityForMainThread;
- (MPElementEntity *)entityInContext:(NSManagedObjectContext *)moc;

- (id)initWithEntity:(MPElementEntity *)entity;
@end
