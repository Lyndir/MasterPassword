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

#import "MPAppDelegate_Shared.h"

@implementation MPConfig

@dynamic sendInfo, rememberLogin, checkInconsistency, hidePasswords, siteAttacker;

- (id)init {

    if (!(self = [super init]))
        return nil;

    [self.defaults registerDefaults:@{
            NSStringFromSelector( @selector( askForReviews ) )     : @YES,

            NSStringFromSelector( @selector( sendInfo ) )          : @YES,
            NSStringFromSelector( @selector( rememberLogin ) )     : @NO,
            NSStringFromSelector( @selector( hidePasswords ) )     : @NO,
            NSStringFromSelector( @selector( checkInconsistency ) ): @NO,
            NSStringFromSelector( @selector( siteAttacker ) )      : @(MPAttacker1),
    }];

    self.delegate = [MPAppDelegate_Shared get];

    return self;
}

@end
