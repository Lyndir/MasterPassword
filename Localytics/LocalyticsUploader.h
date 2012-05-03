//  LocalyticsUploader.h
//  Copyright (C) 2009 Char Software Inc., DBA Localytics
// 
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.  
// 
// Please visit www.localytics.com for more information.

#import <UIKit/UIKit.h>

/*!
 @class LocalyticsUploader
 @discussion Singleton class to handle data uploads
 */

@interface LocalyticsUploader : NSObject {
}

@property (readonly) BOOL isUploading;

/*!
 @method sharedLocalyticsUploader
 @abstract Establishes this as a Singleton Class allowing for data persistence.
 The class is accessed within the code using the following syntax:
 [[LocalyticsUploader sharedLocalyticsUploader] functionHere]
 */
+ (LocalyticsUploader *)sharedLocalyticsUploader;

/*!
 @method LocalyticsUploader
 @abstract Creates a thread which uploads all queued header and event data.
 All files starting with sessionFilePrefix are renamed,
 uploaded and deleted on upload.  This way the sessions can continue
 writing data regardless of whether or not the upload succeeds.  Files
 which have been renamed still count towards the total number of Localytics
 files which can be stored on the disk.
 @param localyticsApplicationKey the Localytics application ID
 */
- (void)uploaderWithApplicationKey:(NSString *)localyticsApplicationKey;

@end