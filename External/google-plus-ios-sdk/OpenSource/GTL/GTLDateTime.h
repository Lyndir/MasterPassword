/* Copyright (c) 2011 Google Inc.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

//
//  GTLDateTime.h
//

#import <Foundation/Foundation.h>
#import "GTLDefines.h"

@interface GTLDateTime : NSObject <NSCopying> {
  NSDateComponents *dateComponents_;
  NSInteger milliseconds_; // This is only for the fraction of a second 0-999
  NSInteger offsetSeconds_; // may be NSUndefinedDateComponent
  BOOL isUniversalTime_; // preserves "Z"
  NSTimeZone *timeZone_; // specific time zone by name, if known
}

// Note: nil can be passed for time zone arguments when the time zone is not
//       known.

+ (GTLDateTime *)dateTimeWithRFC3339String:(NSString *)str;
+ (GTLDateTime *)dateTimeWithDate:(NSDate *)date timeZone:(NSTimeZone *)tz;

- (void)setFromDate:(NSDate *)date timeZone:(NSTimeZone *)tz;
- (void)setFromRFC3339String:(NSString *)str;

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSCalendar *calendar;

@property (nonatomic, readonly) NSString *RFC3339String;
@property (nonatomic, readonly) NSString *stringValue; // same as RFC3339String

@property (nonatomic, retain) NSTimeZone *timeZone;
@property (nonatomic, copy) NSDateComponents *dateComponents;
@property (nonatomic, assign) NSInteger milliseconds; // This is only for the fraction of a second 0-999

@property (nonatomic, assign) BOOL hasTime;
@property (nonatomic, assign) NSInteger offsetSeconds;
@property (nonatomic, assign, getter=isUniversalTime) BOOL universalTime;

- (void)setTimeZone:(NSTimeZone *)timeZone withOffsetSeconds:(NSInteger)val;

@end
