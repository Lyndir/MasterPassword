//
//  LocalyticsDatabase.h
//  Copyright (C) 2013 Char Software Inc., DBA Localytics
//
//  This code is provided under the Localytics Modified BSD License.
//  A copy of this license has been distributed in a file called LICENSE
//  with this source code.
//
// Please visit www.localytics.com for more information.

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#define MAX_DATABASE_SIZE   500000  // The maximum allowed disk size of the primary database file at open, in bytes
#define VACUUM_THRESHOLD    0.8     // The database is vacuumed after its size exceeds this proportion of the maximum.

@interface LocalyticsDatabase : NSObject {
    sqlite3 *_databaseConnection;
}

@property (nonatomic, assign, readonly) BOOL firstRun;

- (unsigned long long)databaseSize;
- (int)eventCount;
- (NSTimeInterval)createdTimestamp;

- (BOOL)beginTransaction:(NSString *)name;
- (BOOL)releaseTransaction:(NSString *)name;
- (BOOL)rollbackTransaction:(NSString *)name;

- (BOOL)incrementLastUploadNumber:(int *)uploadNumber;
- (BOOL)incrementLastSessionNumber:(int *)sessionNumber;

- (BOOL)addEventWithBlobString:(NSString *)blob;
- (BOOL)addCloseEventWithBlobString:(NSString *)blob;
- (BOOL)queueCloseEventWithBlobString:(NSString *)blob;
- (NSString *)dequeueCloseEventBlobString;
- (BOOL)addFlowEventWithBlobString:(NSString *)blob;
- (BOOL)removeLastCloseAndFlowEvents;

- (BOOL)addHeaderWithSequenceNumber:(int)number blobString:(NSString *)blob rowId:(sqlite3_int64 *)insertedRowId;
- (int)unstagedEventCount;
- (BOOL)stageEventsForUpload:(sqlite3_int64)headerId;
- (BOOL)updateAppKey:(NSString *)appKey;
- (NSString *)uploadBlobString;
- (BOOL)deleteUploadedData;
- (BOOL)resetAnalyticsData;
- (BOOL)vacuumIfRequired;

- (NSTimeInterval)lastSessionStartTimestamp;
- (BOOL)setLastSessionStartTimestamp:(NSTimeInterval)timestamp;

- (BOOL)isOptedOut;
- (BOOL)setOptedOut:(BOOL)optOut;
- (NSString *)appVersion;
- (BOOL)updateAppVersion:(NSString *)appVersion;
- (NSString *)installId;
- (NSString *)appKey; // Most recent app key-- may not be that used to open the session.

- (NSString *)customDimension:(int)dimension;
- (BOOL)setCustomDimension:(int)dimension value:(NSString *)value;

- (BOOL)setValueForIdentifier:(NSString *)identifierName value:(NSString *)value;
- (NSString *)valueForIdentifier:(NSString *)identifierName;
- (BOOL)deleteIdentifer:(NSString *)identifierName;
- (NSDictionary *)identifiers;

- (BOOL)setFacebookAttribution:(NSString *)fbAttribution;
- (NSString *)facebookAttributionFromDb;
- (NSString *)facebookAttributionFromPasteboard;

- (NSInteger)safeIntegerValueFromDictionary:(NSDictionary *)dict forKey:(NSString *)key;
- (NSString *)safeStringValueFromDictionary:(NSDictionary *)dict forKey:(NSString *)key;
- (NSDictionary *)safeDictionaryFromDictionary:(NSDictionary *)dict forKey:(NSString *)key;
- (NSArray *)safeListFromDictionary:(NSDictionary *)dict forKey:(NSString *)key;


@end
