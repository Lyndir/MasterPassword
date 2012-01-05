//
//  OPElementEntity.h
//  OnePassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface OPElementEntity : NSManagedObject

@property (nonatomic, retain) NSString *name;
@property (nonatomic) int16_t type;
@property (nonatomic) int16_t uses;
@property (nonatomic) NSTimeInterval lastUsed;
@property (nonatomic, retain) NSString *contentUTI;
@property (nonatomic) int16_t contentType;

- (void)use;
- (id)content;
- (NSString *)contentDescription;

@end
