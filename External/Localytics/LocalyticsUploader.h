//  LocalyticsUploader.h
//  Copyright (C) 2013 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
//  Please visit www.localytics.com for more information.

#import <UIKit/UIKit.h>

extern NSString * const kLocalyticsKeyResponseBody;

/*!
 @class LocalyticsUploader
 @discussion Singleton class to handle data uploads
 */

@interface LocalyticsUploader : NSObject {
}

@property (readonly, atomic) BOOL isUploading;

/*!
 @method LocalyticsUploader
 @abstract Creates a thread which uploads all queued header and event data.
 All files starting with sessionFilePrefix are renamed,
 uploaded and deleted on upload.  This way the sessions can continue
 writing data regardless of whether or not the upload succeeds.  Files
 which have been renamed still count towards the total number of Localytics
 files which can be stored on the disk.
 
 This version of the method now just calls the second version of it with a nil target and NULL callback method.
 @param localyticsApplicationKey the Localytics application ID
 @param useHTTPS Flag determining whether HTTP or HTTPS is used for the post URL.
 @param installId Install id passed to the server in the x-install-id header field.
 @param libraryVersion Library version to be passed to the server in the x-client-version header field.
 */
- (void)uploaderWithApplicationKey:(NSString *)localyticsApplicationKey useHTTPS:(BOOL)useHTTPS installId:(NSString *)installId libraryVersion:(NSString *)libraryVersion;

/*!
 @method LocalyticsUploader
 @abstract Creates a thread which uploads all queued header and event data.
 All files starting with sessionFilePrefix are renamed,
 uploaded and deleted on upload.  This way the sessions can continue
 writing data regardless of whether or not the upload succeeds.  Files
 which have been renamed still count towards the total number of Localytics
 files which can be stored on the disk.
 @param localyticsApplicationKey the Localytics application ID
 @param useHTTPS Flag determining whether HTTP or HTTPS is used for the post URL.
 @param installId Install id passed to the server in the x-install-id header field.
 @param libraryVersion Library version to be passed to the server in the x-client-version header field.
 @param resultTarget Result target is the target for the callback method that knows how to handle response data
 @param callback Callback is the method of the target class that is to be called with the data begin returned by an upload
 */
- (void)uploaderWithApplicationKey:(NSString *)localyticsApplicationKey useHTTPS:(BOOL)useHTTPS installId:(NSString *)installId libraryVersion:(NSString *)libraryVersion resultTarget:(id)target callback:(SEL)callbackMethod;


/*!
 @method uploadTimeStamp
 @abstract Retrieve upload TimeStamp.
 */
- (NSString *)uploadTimeStamp;

@end
