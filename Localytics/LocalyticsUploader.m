//  LocalyticsUploader.m
//  Copyright (C) 2009 Char Software Inc., DBA Localytics
// 
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.  
// 
// Please visit www.localytics.com for more information.

#import "LocalyticsUploader.h"
#import "LocalyticsSession.h"
#import "LocalyticsDatabase.h"
#import <zlib.h>

#define LOCALYTICS_URL    @"http://analytics.localytics.com/api/v2/applications/%@/uploads"

static LocalyticsUploader *_sharedUploader = nil;

@interface LocalyticsUploader ()
- (void)finishUpload;
- (NSData *)gzipDeflatedDataWithData:(NSData *)data;
- (void)logMessage:(NSString *)message;

@property (readwrite) BOOL isUploading;

@end

@implementation LocalyticsUploader
@synthesize isUploading = _isUploading;

#pragma mark - Singleton Class
+ (LocalyticsUploader *)sharedLocalyticsUploader {
	@synchronized(self) {
		if (_sharedUploader == nil) {
			_sharedUploader = [[self alloc] init];			
		}
	}
	return _sharedUploader;
}

#pragma mark - Class Methods

- (void)uploaderWithApplicationKey:(NSString *)localyticsApplicationKey {
	
	// Do nothing if already uploading.
	if (self.isUploading == true) 
	{
		[self logMessage:@"Upload already in progress.  Aborting."];
		return;
	}

	[self logMessage:@"Beginning upload process"];
	self.isUploading = true;
	
	// Prepare the data for upload.  The upload could take a long time, so some effort has to be made to be sure that events
	// which get written while the upload is taking place don't get lost or duplicated.  To achieve this, the logic is:
    // 1) Append every header row blob string and and those of its associated events to the upload string.
    // 2) Deflate and upload the data.
    // 3) On success, delete all blob headers and staged events. Events added while an upload is in process are not
    //    deleted because they are not associated a header (and cannot be until the upload completes).
    
    // Step 1
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    LocalyticsDatabase *db = [LocalyticsDatabase sharedLocalyticsDatabase];
    NSString *blobString = [db uploadBlobString];

    if ([blobString length] == 0) {
        // There is nothing outstanding to upload.
        [self logMessage:@"Abandoning upload. There are no new events."];
        [pool drain];
        [self finishUpload];
        
        return;
    }

	NSData *requestData = [blobString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *myString = [[[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding] autorelease];
    [self logMessage:[NSString  stringWithFormat:@"Uploading data (length: %u)", [myString length]]];
    
    // Step 2
    NSData *deflatedRequestData = [[self gzipDeflatedDataWithData:requestData] retain];
    
    [pool drain];

    NSString *apiUrlString = [NSString stringWithFormat:LOCALYTICS_URL, [localyticsApplicationKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSMutableURLRequest *submitRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:apiUrlString]
																			 cachePolicy:NSURLRequestReloadIgnoringCacheData 
																			 timeoutInterval:60.0];
	[submitRequest setHTTPMethod:@"POST"];
	[submitRequest setValue:@"application/x-gzip" forHTTPHeaderField:@"Content-Type"];
    [submitRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
	[submitRequest setValue:[NSString stringWithFormat:@"%d", [deflatedRequestData length]] forHTTPHeaderField:@"Content-Length"];
	[submitRequest setHTTPBody:deflatedRequestData];
    [deflatedRequestData release];

    // Perform synchronous upload in an async dispatch. This is necessary because the calling block will not persist to
    // receive the response data.
    dispatch_group_async([[LocalyticsSession sharedLocalyticsSession] criticalGroup], [[LocalyticsSession sharedLocalyticsSession] queue], ^{
        @try  {
            NSURLResponse *response = nil;
            NSError *responseError = nil;
            [NSURLConnection sendSynchronousRequest:submitRequest returningResponse:&response error:&responseError];
            NSInteger responseStatusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (responseError) {
                // On error, simply print the error and close the uploader.  We have to assume the data was not transmited
                // so it is not deleted.  In the event that we accidently store data which was succesfully uploaded, the
                // duplicate data will be ignored by the server when it is next uploaded.
                [self logMessage:[NSString stringWithFormat: 
                                  @"Error Uploading.  Code: %d,  Description: %@", 
                                  [responseError code], 
                                  [responseError localizedDescription]]];
            } else {
                // Step 3
                // While response status codes in the 5xx range leave upload rows intact, the default case is to delete.
                if (responseStatusCode >= 500 && responseStatusCode < 600) {
                    [self logMessage:[NSString stringWithFormat:@"Upload failed with response status code %d", responseStatusCode]];
                } else {
                    // Because only one instance of the uploader can be running at a time it should not be possible for
                    // new upload rows to appear so there is no fear of deleting data which has not yet been uploaded.
                    [self logMessage:[NSString stringWithFormat:@"Upload completed successfully. Response code %d", responseStatusCode]];
                    [[LocalyticsDatabase sharedLocalyticsDatabase] deleteUploadedData];
                }
            }
        }
        @catch (NSException * e) {}
        
        [self finishUpload];
    });
}

- (void)finishUpload
{
    self.isUploading = false;
    
    // Upload data has been deleted. Recover the disk space if necessary.
    [[LocalyticsDatabase sharedLocalyticsDatabase] vacuumIfRequired];
}

/*!
 @method gzipDeflatedDataWithData
 @abstract Deflates the provided data using gzip at the default compression level (6). Complete NSData gzip category available on CocoaDev. http://www.cocoadev.com/index.pl?NSDataCategory.
 @return the deflated data
 */
- (NSData *)gzipDeflatedDataWithData:(NSData *)data
{
	if ([data length] == 0) return data;
	
	z_stream strm;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	strm.total_out = 0;
	strm.next_in=(Bytef *)[data bytes];
	strm.avail_in = [data length];
	
	// Compresssion Levels:
	//   Z_NO_COMPRESSION
	//   Z_BEST_SPEED
	//   Z_BEST_COMPRESSION
	//   Z_DEFAULT_COMPRESSION
	
	if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
	
	NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
	
	do {
		
		if (strm.total_out >= [compressed length])
			[compressed increaseLengthBy: 16384];
		
		strm.next_out = [compressed mutableBytes] + strm.total_out;
		strm.avail_out = [compressed length] - strm.total_out;
		
		deflate(&strm, Z_FINISH);  
		
	} while (strm.avail_out == 0);
	
	deflateEnd(&strm);
	
	[compressed setLength: strm.total_out];
	return [NSData dataWithData:compressed];
}

/*!
 @method logMessage
 @abstract Logs a message with (localytics uploader) prepended to it
 @param message The message to log
 */
- (void) logMessage:(NSString *)message {
    if(DO_LOCALYTICS_LOGGING) {
		NSLog(@"(localytics uploader) %s\n", [message UTF8String]);
    }
}

#pragma mark - System Functions
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (_sharedUploader == nil) {
			_sharedUploader = [super allocWithZone:zone];
			return _sharedUploader;
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
	[_sharedUploader release];
    [super dealloc];
}

@end
