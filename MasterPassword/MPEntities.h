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

#define MPAvatarCount 19

@interface MPElementEntity (MP)

@property (assign) MPElementType type;
@property (assign) NSUInteger    uses;

- (NSUInteger)use;
- (NSString *)exportContent;
- (void)importProtectedContent:(NSString *)protectedContent;
- (void)importClearTextContent:(NSString *)clearContent usingKey:(NSData *)key;

@end

@interface MPElementGeneratedEntity (MP)

@property (assign) NSUInteger counter;

@end

@interface MPUserEntity (MP)

@property (assign) NSUInteger avatar;
@property (assign) BOOL       saveKey;
@property (assign) MPElementType defaultType;
@property (readonly) NSString *userID;

+ (NSString *)idFor:(NSString *)userName;

@end
