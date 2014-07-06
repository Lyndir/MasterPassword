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

@property (nonatomic) NSString *siteName;
@property (nonatomic) MPElementType type;
@property (nonatomic) NSString *typeName;
@property (nonatomic) NSString *content;
@property (nonatomic) NSString *contentDisplay;
@property (nonatomic) NSString *loginName;
@property (nonatomic) NSNumber *uses;
@property (nonatomic) NSUInteger counter;
@property (nonatomic) NSDate *lastUsed;
@property (nonatomic) id<MPAlgorithm> algorithm;
@property (nonatomic) BOOL generated;
@property (nonatomic) BOOL stored;

- (id)initWithEntity:(MPElementEntity *)entity;
- (MPElementEntity *)entityInContext:(NSManagedObjectContext *)moc;

- (void)updateContent;
@end
