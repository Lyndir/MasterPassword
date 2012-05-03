//
//  Crashlytics.h
//  Crashlytics
//
//  Copyright 2012 Crashlytics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CrashlyticsDelegate;

@interface Crashlytics : NSObject {
@private
	NSString *_apiKey;
	NSString *_dataDirectory;
	NSString *_bundleIdentifier;
	BOOL _installed;
	NSMutableDictionary *_customAttributes;
	id _user;
	NSInteger _sendButtonIndex;
	NSInteger _alwaysSendButtonIndex;
	NSObject <CrashlyticsDelegate> *_delegate;
}

@property (nonatomic, readonly, copy) NSString *apiKey;
@property (nonatomic, readonly, copy) NSString *version;
@property (nonatomic, assign)         BOOL      debugMode;

@property (nonatomic, assign)         NSObject <CrashlyticsDelegate> *delegate;

/**
 *
 * The recommended way to install Crashlytics into your application is to place a call
 * to +startWithAPIKey: in your -application:didFinishLaunchingWithOptions: method.
 *
 * This delay defaults to 1 second in order to generally give the application time to 
 * fully finish launching.
 *
 **/
+ (Crashlytics *)startWithAPIKey:(NSString *)apiKey;
+ (Crashlytics *)startWithAPIKey:(NSString *)apiKey afterDelay:(NSTimeInterval)delay;

/**
 *
 * If you need the functionality provided by the CrashlyticsDelegate protocol, you can use
 * these convenience methods to activate the framework and set the delegate in one call.
 *
 **/
+ (Crashlytics *)startWithAPIKey:(NSString *)apiKey delegate:(NSObject <CrashlyticsDelegate> *)delegate;
+ (Crashlytics *)startWithAPIKey:(NSString *)apiKey delegate:(NSObject <CrashlyticsDelegate> *)delegate afterDelay:(NSTimeInterval)delay;

/**
 *
 * Access the singleton Crashlytics instance.
 *
 **/
+ (Crashlytics *)sharedInstance;

/**
 *
 * The easiest way to cause a crash - great for testing!
 *
 **/
- (void)crash;

@end

/**
 *
 * The CrashlyticsDelegate protocol provides a mechanism for your application to take
 * action on events that occur in the Crashlytics crash reporting system.  You can make 
 * use of these calls by assigning an object to the Crashlytics' delegate property directly,
 * or through the convenience startWithAPIKey:delegate:... methods.
 *
 **/
@protocol CrashlyticsDelegate <NSObject>
@optional

/**
 *
 * Called once a Crashlytics instance has determined that the last execution of the 
 * application ended in a crash.  This is called some time after the crash reporting
 * process has begun.  If you have specififed a delay in one of the
 * startWithAPIKey:... calls, this will take at least that long to be invoked.
 *
 **/
- (void)crashlyticsDidDetectCrashDuringPreviousExecution:(Crashlytics *)crashlytics;

@end
