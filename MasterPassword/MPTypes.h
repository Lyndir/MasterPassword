//
//  MPTypes.h
//  MasterPassword
//
//  Created by Maarten Billemont on 02/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MPPersistentStoreDidChangeNotification @"MPPersistentStoreDidChange"

typedef enum {
    MPElementContentTypePassword,
    MPElementContentTypeNote,
    MPElementContentTypePicture,
} MPElementContentType;

typedef enum {
    /** Generate the password. */
    MPElementTypeClassGenerated         = 1 << 4,
    /** Store the password. */
    MPElementTypeClassStored            = 1 << 5,
} MPElementTypeClass;

typedef enum {
    /** Export the key-protected content data. */
    MPElementFeatureExportContent       = 1 << 10,
    /** Never export content. */
    MPElementFeatureDevicePrivate       = 1 << 11,
} MPElementFeature;

typedef enum {
    MPElementTypeGeneratedLong          = 0x0 | MPElementTypeClassGenerated   | 0x0,
    MPElementTypeGeneratedMedium        = 0x1 | MPElementTypeClassGenerated   | 0x0,
    MPElementTypeGeneratedShort         = 0x2 | MPElementTypeClassGenerated   | 0x0,
    MPElementTypeGeneratedBasic         = 0x3 | MPElementTypeClassGenerated   | 0x0,
    MPElementTypeGeneratedPIN           = 0x4 | MPElementTypeClassGenerated   | 0x0,
    
    MPElementTypeStoredPersonal         = 0x0 | MPElementTypeClassStored      | MPElementFeatureExportContent,
    MPElementTypeStoredDevicePrivate    = 0x1 | MPElementTypeClassStored      | MPElementFeatureDevicePrivate,
} MPElementType;

#define MPTestFlightCheckpointAction                    @"MPTestFlightCheckpointAction"
#define MPTestFlightCheckpointHelpChapter               @"MPTestFlightCheckpointHelpChapter_%@"
#define MPTestFlightCheckpointCopyToPasteboard          @"MPTestFlightCheckpointCopyToPasteboard"
#define MPTestFlightCheckpointResetPasswordCounter      @"MPTestFlightCheckpointResetPasswordCounter"
#define MPTestFlightCheckpointIncrementPasswordCounter  @"MPTestFlightCheckpointIncrementPasswordCounter"
#define MPTestFlightCheckpointEditPassword              @"MPTestFlightCheckpointEditPassword"
#define MPTestFlightCheckpointCloseAlert                @"MPTestFlightCheckpointCloseAlert"
#define MPTestFlightCheckpointSelectType                @"MPTestFlightCheckpointSelectType_%@"
#define MPTestFlightCheckpointSelectElement             @"MPTestFlightCheckpointSelectElement"
#define MPTestFlightCheckpointDeleteElement             @"MPTestFlightCheckpointDeleteElement"
#define MPTestFlightCheckpointCancelSearch              @"MPTestFlightCheckpointCancelSearch"
#define MPTestFlightCheckpointExternalLink              @"MPTestFlightCheckpointExternalLink"
#define MPTestFlightCheckpointLaunched                  @"MPTestFlightCheckpointLaunched"
#define MPTestFlightCheckpointActivated                 @"MPTestFlightCheckpointActivated"
#define MPTestFlightCheckpointDeactivated               @"MPTestFlightCheckpointDeactivated"
#define MPTestFlightCheckpointTerminated                @"MPTestFlightCheckpointTerminated"
#define MPTestFlightCheckpointShowGuide                 @"MPTestFlightCheckpointShowGuide"
#define MPTestFlightCheckpointMPForgotten               @"MPTestFlightCheckpointMPForgotten"
#define MPTestFlightCheckpointMPChanged                 @"MPTestFlightCheckpointMPChanged"
#define MPTestFlightCheckpointMPUnstored                @"MPTestFlightCheckpointMPUnstored"
#define MPTestFlightCheckpointMPMismatch                @"MPTestFlightCheckpointMPMismatch"
#define MPTestFlightCheckpointMPEntered                 @"MPTestFlightCheckpointMPEntered"
#define MPTestFlightCheckpointLocalStoreIncompatible    @"MPTestFlightCheckpointLocalStoreIncompatible"
#define MPTestFlightCheckpointCloudStoreIncompatible    @"MPTestFlightCheckpointCloudStoreIncompatible"
#define MPTestFlightCheckpointSetKey                    @"MPTestFlightCheckpointSetKey"
#define MPTestFlightCheckpointCloudEnabled              @"MPTestFlightCheckpointCloudEnabled"
#define MPTestFlightCheckpointCloudDisabled             @"MPTestFlightCheckpointCloudDisabled"
#define MPTestFlightCheckpointSitesImported             @"MPTestFlightCheckpointSitesImported"
#define MPTestFlightCheckpointSitesExported             @"MPTestFlightCheckpointSitesExported"

#define MPNotificationStoreUpdated                      @"MPNotificationStoreUpdated"
#define MPNotificationKeySet                            @"MPNotificationKeySet"
#define MPNotificationKeyUnset                          @"MPNotificationKeyUnset"
#define MPNotificationKeyForgotten                      @"MPNotificationKeyForgotten"
#define MPNotificationElementUsed                       @"MPNotificationElementUsed"

NSData *keyForPassword(NSString *password);
NSData *keyIDForPassword(NSString *password);
NSData *keyIDForKey(NSData *key);
NSString *NSStringFromMPElementType(MPElementType type);
NSString *ClassNameFromMPElementType(MPElementType type);
Class ClassFromMPElementType(MPElementType type);
NSString *MPCalculateContent(MPElementType type, NSString *name, NSData *key, uint32_t counter);
