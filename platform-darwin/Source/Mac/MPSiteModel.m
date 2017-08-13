//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPSiteModel.h"
#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"
#import "MPMacAppDelegate.h"

@interface MPSiteModel()

@property(nonatomic, strong) NSManagedObjectID *entityOID;
@property(nonatomic) BOOL initialized;

@end

@implementation MPSiteModel

- (instancetype)initWithEntity:(MPSiteEntity *)entity fuzzyGroups:(NSArray *)fuzzyGroups {

    if (!(self = [super init]))
        return nil;

    [self setEntity:entity fuzzyGroups:fuzzyGroups];
    self.initialized = YES;

    return self;
}

- (instancetype)initWithName:(NSString *)siteName forUser:(MPUserEntity *)user {

    if (!(self = [super init]))
        return nil;

    [self setTransientSiteName:siteName forUser:user];
    self.initialized = YES;

    return self;
}

- (void)setEntity:(MPSiteEntity *)entity fuzzyGroups:(NSArray *)fuzzyGroups {

    if ([self.entityOID isEqual:entity.permanentObjectID])
        return;
    self.entityOID = entity.permanentObjectID;

    NSString *siteName = entity.name;
    NSMutableAttributedString *attributedSiteName = [[NSMutableAttributedString alloc] initWithString:siteName];
    for (NSUInteger f = 0, s = (NSUInteger)-1; f < [fuzzyGroups count]; ++f) {
        s = [siteName rangeOfString:fuzzyGroups[f] options:NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch
                              range:NSMakeRange( s + 1, [siteName length] - (s + 1) )].location;
        if (s == NSNotFound)
            break;

        [attributedSiteName addAttribute:NSBackgroundColorAttributeName value:[NSColor alternateSelectedControlColor]
                                   range:NSMakeRange( s, [fuzzyGroups[f] length] )];
    }
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSCenterTextAlignment;
    [attributedSiteName addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange( 0, [siteName length] )];

    self.displayedName = attributedSiteName;
    self.name = siteName;
    self.algorithm = entity.algorithm;
    self.lastUsed = entity.lastUsed;
    self.type = entity.type;
    self.typeName = entity.typeName;
    self.uses = entity.uses_;
    self.counter = [entity isKindOfClass:[MPGeneratedSiteEntity class]]? [(MPGeneratedSiteEntity *)entity counter]: MPCounterValueInitial;
    self.loginGenerated = entity.loginGenerated;

    // Find all password types and the index of the current type amongst them.
    [self updateContent:entity];
}

- (void)setTransientSiteName:(NSString *)siteName forUser:(MPUserEntity *)user {

    self.entityOID = nil;

    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSCenterTextAlignment;
    self.displayedName = stra( siteName, @{
            NSBackgroundColorAttributeName: [NSColor alternateSelectedControlColor],
            NSParagraphStyleAttributeName : paragraphStyle,
    } );
    self.name = siteName;
    self.algorithm = MPAlgorithmDefault;
    self.lastUsed = nil;
    self.type = user.defaultType;
    self.typeName = [self.algorithm nameOfType:self.type];
    self.uses = @0;
    self.counter = MPCounterValueDefault;

    // Find all password types and the index of the current type amongst them.
    [self updateContent];
}

- (MPSiteEntity *)entityInContext:(NSManagedObjectContext *)moc {

    if (!self.entityOID)
        return nil;

    NSError *error;
    MPSiteEntity *entity = [moc existingObjectWithID:self.entityOID error:&error];
    if (!entity)
        MPError( error, @"Couldn't retrieve active site." );

    return entity;
}

- (void)setCounter:(MPCounterValue)counter {

    if (self.counter == counter)
        return;
    _counter = counter;

    if (!self.initialized)
        // This wasn't a change to the entity.
        return;

    if (self.entityOID)
        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *entity = [self entityInContext:context];
            if ([entity isKindOfClass:[MPGeneratedSiteEntity class]]) {
                ((MPGeneratedSiteEntity *)entity).counter = counter;
                [context saveToStore];

                [self updateContent:entity];
            }
        }];
    else
        [self updateContent];
}

- (void)setLoginGenerated:(BOOL)loginGenerated {

    if (self.loginGenerated == loginGenerated)
        return;
    _loginGenerated = loginGenerated;

    if (!self.initialized)
        // This wasn't a change to the entity.
        return;

    if (self.entityOID)
        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *entity = [self entityInContext:context];
            entity.loginGenerated = loginGenerated;
            [context saveToStore];

            [self updateContent:entity];
        }];
    else
        [self updateContent];
}

- (MPAlgorithmVersion)algorithmVersion {

    return self.algorithm.version;
}

- (void)setAlgorithmVersion:(MPAlgorithmVersion)algorithmVersion {

    if (algorithmVersion == self.algorithm.version)
        return;
    [self willChangeValueForKey:@"outdated"];
    self.algorithm = MPAlgorithmForVersion( algorithmVersion )?: self.algorithm;
    [self didChangeValueForKey:@"outdated"];

    if (self.entityOID)
        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *entity = [self entityInContext:context];
            entity.algorithm = self.algorithm;
            [context saveToStore];

            [self updateContent:entity];
        }];
    else
        [self updateContent];
}

- (void)setQuestion:(NSString *)question {

    if ([self.question isEqualToString:question])
        return;
    _question = question;

    [self updateContent];
}

- (BOOL)outdated {

    return self.algorithmVersion < MPAlgorithmVersionCurrent;
}

- (BOOL)generated {

    return self.type & MPResultTypeClassTemplate;
}

- (BOOL)stored {

    return self.type & MPResultTypeClassStateful;
}

- (BOOL)transient {

    return self.entityOID == nil;
}

- (void)updateContent {

    if (self.entityOID)
        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            [self updateContent:[MPSiteEntity existingObjectWithID:self.entityOID inContext:context]];
        }];

    else
        PearlNotMainQueue( ^{
            [self updatePasswordWithResult:
                    [self.algorithm mpwTemplateForSiteNamed:self.name ofType:self.type withCounter:self.counter
                                                   usingKey:[MPAppDelegate_Shared get].key]];
            [self updateLoginNameWithResult:
                    [self.algorithm mpwLoginForSiteNamed:self.name
                                                usingKey:[MPAppDelegate_Shared get].key]];
            [self updateAnswerWithResult:
                    [self.algorithm mpwAnswerForSiteNamed:self.name onQuestion:self.question
                                                 usingKey:[MPAppDelegate_Shared get].key]];
        } );
}

- (void)updateContent:(MPSiteEntity *)entity {

    [entity resolvePasswordUsingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        [self updatePasswordWithResult:result];
    }];
    [entity resolveLoginUsingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        [self updateLoginNameWithResult:result];
    }];
    [self updateAnswerWithResult:[self.algorithm mpwAnswerForSiteNamed:self.name onQuestion:self.question
                                                              usingKey:[MPAppDelegate_Shared get].key]];
}

- (void)updatePasswordWithResult:(NSString *)result {

    static NSRegularExpression *re_anyChar;
    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        re_anyChar = [NSRegularExpression regularExpressionWithPattern:@"." options:0 error:nil];
    } );

    NSString *displayResult = result;
    if ([[MPConfig get].hidePasswords boolValue] && !([NSEvent modifierFlags] & NSAlternateKeyMask))
        displayResult = [displayResult stringByReplacingMatchesOfExpression:re_anyChar withTemplate:@"●"];

    PearlMainQueue( ^{
        self.content = result;
        self.displayedContent = displayResult;
    } );
}

- (void)updateLoginNameWithResult:(NSString *)loginName {

    PearlMainQueue( ^{
        self.loginName = loginName;
    } );
}

- (void)updateAnswerWithResult:(NSString *)answer {

    PearlMainQueue( ^{
        self.answer = answer;
    } );
}

@end
