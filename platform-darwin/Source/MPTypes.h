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

#import <Crashlytics/Crashlytics.h>
#import <Crashlytics/Answers.h>

__BEGIN_DECLS
extern NSString *const MPErrorDomain;
extern NSInteger const MPErrorHangCode;

extern NSString *const MPSignedInNotification;
extern NSString *const MPSignedOutNotification;
extern NSString *const MPKeyForgottenNotification;
extern NSString *const MPSiteUpdatedNotification;
extern NSString *const MPCheckConfigNotification;
extern NSString *const MPSitesImportedNotification;
extern NSString *const MPFoundInconsistenciesNotification;

extern NSString *const MPSitesImportedNotificationUserKey;
extern NSString *const MPInconsistenciesFixResultUserKey;

__END_DECLS

#ifdef CRASHLYTICS
#define MPError(error_, message, ...) ({ \
    err( message @"%@%@", ##__VA_ARGS__, error_? @"\n": @"", [error_ fullDescription]?: @"" ); \
    \
    if ([[MPConfig get].sendInfo boolValue]) { \
        [[Crashlytics sharedInstance] recordError:error_ withAdditionalUserInfo:@{ \
                @"location": strf( @"%@:%d %@", @(basename((char *)__FILE__)), __LINE__, NSStringFromSelector(_cmd) ), \
        }]; \
    } \
})
#else
#define MPError(error_, message, ...) ({ \
    err( message @"%@%@", ##__VA_ARGS__, error_? @"\n": @"", [error_ fullDescription]?: @"" ); \
})
#endif
