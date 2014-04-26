//
//  MPElementGeneratedEntity.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 2013-01-29.
//  Copyright (c) 2013 Lyndir. All rights reserved.
//

#import "MPElementGeneratedEntity.h"
#import "MPAppDelegate_Shared.h"

@implementation MPElementGeneratedEntity

@dynamic counter_;

- (MPFixableResult)findAndFixInconsistenciesInContext:(NSManagedObjectContext *)context {

    MPFixableResult result = [super findAndFixInconsistenciesInContext:context];

    if (!self.type || self.type == (MPElementType)NSNotFound || ![[self.algorithm allTypes] containsObject:self.type_])
        // Invalid self.type
        result = MPApplyFix( result, ^MPFixableResult {
            wrn( @"Invalid type for: %@ of %@, type: %ld.  Will use %ld instead.",
                            self.name, self.user.name, (long)self.type, (long)self.user.defaultType );
            self.type = self.user.defaultType;
            return MPFixableResultProblemsFixed;
        } );
    if (!self.type || self.type == (MPElementType)NSNotFound || ![[self.algorithm allTypes] containsObject:self.type_])
        // Invalid self.user.defaultType
        result = MPApplyFix( result, ^MPFixableResult {
            wrn( @"Invalid type for: %@ of %@, type: %ld.  Will use %ld instead.",
                            self.name, self.user.name, (long)self.type, (long)MPElementTypeGeneratedLong );
            self.type = MPElementTypeGeneratedLong;
            return MPFixableResultProblemsFixed;
        } );
    if (![self isKindOfClass:[self.algorithm classOfType:self.type]])
        // Mismatch between self.type and self.class
        result = MPApplyFix( result, ^MPFixableResult {
            for (MPElementType newType = self.type; self.type != (newType = [self.algorithm nextType:newType]);)
                if ([self isKindOfClass:[self.algorithm classOfType:newType]]) {
                    wrn( @"Mismatching type for: %@ of %@, type: %lu, class: %@.  Will use %ld instead.",
                                    self.name, self.user.name, (long)self.type, self.class, (long)newType );
                    self.type = newType;
                    return MPFixableResultProblemsFixed;
                }

            err( @"Mismatching type for: %@ of %@, type: %lu, class: %@.  Couldn't find a type to fix problem with.",
                            self.name, self.user.name, (long)self.type, self.class );
            return MPFixableResultProblemsNotFixed;
        } );

    return result;
}

@end
