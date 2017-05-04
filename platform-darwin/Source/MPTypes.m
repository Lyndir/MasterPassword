//
//  MPTypes.c
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPTypes.h"

NSString *const MPErrorDomain = @"MPErrorDomain";
NSInteger const MPErrorHangCode = 1;

NSString *const MPSignedInNotification = @"MPSignedInNotification";
NSString *const MPSignedOutNotification = @"MPSignedOutNotification";
NSString *const MPKeyForgottenNotification = @"MPKeyForgottenNotification";
NSString *const MPSiteUpdatedNotification = @"MPSiteUpdatedNotification";
NSString *const MPCheckConfigNotification = @"MPCheckConfigNotification";
NSString *const MPSitesImportedNotification = @"MPSitesImportedNotification";
NSString *const MPFoundInconsistenciesNotification = @"MPFoundInconsistenciesNotification";

NSString *const MPSitesImportedNotificationUserKey = @"MPSitesImportedNotificationUserKey";
NSString *const MPInconsistenciesFixResultUserKey = @"MPInconsistenciesFixResultUserKey";
