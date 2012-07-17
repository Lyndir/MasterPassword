//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPKey.h"

typedef enum {
    MPElementContentTypePassword,
    MPElementContentTypeNote,
    MPElementContentTypePicture,
} MPElementContentType;

typedef enum {
    /** Generate the password. */
     MPElementTypeClassGenerated = 1 << 4,
    /** Store the password. */
     MPElementTypeClassStored    = 1 << 5,
} MPElementTypeClass;

typedef enum {
    /** Export the key-protected content data. */
     MPElementFeatureExportContent = 1 << 10,
    /** Never export content. */
     MPElementFeatureDevicePrivate = 1 << 11,
} MPElementFeature;

typedef enum {
    MPElementTypeGeneratedMaximum = 0x0 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedLong    = 0x1 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedMedium  = 0x2 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedShort   = 0x3 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedBasic   = 0x4 | MPElementTypeClassGenerated | 0x0,
    MPElementTypeGeneratedPIN     = 0x5 | MPElementTypeClassGenerated | 0x0,

    MPElementTypeStoredPersonal      = 0x0 | MPElementTypeClassStored | MPElementFeatureExportContent,
    MPElementTypeStoredDevicePrivate = 0x1 | MPElementTypeClassStored | MPElementFeatureDevicePrivate,
} MPElementType;

#define MPCheckpointAction                    @"MPCheckpointAction"
#define MPCheckpointHelpChapter               @"MPCheckpointHelpChapter"
#define MPCheckpointCopyToPasteboard          @"MPCheckpointCopyToPasteboard"
#define MPCheckpointCopyUserNameToPasteboard  @"MPCheckpointCopyUserNameToPasteboard"
#define MPCheckpointResetPasswordCounter      @"MPCheckpointResetPasswordCounter"
#define MPCheckpointIncrementPasswordCounter  @"MPCheckpointIncrementPasswordCounter"
#define MPCheckpointEditPassword              @"MPCheckpointEditPassword"
#define MPCheckpointEditUserName              @"MPCheckpointEditUserName"
#define MPCheckpointCloseAlert                @"MPCheckpointCloseAlert"
#define MPCheckpointCloseOutdatedAlert        @"MPCheckpointCloseOutdatedAlert"
#define MPCheckpointUseType                   @"MPCheckpointUseType"
#define MPCheckpointDeleteElement             @"MPCheckpointDeleteElement"
#define MPCheckpointCancelSearch              @"MPCheckpointCancelSearch"
#define MPCheckpointExternalLink              @"MPCheckpointExternalLink"
#define MPCheckpointLaunched                  @"MPCheckpointLaunched"
#define MPCheckpointActivated                 @"MPCheckpointActivated"
#define MPCheckpointDeactivated               @"MPCheckpointDeactivated"
#define MPCheckpointTerminated                @"MPCheckpointTerminated"
#define MPCheckpointShowGuide                 @"MPCheckpointShowGuide"
#define MPCheckpointForgetSavedKey            @"MPCheckpointForgetSavedKey"
#define MPCheckpointChangeMP                  @"MPCheckpointChangeMP"
#define MPCheckpointLocalStoreIncompatible    @"MPCheckpointLocalStoreIncompatible"
#define MPCheckpointCloudStoreIncompatible    @"MPCheckpointCloudStoreIncompatible"
#define MPCheckpointSignInFailed              @"MPCheckpointSignInFailed"
#define MPCheckpointSignedIn                  @"MPCheckpointSignedIn"
#define MPCheckpointConfig                    @"MPCheckpointConfig"
#define MPCheckpointCloud                     @"MPCheckpointCloud"
#define MPCheckpointCloudEnabled              @"MPCheckpointCloudEnabled"
#define MPCheckpointCloudDisabled             @"MPCheckpointCloudDisabled"
#define MPCheckpointSitesImported             @"MPCheckpointSitesImported"
#define MPCheckpointSitesExported             @"MPCheckpointSitesExported"
#define MPCheckpointExplicitMigration         @"MPCheckpointExplicitMigration"

#define MPNotificationSignedIn                @"MPNotificationKeySet"
#define MPNotificationSignedOut               @"MPNotificationKeyUnset"
#define MPNotificationKeyForgotten            @"MPNotificationKeyForgotten"
#define MPNotificationElementUpdated          @"MPNotificationElementUpdated"
