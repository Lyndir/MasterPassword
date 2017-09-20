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

#import "MPTypes.h"

NSString *const MPErrorDomain = @"MPErrorDomain";
NSInteger const MPErrorHangCode = 1;
NSInteger const MPErrorMarshalCode = 1;

NSString *const MPSignedInNotification = @"MPSignedInNotification";
NSString *const MPSignedOutNotification = @"MPSignedOutNotification";
NSString *const MPKeyForgottenNotification = @"MPKeyForgottenNotification";
NSString *const MPSiteUpdatedNotification = @"MPSiteUpdatedNotification";
NSString *const MPCheckConfigNotification = @"MPCheckConfigNotification";
NSString *const MPSitesImportedNotification = @"MPSitesImportedNotification";
NSString *const MPFoundInconsistenciesNotification = @"MPFoundInconsistenciesNotification";

NSString *const MPSitesImportedNotificationUserKey = @"MPSitesImportedNotificationUserKey";
NSString *const MPInconsistenciesFixResultUserKey = @"MPInconsistenciesFixResultUserKey";
