//
//  MPSiteQuestionEntity+CoreDataProperties.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-04-30.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPSiteQuestionEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MPSiteQuestionEntity (CoreDataProperties)

+ (NSFetchRequest<MPSiteQuestionEntity *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *keyword;
@property (nullable, nonatomic, retain) MPSiteEntity *site;

@end

NS_ASSUME_NONNULL_END
