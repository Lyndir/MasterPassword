//
//  MPUserEntity+CoreDataProperties.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-04-30.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPUserEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MPUserEntity (CoreDataProperties)

+ (NSFetchRequest<MPUserEntity *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *avatar_;
@property (nullable, nonatomic, copy) NSNumber *defaultType_;
@property (nullable, nonatomic, retain) NSData *keyID;
@property (nullable, nonatomic, copy) NSDate *lastUsed;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *saveKey_;
@property (nullable, nonatomic, copy) NSNumber *touchID_;
@property (nullable, nonatomic, copy) NSNumber *version_;
@property (nullable, nonatomic, retain) NSSet<MPSiteEntity *> *sites;

@end

@interface MPUserEntity (CoreDataGeneratedAccessors)

- (void)addSitesObject:(MPSiteEntity *)value;
- (void)removeSitesObject:(MPSiteEntity *)value;
- (void)addSites:(NSSet<MPSiteEntity *> *)values;
- (void)removeSites:(NSSet<MPSiteEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
