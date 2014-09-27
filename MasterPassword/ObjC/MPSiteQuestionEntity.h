//
//  MPSiteQuestionEntity.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2014-09-27.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPSiteEntity;

@interface MPSiteQuestionEntity : NSManagedObject

@property (nonatomic, retain) NSString * keyword;
@property (nonatomic, retain) MPSiteEntity *site;

@end
