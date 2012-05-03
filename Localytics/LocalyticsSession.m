//  LocalyticsSession.m
//  Copyright (C) 2009 Char Software Inc., DBA Localytics
// 
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.  
// 
// Please visit www.localytics.com for more information.

#import "LocalyticsSession.h"
#import "WebserviceConstants.h"
#import "LocalyticsUploader.h"
#import "LocalyticsDatabase.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/mach.h>
#include <sys/socket.h>
#include <net/if_dl.h>
#include <ifaddrs.h>
#include <CommonCrypto/CommonDigest.h>

#pragma mark Constants
#define PREFERENCES_KEY             @"_localytics_install_id" // The randomly generated ID for each install of the app
#define CLIENT_VERSION              @"iOS_2.6"      // The version of this library
#define LOCALYTICS_DIR              @".localytics"	// The directory in which the Localytics database is stored
#define IFT_ETHER                   0x6             // Ethernet CSMACD
#define PATH_TO_APT                 @"/private/var/lib/apt/"

#define DEFAULT_BACKGROUND_SESSION_TIMEOUT 15   // Default value for how many seconds a session persists when App shifts to the background.

// The singleton session object.
static LocalyticsSession *_sharedLocalyticsSession = nil;

@interface LocalyticsSession() 

@property (nonatomic, retain) NSString *sessionUUID;
@property (nonatomic, retain) NSString *applicationKey;
@property (nonatomic, assign) NSTimeInterval lastSessionStartTimestamp;
@property (nonatomic, retain) NSDate *sessionResumeTime;
@property (nonatomic, retain) NSDate *sessionCloseTime;
@property (nonatomic, retain) NSMutableString *unstagedFlowEvents;
@property (nonatomic, retain) NSMutableString *stagedFlowEvents;
@property (nonatomic, retain) NSMutableString *screens;
@property (nonatomic, assign) NSTimeInterval sessionActiveDuration;
@property (nonatomic, assign) BOOL sessionHasBeenOpen;

// Private methods.
- (void)ll_open;
- (void)reopenPreviousSession;
- (void)addFlowEventWithName:(NSString *)name type:(NSString *)eventType;
- (void)addScreenWithName:(NSString *)name;
- (NSString *)blobHeaderStringWithSequenceNumber:(int)nextSequenceNumber;
- (BOOL)ll_isOptedIn;
- (BOOL)createOptEvent:(BOOL)optState;
- (BOOL)saveApplicationFlowAndRemoveOnResume:(BOOL)removeOnResume;
- (NSString *)formatAttributeWithName:(NSString *)paramName value:(NSString *)paramValue;
- (NSString *)formatAttributeWithName:(NSString *)paramName value:(NSString *)paramValue first:(BOOL)firstAttribute;
- (void)logMessage:(NSString *)message;

// Datapoint methods.
- (NSString *)customDimensions;
- (NSString *)macAddress;
- (NSString *)hashString:(NSString *)input;
- (NSString *)randomUUID;
- (NSString *)escapeString:(NSString *)input;
- (NSString *)installationId;
- (NSString *)uniqueDeviceIdentifier;
- (NSString *)appVersion;
- (NSTimeInterval)currentTimestamp;
- (BOOL)isDeviceJailbroken;
- (NSString *)deviceModel;
- (NSString *)modelSizeString;
- (double)availableMemory;

@end

@implementation LocalyticsSession

@synthesize queue                       = _queue;
@synthesize criticalGroup               = _criticalGroup;
@synthesize sessionUUID                 = _sessionUUID; 
@synthesize applicationKey              = _applicationKey;
@synthesize lastSessionStartTimestamp   = _lastSessionStartTimestamp;
@synthesize sessionResumeTime           = _sessionResumeTime;
@synthesize sessionCloseTime            = _sessionCloseTime;
@synthesize isSessionOpen               = _isSessionOpen;
@synthesize hasInitialized              = _hasInitialized;
@synthesize backgroundSessionTimeout    = _backgroundSessionTimeout;
@synthesize unstagedFlowEvents          = _unstagedFlowEvents;
@synthesize stagedFlowEvents            = _stagedFlowEvents;
@synthesize screens                     = _screens;
@synthesize sessionActiveDuration       = _sessionActiveDuration;
@synthesize sessionHasBeenOpen          = _sessionHasBeenOpen;

#pragma mark Singleton

+ (LocalyticsSession *)sharedLocalyticsSession {    
	@synchronized(self) {
		if (_sharedLocalyticsSession == nil) {
			_sharedLocalyticsSession = [[self alloc] init];
		}
	}
	return _sharedLocalyticsSession;
}

- (LocalyticsSession *)init {
	if((self = [super init])) {
        _isSessionOpen  = NO;
        _hasInitialized = NO;
        _backgroundSessionTimeout = DEFAULT_BACKGROUND_SESSION_TIMEOUT;
        _sessionHasBeenOpen = NO;
        _queue = dispatch_queue_create("com.Localytics.operations", DISPATCH_QUEUE_SERIAL);
        _criticalGroup = dispatch_group_create();
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        [LocalyticsDatabase sharedLocalyticsDatabase];
    }
    
    return self;
}

#pragma mark Public Methods

- (void)LocalyticsSession:(NSString *)appKey {	    
	// If the session has already initialized, don't bother doing it again.
	if(self.hasInitialized) 
	{
		[self logMessage:@"Object has already been initialized."];
		return;
	}	
    
	@try {
        
        if(appKey == (id)[NSNull null] || appKey.length == 0) {
            [self logMessage:@"App key is null or empty."];
            self.hasInitialized = NO;
            return;
        }
        
        // App key should only be alphanumeric chars and dashes.        
        NSString *trimmedAppKey = [appKey stringByReplacingOccurrencesOfString:@"-" withString:@""];
        if([[trimmedAppKey stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]] isEqualToString:@""] == false) {
            [self logMessage:@"App key may only contain dashes and alphanumeric characters."];
            self.hasInitialized = NO;
            return;
        }
        
        if ([LocalyticsDatabase sharedLocalyticsDatabase]) {
            // Check if the app key has changed.
            NSString *lastAppKey = [[LocalyticsDatabase sharedLocalyticsDatabase] appKey];
            if (![lastAppKey isEqualToString:appKey]) {
                if (lastAppKey) {
                    // Clear previous events and dimensions to guarantee that new data isn't associated with the old app key.
                    [[LocalyticsDatabase sharedLocalyticsDatabase] resetAnalyticsData];

                    // Vacuum to improve the odds of opening a new session following bulk delete.
                    [[LocalyticsDatabase sharedLocalyticsDatabase] vacuumIfRequired];
                }
                // Record the key for future checks.
                [[LocalyticsDatabase sharedLocalyticsDatabase] updateAppKey:appKey];
            }

            self.applicationKey = appKey;
            self.hasInitialized = YES;
            [self logMessage:[@"Object Initialized.  Application's key is: " stringByAppendingString:self.applicationKey]]; 
        }
	}
	@catch (NSException * e) {}
}

- (void)startSession:(NSString *)appKey {
	[self LocalyticsSession:appKey];
	[self open];
	[self upload];
}

// Public interface to ll_open.
- (void)open {
    dispatch_async(_queue, ^{
        [self ll_open];
    });
}

- (void)resume {
    dispatch_async(_queue, ^{
      // Do nothing if session is already open
      if(self.isSessionOpen == YES)
        return;

      if([self ll_isOptedIn] == false) {
        [self logMessage:@"Can't resume session because user is opted out."];
        return;
      }  

      // conditions for resuming previous session
      if(self.sessionHasBeenOpen &&
         (!self.sessionCloseTime ||
          [self.sessionCloseTime timeIntervalSinceNow]*-1 <= self.backgroundSessionTimeout)) {
             // Note that we allow the session to be resumed even if the database size exceeds the
             // maximum. This is because we don't want to create incomplete sessions. If the DB was large
             // enough that the previous session could not be opened, there will be nothing to resume. But 
             // if this session caused it to go over it is better to let it complete and stop the next one
             // from being created.
             [self logMessage:@"Resume called - Resuming previous session."];
             [self reopenPreviousSession];
      } else {
        // otherwise open new session and upload
        [self logMessage:@"Resume called - Opening a new session."];
        [self ll_open];
      }
      self.sessionCloseTime = nil;
    });
}

- (void)close {
    dispatch_group_async(_criticalGroup, _queue, ^{
        // Do nothing if the session is not open
        if (self.isSessionOpen == NO) {
            [self logMessage:@"Unable to close session"];
            return; 
        }

        // Save time of close
        self.sessionCloseTime = [NSDate date];
        
        // Update active session duration.
        self.sessionActiveDuration += [self.sessionCloseTime timeIntervalSinceDate:self.sessionResumeTime];

        int sessionLength = (int)[[NSDate date] timeIntervalSince1970] - self.lastSessionStartTimestamp;
        
        @try {
            // Create the JSON representing the close blob
            NSMutableString *closeEventString = [NSMutableString string];
            [closeEventString appendString:@"{"];
            [closeEventString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE         value:@"c"                      first:YES]];
            [closeEventString appendString:[self formatAttributeWithName:PARAM_SESSION_UUID      value:self.sessionUUID]];
            [closeEventString appendString:[self formatAttributeWithName:PARAM_UUID              value:[self randomUUID] ]];
            [closeEventString appendFormat:@",\"%@\":%u", PARAM_SESSION_START, (long)self.lastSessionStartTimestamp];
            [closeEventString appendFormat:@",\"%@\":%u", PARAM_SESSION_ACTIVE, (long)self.sessionActiveDuration];
            [closeEventString appendFormat:@",\"%@\":%u", PARAM_CLIENT_TIME, (long)[self currentTimestamp]];
            
            // Avoid recording session lengths of users with unreasonable client times (usually caused by developers testing clock change attacks)
            if(sessionLength > 0 && sessionLength < 400000) {
                [closeEventString appendFormat:@",\"%@\":%u", PARAM_SESSION_TOTAL, sessionLength];
            }

            // Open second level - screen flow
            [closeEventString appendFormat:@",\"%@\":[", PARAM_SESSION_SCREENFLOW];
            [closeEventString appendString:self.screens];

            // Close second level - screen flow
            [closeEventString appendString:@"]"];

            // Append the custom dimensions
            [closeEventString appendString:[self customDimensions]];
            
            // Close first level - close blob 
            [closeEventString appendString:@"}\n"];
            
            BOOL success = [[LocalyticsDatabase sharedLocalyticsDatabase] addCloseEventWithBlobString:[[closeEventString copy] autorelease]];
            
            self.isSessionOpen = NO;  // Session is no longer open.

            if (success) {
                // Record final session flow, opting to remove it from the database if the session happens to resume.
                // This is safe now that the session has closed because no new events can be added.
                success = [self saveApplicationFlowAndRemoveOnResume:YES];
            }
            
            if (success) {
                [self logMessage:@"Session succesfully closed."];
            } else {
                [self logMessage:@"Failed to record session close."];
            }
        }
        @catch (NSException * e) {}
    });
}

- (void)setOptIn:(BOOL)optedIn {
    dispatch_async(_queue, ^{
        @try {
            LocalyticsDatabase *db = [LocalyticsDatabase sharedLocalyticsDatabase];
            NSString *t = @"set_opt";
            BOOL success = [db beginTransaction:t];
            
            // Write out opt event.
            if (success) {
                success =  [self createOptEvent:optedIn];
            }

            // Update database with the option (stored internally as an opt-out).
            if (success) {
                [db setOptedOut:optedIn == NO];
            }
            
            if (success && optedIn == NO) {
                // Disable all further Localytics calls for this and future sessions
                // This should not be flipped when the session is opted back in because that
                // would create an incomplete session.
                self.isSessionOpen = NO;
            }
            
            if (success) {
                [db releaseTransaction:t];
                [self logMessage:[NSString stringWithFormat:@"Application opted %@", optedIn ? @"in" : @"out"]];
            } else {
                [db rollbackTransaction:t];
                [self logMessage:@"Failed to update opt state."];
            }
        }
        @catch (NSException * e) {}
    });
}

// Public interface to ll_isOptedIn.
- (BOOL)isOptedIn {
    __block BOOL optedIn = YES;
    dispatch_sync(_queue, ^{
        optedIn = [self ll_isOptedIn];
    });
    return optedIn;
}

// A convenience function for users who don't wish to add attributes.
- (void)tagEvent:(NSString *)event {
	[self tagEvent:event attributes:nil reportAttributes:nil];
}

// Most users should use this tagEvent call.
- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes {
	[self tagEvent:event attributes:attributes reportAttributes:nil];
}

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes reportAttributes:(NSDictionary *)reportAttributes {
    dispatch_async(_queue, ^{
        @try {
            // Do nothing if the session is not open.
            if (self.isSessionOpen == NO) 
            {
                [self logMessage:@"Cannot tag an event because the session is not open."];
                return; 
            }
        
            if(event == (id)[NSNull null] || event.length == 0)
            {
                [self logMessage:@"Event tagged without a name. Skipping."];
                return;
            }
            
            // Create the JSON for the event
            NSMutableString *eventString = [[[NSMutableString alloc] init] autorelease];
            [eventString appendString:@"{"];
            [eventString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE     value:@"e" first:YES] ];
            [eventString appendString:[self formatAttributeWithName:PARAM_UUID          value:[self randomUUID] ]];
            [eventString appendString:[self formatAttributeWithName:PARAM_APP_KEY       value:self.applicationKey ]];
            [eventString appendString:[self formatAttributeWithName:PARAM_SESSION_UUID  value:self.sessionUUID ]];
            [eventString appendString:[self formatAttributeWithName:PARAM_EVENT_NAME    value:[self escapeString:event] ]];
            [eventString appendFormat:@",\"%@\":%u", PARAM_CLIENT_TIME, (long)[self currentTimestamp]];

            // Append the custom dimensions
            [eventString appendString:[self customDimensions]];
            
            // If there are any attributes for this event, add them as a hash
            int attrIndex = 0;
            if(attributes != nil)
            {
                // Open second level - attributes
                [eventString appendString:[NSString stringWithFormat:@",\"%@\":{", PARAM_ATTRIBUTES]];
                for (id key in [attributes allKeys])
                {
                    // Have to escape paramName and paramValue because they user-defined.
                    [eventString appendString:
                     [self formatAttributeWithName:[self escapeString:[key description]] 
                                             value:[self escapeString:[[attributes valueForKey:key] description]]
                                             first:(attrIndex == 0)]];
                    attrIndex++;
                }
                
                // Close second level - attributes
                [eventString appendString:@"}"];
            }

            // If there are any report attributes for this event, add them as above
            attrIndex = 0;
            if(reportAttributes != nil)
            {
                [eventString appendString:[NSString stringWithFormat:@",\"%@\":{", PARAM_REPORT_ATTRIBUTES]];
                for(id key in [reportAttributes allKeys]) {
                    [eventString appendString:
                     [self formatAttributeWithName:[self escapeString:[key description]] 
                                             value:[self escapeString:[[reportAttributes valueForKey:key] description]]
                                             first:(attrIndex == 0)]];
                    attrIndex++;
                }
                [eventString appendString:@"}"];
            }
            
            // Close first level - Event information
            [eventString appendString:@"}\n"];

            BOOL success = [[LocalyticsDatabase sharedLocalyticsDatabase] addEventWithBlobString:[[eventString copy] autorelease]];
            if (success) {
                // User-originated events should be tracked as application flow.
                [self addFlowEventWithName:event type:@"e"]; // "e" for Event.

                [self logMessage:[@"Tagged event: " stringByAppendingString:event]];
            } else {
                [self logMessage:@"Failed to tag event."];
            }
        }
        @catch (NSException * e) {}
    });
}

- (void)tagScreen:(NSString *)screen {
    dispatch_async(_queue, ^{        
        // Do nothing if the session is not open.
        if (self.isSessionOpen == NO) 
        {
            [self logMessage:@"Cannot tag a screen because the session is not open."];
            return; 
        }

        // Tag screen with description to enforce string type and avoid retaining objects passed by clients in lieu of a
        // screen name.
        NSString *screenName = [screen description];
        [self addFlowEventWithName:screenName type:@"s"]; // "s" for Screen.

        // Maintain a parallel list of only screen names. This is submitted in the session close event.
        // This may be removed in a future version of the client library.
        [self addScreenWithName:screenName];

        [self logMessage:[@"Tagged screen: " stringByAppendingString:screenName]];
    });
}

- (void)setCustomDimension:(int)dimension value:(NSString *)value {
    dispatch_async(_queue, ^{
        if(dimension < 0 || dimension > 3) {
            [self logMessage:@"Only valid dimensions are 0 - 3"];
            return;
        }
        
        if(false == [[LocalyticsDatabase sharedLocalyticsDatabase] setCustomDimension:dimension value:value]) {
            [self logMessage:@"Unable to set custom dimensions."];
        }
    });
}

- (void)upload {
    dispatch_group_async(_criticalGroup, _queue, ^{
        @try {
            if ([[LocalyticsUploader sharedLocalyticsUploader] isUploading]) {
                [self logMessage:@"An upload is already in progress. Aborting."];
                return;
            }

            NSString *t = @"stage_upload";
            LocalyticsDatabase *db = [LocalyticsDatabase sharedLocalyticsDatabase];
            BOOL success = [db beginTransaction:t];

            // - The event list for the current session is not modified
            // New flow events are only transitioned to the "old" list if the upload is staged successfully. The queue
            // ensures that the list of events are not modified while a call to upload is in progress.
            if (success) {
                // Write flow blob to database. This is for a session in progress and should not be removed upon resume.
                success = [self saveApplicationFlowAndRemoveOnResume:NO];
            }

            if (success && [db unstagedEventCount] > 0) {
                // Increment upload sequence number.
                int sequenceNumber = 0;
                success = [db incrementLastUploadNumber:&sequenceNumber];
                
                // Write out header to database.
                sqlite3_int64 headerRowId = 0;
                if (success) {
                    NSString *headerBlob = [self blobHeaderStringWithSequenceNumber:sequenceNumber];
                    success = [db addHeaderWithSequenceNumber:sequenceNumber blobString:headerBlob rowId:&headerRowId];
                }

                // Associate unstaged events.
                if (success) {
                    success = [db stageEventsForUpload:headerRowId];
                }
            }
            
            if (success) {
                // Complete transaction
                [db releaseTransaction:t];

                // Move new flow events to the old flow event array.
                if (self.unstagedFlowEvents.length) {
                    if (self.stagedFlowEvents.length) {
                        [self.stagedFlowEvents appendFormat:@",%@", self.unstagedFlowEvents];
                    } else {
                        self.stagedFlowEvents = [[self.unstagedFlowEvents mutableCopy] autorelease];
                    }
                    self.unstagedFlowEvents = [NSMutableString string];
                }
                
                // Begin upload.
                [[LocalyticsUploader sharedLocalyticsUploader] uploaderWithApplicationKey:self.applicationKey];     
            } else {
                [db rollbackTransaction:t];
                [self logMessage:@"Failed to start upload."];
            }
        }
        @catch (NSException * e) { }
    });
}

#pragma mark Private Methods

- (void)ll_open {
    // There are a number of conditions in which nothing should be done:
    if (self.hasInitialized == NO ||  // the session object has not yet initialized
        self.isSessionOpen == YES)  // session has already been opened
    {
        [self logMessage:@"Unable to open session."];
        return; 
    }
    
    if([self ll_isOptedIn] == false) {
        [self logMessage:@"Can't open session because user is opted out."];
        return;
    }
    
    @try {
        // If there is too much data on the disk, don't bother collecting any more.
        LocalyticsDatabase *db = [LocalyticsDatabase sharedLocalyticsDatabase];
        if([db databaseSize] > MAX_DATABASE_SIZE) {
            [self logMessage:@"Database has exceeded the maximum size. Session not opened."];
            self.isSessionOpen = NO;
            return;
        }
        
        self.sessionActiveDuration = 0;
        self.sessionResumeTime = [NSDate date];
        self.unstagedFlowEvents = [NSMutableString string];
        self.stagedFlowEvents = [NSMutableString string];
        self.screens = [NSMutableString string];
        
        // Begin transaction for session open.
        NSString *t = @"open_session";
        BOOL success = [db beginTransaction:t];
        
        // Save session start time.
        self.lastSessionStartTimestamp = [self.sessionResumeTime timeIntervalSince1970];
        if (success) {
            success = [db setLastsessionStartTimestamp:self.lastSessionStartTimestamp];
        }
        
        // Retrieve next session number.
        int sessionNumber = 0;
        if (success) {
            success = [db incrementLastSessionNumber:&sessionNumber];
        }
        
        if (success) {
            // Prepare session open event.          
            self.sessionUUID = [self randomUUID];
            
            // Store event.
            NSMutableString *openEventString = [NSMutableString string];
            [openEventString appendString:@"{"];
            [openEventString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE              value:@"s"              first:YES]];
            [openEventString appendString:[self formatAttributeWithName:PARAM_NEW_SESSION_UUID           value:self.sessionUUID]];
            [openEventString appendFormat:@",\"%@\":%u", PARAM_CLIENT_TIME, (long)self.lastSessionStartTimestamp];
            [openEventString appendFormat:@",\"%@\":%d", PARAM_SESSION_NUMBER, sessionNumber];            
            
            [openEventString appendString:[self customDimensions]];
            
            [openEventString appendString:@"}\n"];
            
            [self customDimensions];
            
            success = [db addEventWithBlobString:[[openEventString copy] autorelease]];
        }
        
        if (success) {
            [db releaseTransaction:t];
            self.isSessionOpen = YES;
            self.sessionHasBeenOpen = YES;
            [self logMessage:[@"Succesfully opened session. UUID is: " stringByAppendingString:self.sessionUUID]];
        } else {
            [db rollbackTransaction:t];
            self.isSessionOpen = NO;
            [self logMessage:@"Failed to open session."];
        }
    }
    @catch (NSException * e) {}
}

/*!
 @method reopenPreviousSession
 @abstract Reopens the previous session, using previous session variables. If there was no previous session, do nothing.
*/
- (void)reopenPreviousSession {
    if(self.sessionHasBeenOpen == NO){
        [self logMessage:@"Unable to reopen previous session, because a previous session was never opened."];
    return;
    }

    // Record session resume time.
    self.sessionResumeTime = [NSDate date];

    //Remove close and flow events if they exist.
    [[LocalyticsDatabase sharedLocalyticsDatabase] removeLastCloseAndFlowEvents];

    self.isSessionOpen = YES;
}

/*!
 @method addFlowEventWithName:type:
 @abstract Adds a simple key-value pair to the list of events tagged during this session.
 @param name The name of the tagged event.
 @param eventType A key representing the type of the tagged event. Either "s" for Screen or "e" for Event.
 */
- (void)addFlowEventWithName:(NSString *)name type:(NSString *)eventType {
    if (!name || !eventType)
        return;
    
    // Format new event as simple key-value dictionary.
    NSString *eventString = [self formatAttributeWithName:eventType value:[self escapeString:name] first:YES];
    
    // Flow events are uploaded as a sequence of key-value pairs. Wrap the above in braces and append to the list.
    BOOL previousFlowEvents = self.unstagedFlowEvents.length > 0;
    if (previousFlowEvents) {
        [self.unstagedFlowEvents appendString:@","];
    }
    [self.unstagedFlowEvents appendFormat:@"{%@}", eventString];
}

/*!
 @method addScreenWithName:
 @abstract Adds a name to list of screens encountered during this session.
 @discussion The complete list of names is sent with the session close event. Screen names are stored in parallel to the
 screen flow events list and may be removed in future versions of this library.
 @param name The name of the tagged screen.
 */
- (void)addScreenWithName:(NSString *)name {
    if (self.screens.length > 0) {
        [self.screens appendString:@","];
    }
    [self.screens appendFormat:@"\"%@\"", [self escapeString:name]];
}

/*!
 @method blobHeaderStringWithSequenceNumber:
 @abstract Creates the JSON string for the upload blob header, substituting in the given upload sequence number.
 @param  nextSequenceNumber The sequence number for the current upload attempt.
 @return The upload header JSON blob.
 */
- (NSString *)blobHeaderStringWithSequenceNumber:(int)nextSequenceNumber {

    NSMutableString *headerString = [[[NSMutableString alloc] init] autorelease];

    // Common header information.
	UIDevice *thisDevice = [UIDevice currentDevice];
	NSLocale *locale = [NSLocale currentLocale];
	NSLocale *english = [[[NSLocale alloc] initWithLocaleIdentifier: @"en_US"] autorelease];
	NSLocale *device_locale = [[NSLocale preferredLanguages] objectAtIndex:0];	
    NSString *device_language = [english displayNameForKey:NSLocaleIdentifier value:device_locale];
	NSString *locale_country = [english displayNameForKey:NSLocaleCountryCode value:[locale objectForKey:NSLocaleCountryCode]];
    NSString *uuid = [self randomUUID];
    NSString *device_uuid = [self uniqueDeviceIdentifier];

    // Open first level - blob information
    [headerString appendString:@"{"];
    [headerString appendFormat:@"\"%@\":%d", PARAM_SEQUENCE_NUMBER, nextSequenceNumber];
    [headerString appendFormat:@",\"%@\":%u", PARAM_PERSISTED_AT, (long)[[LocalyticsDatabase sharedLocalyticsDatabase] createdTimestamp]];
    [headerString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE    value:@"h" ]];
    [headerString appendString:[self formatAttributeWithName:PARAM_UUID         value:uuid ]];

    // Open second level - blob header attributes
    [headerString appendString:[NSString stringWithFormat:@",\"%@\":{", PARAM_ATTRIBUTES]];
    [headerString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE    value:@"a"  first:YES]];
    
	// >>  Application and session information
    [headerString appendString:[self formatAttributeWithName:PARAM_INSTALL_ID       value:[self installationId] ]];
	[headerString appendString:[self formatAttributeWithName:PARAM_APP_KEY          value:self.applicationKey ]];
	[headerString appendString:[self formatAttributeWithName:PARAM_APP_VERSION      value:[self appVersion]  ]];
	[headerString appendString:[self formatAttributeWithName:PARAM_LIBRARY_VERSION  value:CLIENT_VERSION        ]];
     
    // >>  Device Information
//	[headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_UUID          value:device_uuid ]];
    [headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_UUID_HASHED   value:[self hashString:device_uuid] ]];
	[headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_PLATFORM      value:[thisDevice model]            ]];
	[headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_OS_VERSION    value:[thisDevice systemVersion]    ]];
	[headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_MODEL         value:[self deviceModel]         ]];

// MAC Address collection. Uncomment the following line to add Mac address to the mix of collected identifiers
//    [headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_MAC value:[self hashString:[self macAddress]]     ]];    
	[headerString appendString:[NSString stringWithFormat:@",\"%@\":%d", PARAM_DEVICE_MEMORY, (long)[self availableMemory]  ]];	
	[headerString appendString:[self formatAttributeWithName:PARAM_LOCALE_LANGUAGE   value:device_language]];
	[headerString appendString:[self formatAttributeWithName:PARAM_LOCALE_COUNTRY    value:locale_country]];
	[headerString appendString:[self formatAttributeWithName:PARAM_DEVICE_COUNTRY    value:[locale objectForKey:NSLocaleCountryCode]]];
	[headerString appendString:[NSString stringWithFormat:@",\"%@\":%@", PARAM_JAILBROKEN, [self isDeviceJailbroken] ? @"true" : @"false"]];
    
    //  Close second level - attributes
    [headerString appendString:@"}"];
    
    // Close first level - blob information
    [headerString appendString:@"}\n"];

	return [[headerString copy] autorelease];
}

- (BOOL)ll_isOptedIn {
    return [[LocalyticsDatabase sharedLocalyticsDatabase] isOptedOut] == NO;
}

/*!
 @method createOptEvent:
 @abstract Generates the JSON for an opt event (user opting in or out) and writes it to the database.
 @return YES if the event was written to the database, NO otherwise
 */
- (BOOL)createOptEvent:(BOOL)optState {
	NSMutableString *optEventString = [NSMutableString string];
    [optEventString appendString:@"{"];
    [optEventString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE  value:@"o"                  first:YES]];
	[optEventString appendString:[self formatAttributeWithName:PARAM_APP_KEY    value:self.applicationKey   first:NO]];
	[optEventString appendString:[NSString stringWithFormat:@",\"%@\":%@", PARAM_OPT_VALUE, (optState ? @"true" : @"false") ]];	
    [optEventString appendFormat:@",\"%@\":%u", PARAM_CLIENT_TIME, (long)[self currentTimestamp]];
	[optEventString appendString:@"}\n"];

    BOOL success = [[LocalyticsDatabase sharedLocalyticsDatabase] addEventWithBlobString:[[optEventString copy] autorelease]];
    return success;
}

/*
 @method saveApplicationFlowAndRemoveOnResume:
 @abstract Constructs an application flow blob string and writes it to the database, optionally flagging it for deletion
 if the session is resumed.
 @param removeOnResume YES if the application flow blob should be deleted if the session is resumed.
 @return YES if the application flow event was written to the database successfully.
 */
- (BOOL)saveApplicationFlowAndRemoveOnResume:(BOOL)removeOnResume {
    BOOL success = YES;
    
    // If there are no new events, then there is nothing additional to save.
    if (self.unstagedFlowEvents.length) {
        // Flows are uploaded as a distinct blob type containing arrays of new and previously-uploaded event and
        // screen names. Write a flow event to the database.
        NSMutableString *flowEventString = [[[NSMutableString alloc] init] autorelease];
        
        // Open first level - flow blob event
        [flowEventString appendString:@"{"];
        [flowEventString appendString:[self formatAttributeWithName:PARAM_DATA_TYPE value:@"f"                  first:YES]];
        [flowEventString appendString:[self formatAttributeWithName:PARAM_UUID      value:[self randomUUID] ]];
        [flowEventString appendFormat:@",\"%@\":%u", PARAM_SESSION_START, (long)self.lastSessionStartTimestamp];
        
        // Open second level - new flow events
        [flowEventString appendFormat:@",\"%@\":[", PARAM_NEW_FLOW_EVENTS];
        [flowEventString appendString:self.unstagedFlowEvents]; // Flow events are escaped in |-addFlowEventWithName:|
        // Close second level - new flow events
        [flowEventString appendString:@"]"];
        
        // Open second level - old flow events
        [flowEventString appendFormat:@",\"%@\":[", PARAM_OLD_FLOW_EVENTS];
        [flowEventString appendString:self.stagedFlowEvents];
        // Close second level - old flow events
        [flowEventString appendString:@"]"];
        
        // Close first level - flow blob event
        [flowEventString appendString:@"}\n"];
        
        success = [[LocalyticsDatabase sharedLocalyticsDatabase] addFlowEventWithBlobString:[[flowEventString copy] autorelease]];
    }
    return success;
}

// Convenience method for formatAttributeWithName which sets firstAttribute to NO since
// this is the most common way to call it.
- (NSString *)formatAttributeWithName:(NSString *)paramName value:(NSString *)paramValue {
    return [self formatAttributeWithName:paramName value:paramValue first:NO];
}

/*!
 @method formatAttributeWithName:value:firstAttribute:
 @abstract Returns the given string key/value pair as a JSON string.
 @param paramName The name of the parameter 
 @param paramValue The value of the parameter
 @param firstAttribute YES if this attribute is first in an attribute list
 @return a JSON string which can be dumped to the JSON file
 */
- (NSString *)formatAttributeWithName:(NSString *)paramName value:(NSString *)paramValue first:(BOOL)firstAttribute {
	// The expected result is one of:
    //  "paramname":"paramvalue"
    //  "paramname":null
    NSMutableString *formattedString = [NSMutableString string];
    if (!firstAttribute) {
        [formattedString appendString:@","];
    }
    
    NSString *quotedString = @"\"%@\"";
    paramName = [NSString stringWithFormat:quotedString, paramName];
    paramValue = paramValue ? [NSString stringWithFormat:quotedString, paramValue] : @"null";
    [formattedString appendFormat:@"%@:%@", paramName, paramValue];
	return [[formattedString copy] autorelease];
}

/*!
 @method escapeString
 @abstract Formats the input string so it fits nicely in a JSON document.  This includes
 escaping double quote and slash characters.
 @return The escaped version of the input string
 */
- (NSString *)escapeString:(NSString *)input
{		
	NSString *output = [input stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	output = [output stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    output = [output stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    return output;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self logMessage:@"Application entered the background."];

    // Continue executing until critical blocks finish executing or background time runs out, whichever comes first.
    UIApplication *application = (UIApplication *)[notification object];
    __block UIBackgroundTaskIdentifier taskID = [application beginBackgroundTaskWithExpirationHandler:^{
        // Synchronize with the main queue in case the the tasks finish at the same time as the expiration handler.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (taskID != UIBackgroundTaskInvalid) {
                [self logMessage:@"Failed to finish executing critical tasks. Cleaning up."];
                [application endBackgroundTask:taskID];
                taskID = UIBackgroundTaskInvalid;
            }
        });
    }];

    // Critical tasks have finished. Expire the background task.
    dispatch_group_notify(_criticalGroup, dispatch_get_main_queue(), ^{
        [self logMessage:@"Finished executing critical tasks."];
        if (taskID != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:taskID];        
            taskID = UIBackgroundTaskInvalid;
        }
    });
}

/*!
 @method logMessage
 @abstract Logs a message with (localytics) prepended to it.
 @param message The message to log
 */
- (void)logMessage:(NSString *)message
{
    if(DO_LOCALYTICS_LOGGING) {
        NSLog(@"(localytics) %s\n", [message UTF8String]);
    }
}

#pragma mark Datapoint Functions
/*!
 @method customDimensions
 @abstract Returns the json blob containing the custom dimensions. Assumes this will be appended
 to an existing blob and as a result prepends the results with a comma.
 */
- (NSString *)customDimensions
{
    NSMutableString *dimensions = [[[NSMutableString alloc] init] autorelease];
    
    for(int i=0; i <4; i++) {
        NSString *dimension = [[LocalyticsDatabase sharedLocalyticsDatabase] customDimension:i];
        if(dimension) {
            [dimensions appendFormat:@",\"c%i\":\"%@\"", i, dimension];
        }            
    }
    
    return [[dimensions copy] autorelease];
}

/*!
 @method macAddress
 @abstract Returns the macAddress of this device.
 */
- (NSString *)macAddress
{
    NSMutableString* result = [NSMutableString string];
    
    BOOL success;
    struct ifaddrs* addrs;
    const struct ifaddrs* cursor;
    const struct sockaddr_dl* dlAddr;
    const uint8_t * base;
    int i;
    
    success = (getifaddrs(&addrs) == 0);
    if(success)
    {
        cursor = addrs;
        while(cursor != NULL)
        {
            if((cursor->ifa_addr->sa_family == AF_LINK) && (((const struct sockaddr_dl *) cursor->ifa_addr)->sdl_type == IFT_ETHER))
            {
                dlAddr = (const struct sockaddr_dl *) cursor->ifa_addr;                
                base = (const uint8_t *) &dlAddr->sdl_data[dlAddr->sdl_nlen];
                
                for(i=0; i<dlAddr->sdl_alen; i++) 
                {
                    if(i != 0) {
                        [result appendString:@":"];
                    }
                    [result appendFormat:@"%02x", base[i]];
                }
                break;
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    return result;
}

/*!
 @method hashString
 @abstract SHA1 Hashes a string
 */
- (NSString *)hashString:(NSString *)input
{
    NSData *stringBytes = [input dataUsingEncoding: NSUTF8StringEncoding];
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    
    if (CC_SHA1([stringBytes bytes], [stringBytes length], digest)) {
        NSMutableString* hashedUUID = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
        for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
            [hashedUUID appendFormat:@"%02x", digest[i]];
        }
        return hashedUUID;
    }
    
    return nil;
}

/*!
 @method randomUUID
 @abstract Generates a random UUID
 @return NSString containing the new UUID
 */
- (NSString *)randomUUID {
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef stringUUID = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return [(NSString *)stringUUID autorelease];
}

/*!
 @method installationId
 @abstract Looks in user preferences for an ID unique to this installation. If one is not
 found it checks if one happens to be in the database (carroyover from older version of the db)
 if not, it generates one.
 @return A string uniquely identifying this installation of this app
 */
- (NSString *) installationId {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *installId = [prefs stringForKey:PREFERENCES_KEY];
    
    if(installId == nil)
    {
        [self logMessage:@"Install ID not found in preferences, checking DB"];
        installId = [[LocalyticsDatabase sharedLocalyticsDatabase] installId];
    }
    
    // If it hasn't been found yet, generate a new one.
    if(installId == nil)
    {
        [self logMessage:@"Install ID not find one in database, generating a new one."];
        installId = [self randomUUID];
    }

    // Store the newly generated installId
    [prefs setObject:installId forKey:PREFERENCES_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
 
    return installId;
}

/*!
 @method uniqueDeviceIdentifier
 @abstract A unique device identifier is a hash value composed from various hardware identifiers such
 as the device’s serial number. It is guaranteed to be unique for every device but cannot 
 be tied to a user account. [UIDevice Class Reference]
 @return An 1-way hashed identifier unique to this device.
 */
- (NSString *)uniqueDeviceIdentifier {

// Supress the warning for uniqueIdentifier being deprecated.
// We collect it as long as it is available along with a randomly generated ID.
// This way, when this becomes unavailable we can map existing users so the
// new vs returning counts do not break. This will be removed before it causes grief.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	NSString *systemId = [[UIDevice currentDevice] uniqueIdentifier];
#pragma clang diagnostic pop    
    
	return systemId;
}

/*!
 @method appVersion
 @abstract Gets the pretty string for this application's version.
 @return The application's version as a pretty string
 */
- (NSString *)appVersion {
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];	
}

/*!
 @method currentTimestamp
 @abstract Gets the current time as seconds since Unix epoch.
 @return an NSTimeInterval time.
 */
- (NSTimeInterval)currentTimestamp {
    return [[NSDate date] timeIntervalSince1970];
}

/*!
 @method isDeviceJailbroken
 @abstract checks for the existance of apt to determine whether the user is running any
 of the jailbroken app sources.
 @return whether or not the device is jailbroken.
 */
- (BOOL) isDeviceJailbroken {
	NSFileManager *sessionFileManager = [NSFileManager defaultManager];	
	return [sessionFileManager fileExistsAtPath:PATH_TO_APT];
}

/*!
 @method deviceModel
 @abstract Gets the device model string. 
 @return a platform string identifying the device
 */
- (NSString *)deviceModel {
	char *buffer[256] = { 0 };
	size_t size = sizeof(buffer);
    sysctlbyname("hw.machine", buffer, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:(const char*)buffer
											encoding:NSUTF8StringEncoding];
	return platform;
}	

/*!
 @method modelSizeString
 @abstract Checks how much disk space is reported and uses that to determine the model
 @return A string identifying the model, e.g. 8GB, 16GB, etc
 */
- (NSString *) modelSizeString {
	
#if TARGET_IPHONE_SIMULATOR
	return @"simulator";
#endif
	
	// User partition
	NSArray *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *stats = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[path lastObject] error:nil];  
	uint64_t user = [[stats objectForKey:NSFileSystemSize] longLongValue];
	
	// System partition
	path = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSSystemDomainMask, YES);
    stats = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[path lastObject] error:nil];  
	uint64_t system = [[stats objectForKey:NSFileSystemSize] longLongValue];
	
	// Add up and convert to gigabytes
	// TODO: seem to be missing a system partiton or two...
	NSInteger size = (user + system) >> 30;
	
	// Find nearest power of 2 (eg, 1,2,4,8,16,32,etc).  Over 64 and we return 0
	for (NSInteger gig = 1; gig < 257; gig = gig << 1) {
		if (size < gig)
			return [NSString stringWithFormat:@"%dGB", gig];
	}
	return nil;
}

/*!
 @method availableMemory
 @abstract Reports how much memory is available  
 @return A double containing the available free memory
 */
- (double)availableMemory {
	double result = NSNotFound;
	vm_statistics_data_t stats;
	mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
	if (!host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&stats, &count))
		result = vm_page_size * stats.free_count;

	return result;
}


#pragma mark System Functions
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (_sharedLocalyticsSession == nil) {
			_sharedLocalyticsSession = [super allocWithZone:zone];
			return _sharedLocalyticsSession;
		}
	}
	// returns nil on subsequent allocations
	return nil;
}

- (id)copyWithZone:(NSZone *)zone {
	return self;
}

- (id)retain {
	return self;
}

- (unsigned)retainCount {
	// maximum value of an unsigned int - prevents additional retains for the class
	return UINT_MAX;
}

- (oneway void)release {
	// ignore release commands
}

- (id)autorelease {
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

    dispatch_release(_criticalGroup);
    dispatch_release(_queue);
	[_sessionUUID release];
	[_applicationKey release];
	[_sessionCloseTime release];
    [_unstagedFlowEvents release];
    [_stagedFlowEvents release];
    [_screens release];
	[_sharedLocalyticsSession release];

	[super dealloc];
}

@end
