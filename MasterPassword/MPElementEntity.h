//
//  MPElementEntity.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MPElementEntity : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *keyID;
@property (nonatomic, assign) int16_t type;
@property (nonatomic, assign) int16_t uses;
@property (nonatomic, assign) NSTimeInterval lastUsed;

@property (nonatomic, retain, readonly) id content;

- (int16_t)use;
- (NSString *)exportContent;
- (void)importContent:(NSString *)content;

@end
