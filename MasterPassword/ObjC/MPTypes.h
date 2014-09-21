//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPKey.h"

typedef NS_ENUM( NSUInteger, MPSiteTypeClass ) {
    /** Generate the password. */
            MPSiteTypeClassGenerated = 1 << 4,
    /** Store the password. */
            MPSiteTypeClassStored = 1 << 5,
};

typedef NS_ENUM( NSUInteger, MPSiteVariant ) {
    /** Generate the password. */
            MPSiteVariantPassword,
    /** Generate the login name. */
            MPSiteVariantLogin,
};

typedef NS_ENUM( NSUInteger, MPSiteFeature ) {
    /** Export the key-protected content data. */
            MPSiteFeatureExportContent = 1 << 10,
    /** Never export content. */
            MPSiteFeatureDevicePrivate = 1 << 11,
};

typedef NS_ENUM(NSUInteger, MPSiteType) {
    MPSiteTypeGeneratedMaximum = 0x0 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedLong = 0x1 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedMedium = 0x2 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedBasic = 0x4 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedShort = 0x3 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedPIN = 0x5 | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedName = 0xE | MPSiteTypeClassGenerated | 0x0,
    MPSiteTypeGeneratedPhrase = 0xF | MPSiteTypeClassGenerated | 0x0,

    MPSiteTypeStoredPersonal = 0x0 | MPSiteTypeClassStored | MPSiteFeatureExportContent,
    MPSiteTypeStoredDevicePrivate = 0x1 | MPSiteTypeClassStored | MPSiteFeatureDevicePrivate,
};

#define MPErrorDomain                         @"MPErrorDomain"

#define MPCheckpointHelpChapter               @"MPCheckpointHelpChapter"
#define MPCheckpointCopyToPasteboard          @"MPCheckpointCopyToPasteboard"
#define MPCheckpointCopyLoginNameToPasteboard @"MPCheckpointCopyLoginNameToPasteboard"
#define MPCheckpointResetPasswordCounter      @"MPCheckpointResetPasswordCounter"
#define MPCheckpointIncrementPasswordCounter  @"MPCheckpointIncrementPasswordCounter"
#define MPCheckpointEditPassword              @"MPCheckpointEditPassword"
#define MPCheckpointEditLoginName             @"MPCheckpointEditLoginName"
#define MPCheckpointUseType                   @"MPCheckpointUseType"
#define MPCheckpointDeleteSite                @"MPCheckpointDeleteSite"
#define MPCheckpointShowGuide                 @"MPCheckpointShowGuide"
#define MPCheckpointShowSetup                 @"MPCheckpointShowSetup"
#define MPCheckpointChangeMP                  @"MPCheckpointChangeMP"
#define MPCheckpointMPErrorUbiquity           @"MPCheckpointMPErrorUbiquity"
#define MPCheckpointLocalStoreReset           @"MPCheckpointLocalStoreReset"
#define MPCheckpointCloudStoreReset           @"MPCheckpointCloudStoreReset"
#define MPCheckpointSignInFailed              @"MPCheckpointSignInFailed"
#define MPCheckpointSignedIn                  @"MPCheckpointSignedIn"
#define MPCheckpointConfig                    @"MPCheckpointConfig"
#define MPCheckpointCloud                     @"MPCheckpointCloud"
#define MPCheckpointSitesImported             @"MPCheckpointSitesImported"
#define MPCheckpointSitesExported             @"MPCheckpointSitesExported"
#define MPCheckpointExplicitMigration         @"MPCheckpointExplicitMigration"
#define MPCheckpointReview                    @"MPCheckpointReview"
#define MPCheckpointApps                      @"MPCheckpointApps"
#define MPCheckpointApp                       @"MPCheckpointApp"
#define MPCheckpointEmergencyGenerator        @"MPCheckpointEmergencyGenerator"
#define MPCheckpointLogs                      @"MPCheckpointLogs"
#define MPCheckpointStarted                   @"MPCheckpointStarted"

#define MPSignedInNotification                @"MPSignedInNotification"
#define MPSignedOutNotification               @"MPSignedOutNotification"
#define MPKeyForgottenNotification            @"MPKeyForgottenNotification"
#define MPSiteUpdatedNotification             @"MPSiteUpdatedNotification"
#define MPCheckConfigNotification             @"MPCheckConfigNotification"
#define MPSitesImportedNotification           @"MPSitesImportedNotification"
#define MPFoundInconsistenciesNotification    @"MPFoundInconsistenciesNotification"

#define MPSitesImportedNotificationUserKey    @"MPSitesImportedNotificationUserKey"
#define MPInconsistenciesFixResultUserKey     @"MPInconsistenciesFixResultUserKey"

#define MPProductGenerateLogins               @"com.lyndir.masterpassword.products.generatelogins"
#define MPProductGenerateAnswers              @"com.lyndir.masterpassword.products.generateanswers"

static void MPCheckpoint(NSString *checkpoint, NSDictionary *attributes) {

    inf(@"%@: %@", checkpoint, attributes);
}
