//  UploaderThread.m
//  Copyright (C) 2009 Char Software Inc., DBA Localytics
// 
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.  
// 
// Please visit www.localytics.com for more information.

#import "UploaderThread.h"
#import "LocalyticsSession.h"
#import "LocalyticsDatabase.h"
#import <zlib.h>

#define LOCALYTICS_URL             @"http://analytics.localytics.com/api/v2/applications/%@/uploads"            // url to send the 

static UploaderThread *_sharedUploaderThread = nil;

@interface UploaderThread ()
- (void)complete;
- (NSData *)gzipDeflatedDataWithData:(NSData *)data;
- (void)logMessage:(NSString *)message;
@end

@implementation UploaderThread

@synthesize uploadConnection   = _uploadConnection;
@synthesize isUploading        = _isUploading;

#pragma mark Singleton Class
+ (UploaderThread *)sharedUploaderThread {
	@synchronized(self) {
		if (_sharedUploaderThread == nil) 
		{
			_sharedUploaderThread = [[self alloc] init];			
		}
	}
	return _sharedUploaderThread;
}

#pragma mark Class Methods
- (void)uploaderThreadwithApplicationKey:(NSString *)localyticsApplicationKey {
	
	// Do nothing if already uploading.
	if (self.uploadConnection != nil || self.isUploading == true) 
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
        [self complete];
        return;
    }

	NSData *requestData = [blobString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *myString = [[[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding] autorelease];
    [self logMessage:@"Upload data:"];
    [self logMessage:myString];
    
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
	
	// The NSURLConnection Object automatically spawns its own thread as a default behavior.
	@try 
	{
		[self logMessage:@"Spawning new thread for upload"];
		self.uploadConnection = [NSURLConnection connectionWithRequest:submitRequest delegate:self];
		
		// Step 3 is handled by connectionDidFinishLoading.
	}
	@catch (NSException * e) 
	{ 
		[self complete];
	}	
}

#pragma mark **** NSURLConnection FUNCTIONS ****

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	// Used to gather response data from server - Not utilized in this version
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // Could receive multiple response callbacks, likely due to redirection.
    // Record status and act only when connection completes load.
    _responseStatusCode = [(NSHTTPURLResponse *)response statusCode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// If the connection finished loading, the files should be deleted. While response status codes in the 5xx range
    // leave upload rows intact, the default case is to delete.
    if (_responseStatusCode >= 500 && _responseStatusCode < 600)
    {
        [self logMessage:[NSString stringWithFormat:@"Upload failed with response status code %d", _responseStatusCode]];
    } else
    {
        // The connection finished loading and uploaded data should be deleted.  Because only one instance of the
        // uploader can be running at a time it should not be possible for new upload rows to appear so there is no
        // fear of deleting data which has not yet been uploaded.
        [self logMessage:[NSString stringWithFormat:@"Upload completed successfully. Response code %d", _responseStatusCode]];
        [[LocalyticsDatabase sharedLocalyticsDatabase] deleteUploadData];
    }

	// Close upload session
	[self complete];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	// On error, simply print the error and close the uploader.  We have to assume the data was not transmited
	// so it is not deleted.  In the event that we accidently store data which was succesfully uploaded, the
	// duplicate data will be ignored by the server when it is next uploaded.
	[self logMessage:[NSString stringWithFormat: 
					  @"Error Uploading.  Code: %d,  Description: %s", 
					  [error code], 
					  [error localizedDescription]]];

	[self complete];
}

/*!
 @method complete
 @abstract closes the upload connection and reports back to the session that the upload is complete
 */
- (void)complete {
    _responseStatusCode = 0;
	self.uploadConnection = nil;
	self.isUploading = false;
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

#pragma mark System Functions
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (_sharedUploaderThread == nil) {
			_sharedUploaderThread = [super allocWithZone:zone];
			return _sharedUploaderThread;
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
	[_uploadConnection release];
	[_sharedUploaderThread release];
    [super dealloc];
}

@end
