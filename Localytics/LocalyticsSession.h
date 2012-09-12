//  LocalyticsSession.h
//  Copyright (C) 2012 Char Software Inc., DBA Localytics
// 
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.  
// 
// Please visit www.localytics.com for more information.

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

// Set this to true to enable localytics traces (useful for debugging)
#define DO_LOCALYTICS_LOGGING false

/*!
 @class LocalyticsSession 
 @discussion The class which manages creating, collecting, & uploading a Localytics session.
 Please see the following guides for information on how to best use this
 library, sample code, and other useful information:
 <ul>
 <li><a href="http://wiki.localytics.com/index.php?title=Developer's_Integration_Guide">Main Developer's Integration Guide</a></li>
 </ul>

 <strong>Best Practices</strong>
 <ul>
 <li>Instantiate the LocalyticsSession object in applicationDidFinishLaunching.</li>
 <li>Open your session and begin your uploads in applicationDidFinishLaunching. This way the
 upload has time to complete and it all happens before your users have a
 chance to begin any data intensive actions of their own.</li>
 <li>Close the session in applicationWillTerminate, and in applicationDidEnterBackground.</li>
 <li>Resume the session in applicationWillEnterForeground.</li>
 <li>Do not call any Localytics functions inside a loop.  Instead, calls
 such as <code>tagEvent</code> should follow user actions.  This limits the
 amount of data which is stored and uploaded.</li>
 <li>Do not use multiple LocalticsSession objects to upload data with 
 multiple application keys.  This can cause invalid state.</li>
 </ul>
 
 @author Localytics
 */

@interface LocalyticsSession : NSObject {

	BOOL _hasInitialized;               // Whether or not the session object has been initialized.
	BOOL _isSessionOpen;                // Whether or not this session has been opened.
    float _backgroundSessionTimeout;    // If an App stays in the background for more
                                        // than this many seconds, start a new session
                                        // when it returns to foreground.
	@private
	#pragma mark Member Variables
    dispatch_queue_t _queue;                // Queue of Localytics block objects.
    dispatch_group_t _criticalGroup;        // Group of blocks the must complete before backgrounding.
	NSString *_sessionUUID;                 // Unique identifier for this session.
	NSString *_applicationKey;              // Unique identifier for the instrumented application
    NSTimeInterval _lastSessionStartTimestamp;  // The start time of the most recent session.
    NSDate *_sessionResumeTime;                 // Time session was started or resumed.
    NSDate *_sessionCloseTime;              // Time session was closed.
    NSMutableString *_unstagedFlowEvents;        // Comma-delimited list of app screens and events tagged during this
                                            // session that have NOT been staged for upload.
    NSMutableString *_stagedFlowEvents;        // App screens and events tagged during this session that HAVE been staged
                                            // for upload.
    NSMutableString *_screens;              // Comma-delimited list of screens tagged during this session.
    NSTimeInterval _sessionActiveDuration;  // Duration that session open.
	BOOL _sessionHasBeenOpen;               // Whether or not this session has ever been open.
}

@property (nonatomic,readonly) dispatch_queue_t queue;
@property (nonatomic,readonly) dispatch_group_t criticalGroup;
@property BOOL isSessionOpen;
@property BOOL hasInitialized;		
@property float backgroundSessionTimeout;

- (void)logMessage:(NSString *)message;
@property (nonatomic, assign, readonly) NSTimeInterval lastSessionStartTimestamp;
@property (nonatomic, assign, readonly) NSInteger sessionNumber;


/*!
 @property enableHTTPS
 @abstract Determines whether or not HTTPS is used when calling the Localytics 
 post URL. The default is NO.
 */
@property (nonatomic, assign) BOOL enableHTTPS; // Defaults to NO.

#pragma mark Public Methods
/*!
 @method sharedLocalyticsSession
 @abstract Accesses the Session object.  This is a Singleton class which maintains
 a single session throughout your application.  It is possible to manage your own
 session, but this is the easiest way to access the Localytics object throughout your code.
 The class is accessed within the code using the following syntax:
	[[LocalyticsSession sharedLocalyticsSession] functionHere]
 So, to tag an event, all that is necessary, anywhere in the code is:
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"MY_EVENT"];
 */
+ (LocalyticsSession *)sharedLocalyticsSession;

/*!
 @method LocalyticsSession
 @abstract Initializes the Localytics Object.  Not necessary if you choose to use startSession.
 @param applicationKey The key unique for each application generated at www.localytics.com
 */
- (void)LocalyticsSession:(NSString *)appKey;

/*!
 @method startSession
 @abstract An optional convenience initialize method that also calls the LocalyticsSession, open & 
 upload methods. Best Practice is to call open & upload immediately after Localytics Session when loading an app, 
 this method fascilitates that behavior.
 It is recommended that this call be placed in <code>applicationDidFinishLaunching</code>.
 @param applicationKey The key unique for each application generated
 at www.localytics.com
 */
- (void)startSession:(NSString *)appKey;

/*!
 @method setOptIn
 @abstract (OPTIONAL) Allows the application to control whether or not it will collect user data.  
 Even if this call is used, it is necessary to continue calling upload().  No new data will be
 collected, so nothing new will be uploaded but it is necessary to upload an event telling the
 server this user has opted out.
 @param optedIn True if the user is opted in, false otherwise.
 */
- (void)setOptIn:(BOOL)optedIn;

/*!
 @method isOptedIn
 @abstract (OPTIONAL) Whether or not this user has is opted in or out.  The only way they can be
 opted out is if setOptIn(false) has been called before this.  This function should only be
 used to pre-populate a checkbox in an options menu.  It is not recommended that an application
 branch based on Localytics instrumentation because this creates an additional test case.  If
 the app is opted out, all subsequent Localytics calls will return immediately.
 @result true if the user is opted in, false otherwise.
 */
- (BOOL)isOptedIn;

/*!
 @method open
 @abstract Opens the Localytics session. Not necessary if you choose to use startSession. 
 The session time as presented on the website is the time between <code>open</code> and the 
 final <code>close</code> so it is recommended to open the session as early as possible, and close
 it at the last moment.  The session must be opened before any tags can
 be written.  It is recommended that this call be placed in <code>applicationDidFinishLaunching</code>.
 <br>
 If for any reason this is called more than once every subsequent open call
 will be ignored.
 */
- (void)open;

/*!
 @method resume
 @abstract Resumes the Localytics session.  When the App enters the background, the session is 
 closed and the time of closing is recorded.  When the app returns to the foreground, the session 
 is resumed.  If the time since closing is greater than BACKGROUND_SESSION_TIMEOUT, (15 seconds
 by default) a new session is created, and uploading is triggered.  Otherwise, the previous session 
 is reopened. It is possible to use the return value to determine whether or not a session was resumed.
 This may be useful to some customers looking to do conditional instrumentation at the close of a session.
 It is perfectly reasonable to ignore the return value.
 @result YES if the sesion was resumed NO if it wasn't (suggesting a new session was created instead).*/
- (BOOL)resume;

/*!
 @method close
 @abstract Closes the Localytics session.  This should be called in
 <code>applicationWillTerminate</code>.
 <br>
 If close is not called, the session will still be uploaded but no
 events will be processed and the session time will not appear. This is
 because the session is not yet closed so it should not be used in
 comparison with sessions which are closed.
 */
- (void)close;

/*!
 @method tagEvent
 @abstract Allows a session to tag a particular event as having occurred.  For
 example, if a view has three buttons, it might make sense to tag
 each button click with the name of the button which was clicked. 
 For another example, in a game with many levels it might be valuable
 to create a new tag every time the user gets to a new level in order
 to determine how far the average user is progressing in the game.
 <br>
 <strong>Tagging Best Practices</strong>
 <ul>
 <li>DO NOT use tags to record personally identifiable information.</li>
 <li>The best way to use tags is to create all the tag strings as predefined
 constants and only use those.  This is more efficient and removes the risk of
 collecting personal information.</li>
 <li>Do not set tags inside loops or any other place which gets called
 frequently.  This can cause a lot of data to be stored and uploaded.</li>
 </ul>
 <br>
 See the tagging guide at: http://wiki.localytics.com/
 @param event The name of the event which occurred.
 */
- (void)tagEvent:(NSString *)event;

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes;

- (void)tagEvent:(NSString *)event attributes:(NSDictionary *)attributes reportAttributes:(NSDictionary *)reportAttributes;

/*!
 @method tagScreen
 @abstract Allows tagging the flow of screens encountered during the session.
 @param screen The name of the screen 
 */
- (void)tagScreen:(NSString *)screen;

/*!
 @method upload
 @abstract Creates a low priority thread which uploads any Localytics data already stored 
 on the device.  This should be done early in the process life in order to 
 guarantee as much time as possible for slow connections to complete.  It is also reasonable
 to upload again when the application is exiting because if the upload is cancelled the data
 will just get uploaded the next time the app comes up.
 */
- (void)upload;

/*!
 @method setCustomDimension
 @abstract (ENTERPRISE ONLY) Sets the value of a custom dimension. Custom dimensions are dimensions
 which contain user defined data unlike the predefined dimensions such as carrier, model, and country.
 Once a value for a custom dimension is set, the device it was set on will continue to upload that value
 until the value is changed. To clear a value pass nil as the value. 
 The proper use of custom dimensions involves defining a dimension with less than ten distinct possible
 values and assigning it to one of the four available custom dimensions. Once assigned this definition should
 never be changed without changing the App Key otherwise old installs of the application will pollute new data.
 */
- (void)setCustomDimension:(int)dimension value:(NSString *)value;

/*!
 @method setLocation
 @abstract Stores the user's location.  This will be used in all event and session calls.
 If your application has already collected the user's location, it may be passed to Localytics
 via this function.  This will cause all events and the session close to include the locatin
 information.  It is not required that you call this function. 
 @param deviceLocation The user's location.
 */
- (void)setLocation:(CLLocationCoordinate2D)deviceLocation;

/*!
 @method ampTrigger
 @abstract Displays the AMP message for the specific event.
 Is a stub implementation here to prevent crashes if this class is accidentally used inplace of
 the LocalyticsAmpSession
 @param event Name of the event.
 */
- (void)ampTrigger:(NSString *)event;

@end
