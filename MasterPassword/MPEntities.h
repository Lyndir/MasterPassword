//
//  MPElementEntities.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 31/05/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPElementEntity.h"
#import "MPElementStoredEntity.h"
#import "MPElementGeneratedEntity.h"
#import "MPUserEntity.h"

@interface MPElementEntity (MP)

- (NSNumber *)use;
- (NSString *)exportContent;
- (void)importContent:(NSString *)content;

@end
