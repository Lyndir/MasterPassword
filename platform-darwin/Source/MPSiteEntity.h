//
//  MPSiteEntity.h
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 2014-09-21.
//  Copyright (c) 2014 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MPSiteQuestionEntity, MPUserEntity;

@interface MPSiteEntity : NSManagedObject

//@property (nonatomic, retain) id content; // Hide here, reveal in MPStoredSiteEntity
@property(nonatomic, retain) NSDate *lastUsed;
@property(nonatomic, retain) NSNumber *loginGenerated_;
@property(nonatomic, retain) NSString *loginName;
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSNumber *requiresExplicitMigration_;
@property(nonatomic, retain) NSNumber *type_;
@property(nonatomic, retain) NSNumber *uses_;
@property(nonatomic, retain) NSNumber *version_;
@property(nonatomic, retain) NSOrderedSet *questions;
@property(nonatomic, retain) MPUserEntity *user;
@end

@interface MPSiteEntity(CoreDataGeneratedAccessors)

- (void)insertObject:(MPSiteQuestionEntity *)value inQuestionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromQuestionsAtIndex:(NSUInteger)idx;
- (void)insertQuestions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeQuestionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInQuestionsAtIndex:(NSUInteger)idx withObject:(MPSiteQuestionEntity *)value;
- (void)replaceQuestionsAtIndexes:(NSIndexSet *)indexes withQuestions:(NSArray *)values;
- (void)addQuestionsObject:(MPSiteQuestionEntity *)value;
- (void)removeQuestionsObject:(MPSiteQuestionEntity *)value;
- (void)addQuestions:(NSOrderedSet *)values;
- (void)removeQuestions:(NSOrderedSet *)values;
@end
