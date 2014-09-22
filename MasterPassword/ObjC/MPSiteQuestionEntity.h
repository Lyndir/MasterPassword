//
//  MPSiteQuestionEntity.h
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 2014-09-21.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPSiteEntity;

@interface MPSiteQuestionEntity : NSManagedObject

@property (nonatomic, retain) NSString * keyword;

@end
