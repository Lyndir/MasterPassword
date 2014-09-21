//
//  MPUserEntity.h
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 2014-09-21.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPSiteEntity;

@interface MPUserEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * avatar_;
@property (nonatomic, retain) NSNumber * defaultType_;
@property (nonatomic, retain) NSData * keyID;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * saveKey_;
@property (nonatomic, retain) NSSet *sites;
@end

@interface MPUserEntity (CoreDataGeneratedAccessors)

- (void)addSitesObject:(MPSiteEntity *)value;
- (void)removeSitesObject:(MPSiteEntity *)value;
- (void)addSites:(NSSet *)values;
- (void)removeSites:(NSSet *)values;

@end
