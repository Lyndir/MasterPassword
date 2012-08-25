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
//  GTLPlusConstants.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   Google+ API (plus/v1moments)
// Description:
//   The Google+ API enables developers to build on top of the Google+ platform.
// Documentation:
//   http://developers.google.com/+/api/

#import <Foundation/Foundation.h>

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLDefines.h"
#else
  #import "GTLDefines.h"
#endif

// Authorization scope
// Know who you are on Google
GTL_EXTERN NSString * const kGTLAuthScopePlusMe;             // "https://www.googleapis.com/auth/plus.me"
// View and manage user activity information in Google+
GTL_EXTERN NSString * const kGTLAuthScopePlusMomentsWrite;   // "https://www.googleapis.com/auth/plus.moments.write"
// View your email address
GTL_EXTERN NSString * const kGTLAuthScopePlusUserinfoEmail;  // "https://www.googleapis.com/auth/userinfo.email"

// Collection
GTL_EXTERN NSString * const kGTLPlusCollectionVault;  // "vault"
