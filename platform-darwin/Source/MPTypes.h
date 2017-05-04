//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

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
#define MPError(error_, ...) ({ \
    err( message @"%@%@", ##__VA_ARGS__, error_? @"\n": @"", [error_ fullDescription]?: @"" ); \
})
#endif
