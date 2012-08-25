//
//  GooglePlusSignInViewController.h
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
#import "GooglePlusSignIn.h"

@class GooglePlusSignInButton;

// A view controller for the Google+ sign-in button which initiates a standard
// OAuth 2.0 flow and provides an access token and a refresh token. A "Sign out"
// button is provided to allow users to sign out of this application.
@interface GooglePlusSampleSignInViewController : UIViewController<
    GooglePlusSignInDelegate>

// The button that handles Google+ sign-in.
@property (retain, nonatomic) IBOutlet GooglePlusSignInButton *signInButton;
// A label to display the result of the sign-in action.
@property (retain, nonatomic) IBOutlet UILabel *signInAuthStatus;
// A button to sign out of this application.
@property (retain, nonatomic) IBOutlet UIButton *signOutButton;

// Called when the user presses the "Sign out" button.
- (IBAction)signOut:(id)sender;

@end
