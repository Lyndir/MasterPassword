//
//  MPSiteEntity+CoreDataProperties.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2017-04-30.
//  Copyright © 2017 Lyndir. All rights reserved.
//

#import "MPSiteEntity+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface MPSiteEntity (CoreDataProperties)

+ (NSFetchRequest<MPSiteEntity *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSObject *content;
@property (nullable, nonatomic, copy) NSDate *lastUsed;
@property (nullable, nonatomic, copy) NSNumber *loginGenerated_;
@property (nullable, nonatomic, copy) NSString *loginName;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *requiresExplicitMigration_;
@property (nullable, nonatomic, copy) NSNumber *type_;
@property (nullable, nonatomic, copy) NSNumber *uses_;
@property (nullable, nonatomic, copy) NSNumber *version_;
@property (nullable, nonatomic, copy) NSString *url;
@property (nullable, nonatomic, retain) NSOrderedSet<MPSiteQuestionEntity *> *questions;
@property (nullable, nonatomic, retain) MPUserEntity *user;

@end

@interface MPSiteEntity (CoreDataGeneratedAccessors)

- (void)insertObject:(MPSiteQuestionEntity *)value inQuestionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromQuestionsAtIndex:(NSUInteger)idx;
- (void)insertQuestions:(NSArray<MPSiteQuestionEntity *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeQuestionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInQuestionsAtIndex:(NSUInteger)idx withObject:(MPSiteQuestionEntity *)value;
- (void)replaceQuestionsAtIndexes:(NSIndexSet *)indexes withQuestions:(NSArray<MPSiteQuestionEntity *> *)values;
- (void)addQuestionsObject:(MPSiteQuestionEntity *)value;
- (void)removeQuestionsObject:(MPSiteQuestionEntity *)value;
- (void)addQuestions:(NSOrderedSet<MPSiteQuestionEntity *> *)values;
- (void)removeQuestions:(NSOrderedSet<MPSiteQuestionEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
