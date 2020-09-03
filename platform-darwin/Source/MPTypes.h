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

MP_LIBS_BEGIN
#import <Sentry/Sentry.h>
MP_LIBS_END

__BEGIN_DECLS
extern NSString *const MPErrorDomain;
extern NSInteger const MPErrorHangCode;
extern NSInteger const MPErrorMarshalCode;

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

#define MPError(error_, message_, ...) ({ \
    NSError *__error = error_; \
    err( message_ @"%@%@", ##__VA_ARGS__, __error && [message_ length]? @"\n": @"", [__error fullDescription]?: @"" ); \
    \
    if (__error && [[MPConfig get].sendInfo boolValue]) { \
        SentryEvent *event = [[SentryEvent alloc] initWithLevel:kSentryLevelError]; \
        event.message = strf( message_ @": %@", ##__VA_ARGS__, [__error localizedDescription]); \
        event.logger = @"MPError"; \
        event.fingerprint = @[ message_, __error.domain, @(__error.code) ]; \
        [SentrySDK captureEvent:event]; \
    } \
    __error; \
})

#define MPMakeError(message, ...) ({ \
     MPError( [NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{ \
        NSLocalizedDescriptionKey: strf( message, ##__VA_ARGS__ ) \
     }], @"" ); \
})
