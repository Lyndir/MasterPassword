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
//  MPSiteModel.h
//  MPSiteModel
//
//  Created by lhunath on 2/11/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPSiteEntity.h"
#import "MPAlgorithm.h"
#import "MPUserEntity.h"

@class MPSiteEntity;

@interface MPSiteModel : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSAttributedString *displayedName;
@property (nonatomic) MPSiteType type;
@property (nonatomic) NSString *typeName;
@property (nonatomic) NSString *content;
@property (nonatomic) NSString *displayedContent;
@property (nonatomic) NSString *loginName;
@property (nonatomic) NSNumber *uses;
@property (nonatomic) NSUInteger counter;
@property (nonatomic) NSDate *lastUsed;
@property (nonatomic) id<MPAlgorithm> algorithm;
@property (nonatomic) MPAlgorithmVersion algorithmVersion;
@property (nonatomic, readonly) BOOL outdated;
@property (nonatomic, readonly) BOOL generated;
@property (nonatomic, readonly) BOOL stored;
@property (nonatomic, readonly) BOOL transient;

- (instancetype)initWithEntity:(MPSiteEntity *)entity fuzzyGroups:(NSArray *)fuzzyGroups;
- (instancetype)initWithName:(NSString *)siteName forUser:(MPUserEntity *)user;
- (MPSiteEntity *)entityInContext:(NSManagedObjectContext *)moc;

- (void)updateContent;
@end
