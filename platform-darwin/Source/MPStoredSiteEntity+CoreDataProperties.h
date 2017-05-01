//
//  MPStoredSiteEntity+CoreDataProperties.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-05-01.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPStoredSiteEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MPStoredSiteEntity (CoreDataProperties)

+ (NSFetchRequest<MPStoredSiteEntity *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *contentObject;

@end

NS_ASSUME_NONNULL_END
