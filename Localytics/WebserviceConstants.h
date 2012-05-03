//  WebserviceConstants.h
//  Copyright (C) 2009 Char Software Inc., DBA Localytics
// 
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.  
// 
// Please visit www.localytics.com for more information.

// The constants which are used to make up the JSON blob
// To save disk space and network bandwidth all the keywords have been
// abbreviated and are exploded by the server.  

/*********************
 * Shared Attributes *
 *********************/
#define PARAM_UUID                  @"u"        // UUID for JSON document
#define PARAM_DATA_TYPE             @"dt"       // Data Type
#define PARAM_CLIENT_TIME           @"ct"       // Client Time, seconds from Unix epoch (int)
#define PARAM_LATITUDE              @"lat"      // Latitude - if available
#define PARAM_LONGITUDE             @"lon"      // Longitude - if available
#define PARAM_SESSION_UUID          @"su"       // UUID for an existing session
#define PARAM_NEW_SESSION_UUID      @"u"        // UUID for a new session
#define PARAM_ATTRIBUTES            @"attrs"    // Attributes (dictionary)

/***************
 * Blob Header *
 ***************/

// PARAM_UUID
// PARAM_DATA_TYPE => "h" for Header
// PARAM_ATTRIBUTES => dictionary containing Header Common Attributes
#define PARAM_PERSISTED_AT          @"pa"       // Persistent Storage Created At. A timestamp created when the app was
                                                // first launched and the persistent storage was created. Stores as 
                                                // seconds from Unix epoch. (int)
#define PARAM_SEQUENCE_NUMBER       @"seq"      // Sequence number - an increasing count for each blob, stored in the
                                                // persistent store Consistent across app starts. (int)

/****************************
 * Header Common Attributes *
 ****************************/

// PARAM_DATA_TYPE
#define PARAM_APP_KEY               @"au"		// Localytics Application ID
#define PARAM_DEVICE_UUID           @"du"		// Device UUID
#define PARAM_DEVICE_UUID_HASHED    @"udid"     // Hashed version of the UUID
#define PARAM_DEVICE_MAC            @"wmac"     // Hashed version of the device Mac
#define PARAM_INSTALL_ID            @"iu"       // Install ID
#define PARAM_JAILBROKEN            @"j"        // Jailbroken (boolean)
#define PARAM_LIBRARY_VERSION       @"lv"		// Client Version
#define PARAM_APP_VERSION           @"av"       // Application Version
#define PARAM_DEVICE_PLATFORM       @"dp"		// Device Platform
#define PARAM_LOCALE_LANGUAGE       @"dll"		// Locale Language
#define PARAM_LOCALE_COUNTRY        @"dlc"		// Locale Country
#define PARAM_NETWORK_COUNTRY       @"nc"       // Network Country (iso code)   // ???: Never used on iPhone.
#define PARAM_DEVICE_COUNTRY        @"dc"       // Device Country (iso code)
#define PARAM_DEVICE_MANUFACTURER	@"dma"      // Device Manufacturer          // ???: Never used on iPhone. Used to be "Device Make".
#define PARAM_DEVICE_MODEL          @"dmo"      // Device Model
#define PARAM_DEVICE_OS_VERSION     @"dov"      // Device OS Version
#define PARAM_NETWORK_CARRIER       @"nca"      // Network Carrier
#define PARAM_DATA_CONNECTION       @"dac"      // Data Connection Type         // ???: Never used on iPhone.
#define PARAM_OPT_VALUE             @"optin"	// Opt In (boolean)
#define PARAM_DEVICE_MEMORY         @"dmem"     // Device Memory

/*****************
 * Session Start *
 *****************/

// PARAM_UUID
// PARAM_DATA_TYPE => "s" for Start
// PARAM_CLIENT_TIME
#define PARAM_SESSION_NUMBER        @"nth"      // This is the nth session on the device, 1-indexed (int)

/****************
 * Session Stop *
 ****************/

// PARAM_UUID
// PARAM_DATA_TYPE => "c" for Close
// PARAM_CLIENT_TIME
// PARAM_LATITUDE
// PARAM_LONGITUDE
// PARAM_SESSION_UUID => UUID of session being closed
#define PARAM_SESSION_ACTIVE        @"cta"      // Active time in seconds (time app was active)
#define PARAM_SESSION_TOTAL         @"ctl"      // Total session length
#define PARAM_SESSION_SCREENFLOW    @"fl"       // Screens encountered during this session, in order

/*********************
 * Application Event *
 *********************/

// PARAM_UUID
// PARAM_DATA_TYPE => "e" for Event
// PARAM_CLIENT_TIME
// PARAM_LATITUDE
// PARAM_LONGITUDE
// PARAM_SESSION_UUID => UUID of session event occured in
// PARAM_ATTRIBUTES => dictionary containing attributes for this event as key-value string pairs
#define PARAM_EVENT_NAME            @"n"        // Event Name, (eg. 'Button Click')
#define PARAM_REPORT_ATTRIBUTES     @"rattrs"   // Attributes used in custom reports

/********************
 * Application flow *
 ********************/

// PARAM_UUID
// PARAM_DATA_TYPE => "f" for Flow
// PARAM_CLIENT_TIME
#define PARAM_SESSION_START         @"ss"   // Start time for the current session.
#define PARAM_NEW_FLOW_EVENTS       @"nw"   // Events and screens encountered during this session that have NOT been staged for upload.
#define PARAM_OLD_FLOW_EVENTS       @"od"   // Events and screens encountered during this session that HAVE been staged for upload.