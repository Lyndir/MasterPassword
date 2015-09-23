/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPSiteModel.h
//  MPSiteModel
//
//  Created by lhunath on 2/11/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPSiteModel.h"
#import "MPSiteEntity.h"
#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"
#import "MPAppDelegate_Store.h"
#import "MPMacAppDelegate.h"

@implementation MPSiteModel {
    NSManagedObjectID *_entityOID;
    BOOL _initialized;
}

- (instancetype)initWithEntity:(MPSiteEntity *)entity fuzzyGroups:(NSArray *)fuzzyGroups {

    if (!(self = [super init]))
        return nil;

    [self setEntity:entity fuzzyGroups:fuzzyGroups];
    _initialized = YES;

    return self;
}

- (instancetype)initWithName:(NSString *)siteName forUser:(MPUserEntity *)user {

    if (!(self = [super init]))
        return nil;

    [self setTransientSiteName:siteName forUser:user];
    _initialized = YES;

    return self;
}

- (void)setEntity:(MPSiteEntity *)entity fuzzyGroups:(NSArray *)fuzzyGroups {

    if ([_entityOID isEqual:entity.objectID])
        return;
    _entityOID = entity.objectID;

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
    self.counter = [entity isKindOfClass:[MPGeneratedSiteEntity class]]? [(MPGeneratedSiteEntity *)entity counter]: 0;

    // Find all password types and the index of the current type amongst them.
    [self updateContent:entity];
}

- (void)setTransientSiteName:(NSString *)siteName forUser:(MPUserEntity *)user {

    _entityOID = nil;

    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSCenterTextAlignment;
    self.displayedName = stra( siteName, @{
            NSBackgroundColorAttributeName : [NSColor alternateSelectedControlColor],
            NSParagraphStyleAttributeName  : paragraphStyle,
    } );
    self.name = siteName;
    self.algorithm = MPAlgorithmDefault;
    self.lastUsed = nil;
    self.type = user.defaultType;
    self.typeName = [self.algorithm nameOfType:self.type];
    self.uses = @0;
    self.counter = 1;

    // Find all password types and the index of the current type amongst them.
    [self updateContent];
}

- (MPSiteEntity *)entityInContext:(NSManagedObjectContext *)moc {

    if (!_entityOID)
        return nil;

    NSError *error;
    MPSiteEntity *entity = (MPSiteEntity *)[moc existingObjectWithID:_entityOID error:&error];
    if (!entity)
        err( @"Couldn't retrieve active site: %@", [error fullDescription] );

    return entity;
}

- (void)setCounter:(NSUInteger)counter {

    if (counter == _counter)
        return;
    _counter = counter;

    if (!_initialized)
        // This wasn't a change to the entity.
        return;

    if (_entityOID)
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

- (MPAlgorithmVersion)algorithmVersion {

    return self.algorithm.version;
}

- (void)setAlgorithmVersion:(MPAlgorithmVersion)algorithmVersion {

    if (algorithmVersion == self.algorithm.version)
        return;
    [self willChangeValueForKey:@"outdated"];
    self.algorithm = MPAlgorithmForVersion( algorithmVersion )?: self.algorithm;
    [self didChangeValueForKey:@"outdated"];

    if (_entityOID)
        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *entity = [self entityInContext:context];
            entity.algorithm = self.algorithm;
            [context saveToStore];

            [self updateContent:entity];
        }];
    else
        [self updateContent];
}

- (BOOL)outdated {

    return self.algorithmVersion < MPAlgorithmVersionCurrent;
}

- (BOOL)generated {

    return self.type & MPSiteTypeClassGenerated;
}

- (BOOL)stored {

    return self.type & MPSiteTypeClassStored;
}

- (BOOL)transient {

    return _entityOID == nil;
}

- (void)updateContent {

    if (_entityOID)
        [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            [self updateContent:[MPSiteEntity existingObjectWithID:_entityOID inContext:context]];
        }];
    else
        PearlNotMainQueue( ^{
            NSString *password = [self.algorithm generatePasswordForSiteNamed:self.name ofType:self.type withCounter:self.counter
                                                                     usingKey:[MPAppDelegate_Shared get].key];
            NSString *loginName = [self.algorithm generateLoginForSiteNamed:self.name usingKey:[MPAppDelegate_Shared get].key];
            [self updatePasswordWithResult:password];
            [self updateLoginNameWithResult:loginName];
        } );
}

- (void)updateContent:(MPSiteEntity *)entity {

    [entity resolvePasswordUsingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        [self updatePasswordWithResult:result];
    }];
    [entity resolveLoginUsingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        [self updateLoginNameWithResult:result];
    }];
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

@end
