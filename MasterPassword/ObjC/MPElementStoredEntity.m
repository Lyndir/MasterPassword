//
//  MPElementStoredEntity.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2013-01-29.
//  Copyright (c) 2013 Lyndir. All rights reserved.
//

#import "MPElementStoredEntity.h"
#import "MPEntities.h"
#import "MPAppDelegate_Shared.h"

@implementation MPElementStoredEntity

@dynamic contentObject;

- (MPFixableResult)findAndFixInconsistenciesInContext:(NSManagedObjectContext *)context {

    MPFixableResult result = [super findAndFixInconsistenciesInContext:context];

    if (self.contentObject && ![self.contentObject isKindOfClass:[NSData class]])
        result = MPApplyFix( result, ^MPFixableResult {
            MPKey *key = [MPAppDelegate_Shared get].key;
            if (key && [[MPAppDelegate_Shared get] activeUserInContext:context] == self.user) {
                wrn( @"Content object not encrypted for: %@ of %@.  Will re-encrypt.", self.name, self.user.name );
                [self.algorithm saveContent:[self.contentObject description] toElement:self usingKey:key];
                return MPFixableResultProblemsFixed;
            }

            err( @"Content object not encrypted for: %@ of %@.  Couldn't fix, please sign in.", self.name, self.user.name );
            return MPFixableResultProblemsNotFixed;
        } );

    return result;
}

@end
