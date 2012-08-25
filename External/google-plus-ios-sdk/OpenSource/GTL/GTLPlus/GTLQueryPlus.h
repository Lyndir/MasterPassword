/* Copyright (c) 2012 Google Inc.
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
//  GTLQueryPlus.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   Google+ API (plus/v1moments)
// Description:
//   The Google+ API enables developers to build on top of the Google+ platform.
// Documentation:
//   http://developers.google.com/+/api/
// Classes:
//   GTLQueryPlus (2 custom class methods, 4 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLQuery.h"
#else
  #import "GTLQuery.h"
#endif

@class GTLPlusMoment;

@interface GTLQueryPlus : GTLQuery

//
// Parameters valid on all methods.
//

// Selector specifying which fields to include in a partial response.
@property (copy) NSString *fields;

//
// Method-specific parameters; see the comments below for more information.
//
@property (copy) NSString *collection;
@property (assign) BOOL debug;
@property (copy) NSString *userId;

#pragma mark -
#pragma mark "moments" methods
// These create a GTLQueryPlus object.

// Method: plus.moments.insert
// Record a user activity (e.g Bill watched a video on Youtube)
//  Required:
//   userId: The ID of the user to get activities for. The special value "me"
//     can be used to indicate the authenticated user.
//   collection: The collection to which to write moments.
//      kGTLPlusCollectionVault: The default collection for writing new moments.
//  Optional:
//   debug: Return the moment as written. Should be used only for debugging.
//  Authorization scope(s):
//   kGTLAuthScopePlusMomentsWrite
// Fetches a GTLPlusMoment.
+ (id)queryForMomentsInsertWithObject:(GTLPlusMoment *)object
                               userId:(NSString *)userId
                           collection:(NSString *)collection;

#pragma mark -
#pragma mark "people" methods
// These create a GTLQueryPlus object.

// Method: plus.people.get
// Get a person's profile.
//  Required:
//   userId: The ID of the person to get the profile for. The special value "me"
//     can be used to indicate the authenticated user.
//  Authorization scope(s):
//   kGTLAuthScopePlusMe
//   kGTLAuthScopePlusUserinfoEmail
// Fetches a GTLPlusPerson.
+ (id)queryForPeopleGetWithUserId:(NSString *)userId;

@end
