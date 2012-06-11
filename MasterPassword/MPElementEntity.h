//
//  MPElementEntity.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 11/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPUserEntity;

@interface MPElementEntity : NSManagedObject

@property (nonatomic, retain) id content;
@property (nonatomic, retain) NSDate * lastUsed;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * type_;
@property (nonatomic, retain) NSNumber * uses_;
@property (nonatomic, retain) MPUserEntity *user;

@end
