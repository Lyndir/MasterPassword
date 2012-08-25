//
//  GooglePlusSampleAppDelegate.h
//
//  Copyright 2012 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <UIKit/UIKit.h>

@class GooglePlusShare;
@class GooglePlusSignInButton;
@class GTMOAuth2Authentication;

@interface GooglePlusSampleAppDelegate : UIResponder<UIApplicationDelegate>

// The sample app's |UIWindow|.
@property (retain, nonatomic) UIWindow *window;
// The navigation controller.
@property (retain, nonatomic) UINavigationController *navigationController;
// The Google+ sign-in button to handle the URL redirect.
@property (retain, nonatomic) GooglePlusSignInButton *signInButton;
// The OAuth 2.0 authentication used in the application.
@property (retain, nonatomic) GTMOAuth2Authentication *auth;
// The Google+ share object to handle the URL redirect.
@property (retain, nonatomic) GooglePlusShare *share;

// The OAuth 2.0 client ID to be used for Google+ sign-in, share, and moments.
+ (NSString *)clientID;

@end
