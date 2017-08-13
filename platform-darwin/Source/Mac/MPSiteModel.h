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

#import <Foundation/Foundation.h>
#import "MPSiteEntity+CoreDataClass.h"
#import "MPAlgorithm.h"
#import "MPUserEntity+CoreDataClass.h"

@class MPSiteEntity;

@interface MPSiteModel : NSObject

@property(nonatomic) NSString *name;
@property(nonatomic) NSAttributedString *displayedName;
@property(nonatomic) MPResultType type;
@property(nonatomic) NSString *typeName;
@property(nonatomic) NSString *content;
@property(nonatomic) NSString *displayedContent;
@property(nonatomic) NSString *question;
@property(nonatomic) NSString *answer;
@property(nonatomic) NSString *loginName;
@property(nonatomic) BOOL loginGenerated;
@property(nonatomic) NSNumber *uses;
@property(nonatomic) MPCounterValue counter;
@property(nonatomic) NSDate *lastUsed;
@property(nonatomic) id<MPAlgorithm> algorithm;
@property(nonatomic) MPAlgorithmVersion algorithmVersion;
@property(nonatomic, readonly) BOOL outdated;
@property(nonatomic, readonly) BOOL generated;
@property(nonatomic, readonly) BOOL stored;
@property(nonatomic, readonly) BOOL transient;

- (instancetype)initWithEntity:(MPSiteEntity *)entity fuzzyGroups:(NSArray *)fuzzyGroups;
- (instancetype)initWithName:(NSString *)siteName forUser:(MPUserEntity *)user;
- (MPSiteEntity *)entityInContext:(NSManagedObjectContext *)moc;

- (void)updateContent;
@end
