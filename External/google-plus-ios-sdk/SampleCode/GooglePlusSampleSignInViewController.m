//
//  GooglePlusSampleSignInViewController.m
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

#import "GooglePlusSampleSignInViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "GooglePlusSampleAppDelegate.h"
#import "GPPSignIn.h"
#import "GPPSignInButton.h"
#import "GTLPlus.h"
#import "GTLPlusConstants.h"
#import "GTLQueryPlus.h"
#import "GTLServicePlus.h"
#import "GTMLogger.h"
#import "GTMOAuth2Authentication.h"

@interface GooglePlusSampleSignInViewController () {
  // Saved state of |userinfoEmailScope_.on|.
  BOOL savedUserinfoEmailScopeState_;
}
- (GooglePlusSampleAppDelegate *)appDelegate;
- (void)setSignInScopes;
- (void)enableSignInSettings:(BOOL)enable;
- (void)reportAuthStatus;
- (void)retrieveUserInfo;
@end

@implementation GooglePlusSampleSignInViewController

@synthesize signInButton = signInButton_;
@synthesize signInAuthStatus = signInAuthStatus_;
@synthesize signInDisplayName = signInDisplayName_;
@synthesize signOutButton = signOutButton_;
@synthesize plusMomentsWriteScope = plusMomentsWriteScope_;
@synthesize userinfoEmailScope = userinfoEmailScope_;

- (void)dealloc {
  [signInButton_ release];
  [signInAuthStatus_ release];
  [signInDisplayName_ release];
  [signOutButton_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  plusMomentsWriteScope_.on = appDelegate.plusMomentsWriteScope;
  userinfoEmailScope_.on = savedUserinfoEmailScopeState_;

  // Set up sign-out button.
  [[signOutButton_ layer] setCornerRadius:5];
  [[signOutButton_ layer] setMasksToBounds:YES];
  CGColorRef borderColor = [[UIColor colorWithWhite:203.0/255.0
                                              alpha:1.0] CGColor];
  [[signOutButton_ layer] setBorderColor:borderColor];
  [[signOutButton_ layer] setBorderWidth:1.0];

  // Set up sample view of Google+ sign-in.
  signInButton_.delegate = self;
  signInButton_.shouldFetchGoogleUserEmail = userinfoEmailScope_.on;
  signInButton_.clientID = [GooglePlusSampleAppDelegate clientID];
  [self setSignInScopes];

  appDelegate.signInButton = signInButton_;
  [self reportAuthStatus];
  [super viewDidLoad];
}

- (void)viewWillDisappear:(BOOL)animated {
  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  appDelegate.plusMomentsWriteScope = plusMomentsWriteScope_.on;
  savedUserinfoEmailScopeState_ = userinfoEmailScope_.on;
}

- (void)viewDidUnload {
  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  appDelegate.signInButton = nil;
  [super viewDidUnload];
}

#pragma mark - GPPSignInDelegate

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  if (error) {
    signInAuthStatus_.text =
        [NSString stringWithFormat:@"Status: Authentication error: %@", error];
    return;
  }
  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  appDelegate.auth = auth;
  [self reportAuthStatus];
}

#pragma mark - Helper methods

- (GooglePlusSampleAppDelegate *)appDelegate {
  return (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
}

- (void)setSignInScopes {
  signInButton_.scope = plusMomentsWriteScope_.on ?
      [NSArray arrayWithObjects:
           @"https://www.googleapis.com/auth/plus.moments.write",
           @"https://www.googleapis.com/auth/plus.me",
           nil] :
      [NSArray arrayWithObjects:
           @"https://www.googleapis.com/auth/plus.me",
           nil];
}

- (void)enableSignInSettings:(BOOL)enable {
  plusMomentsWriteScope_.enabled = enable;
  userinfoEmailScope_.enabled = enable && !plusMomentsWriteScope_.on;
}

- (void)reportAuthStatus {
  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  if (appDelegate.auth) {
    signInAuthStatus_.text = @"Status: Authenticated";
    [self retrieveUserInfo];
    [self enableSignInSettings:NO];
  } else {
    // To authenticate, use Google+ sign-in button.
    signInAuthStatus_.text = @"Status: Not authenticated";
    [self enableSignInSettings:YES];
  }
}

- (void)retrieveUserInfo {
  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  if (appDelegate.auth.userEmail) {
    signInDisplayName_.text = appDelegate.auth.userEmail;
  } else {
    signInDisplayName_.text = @"";
  }
}

#pragma mark - IBActions

- (IBAction)signOut:(id)sender {
  [[signInButton_ googlePlusSignIn] signOut];

  GooglePlusSampleAppDelegate *appDelegate = [self appDelegate];
  appDelegate.auth = nil;

  [self reportAuthStatus];
  signInDisplayName_.text = @"";
}

- (IBAction)plusMomentsWriteScopeToggle:(id)sender {
  [self setSignInScopes];
  userinfoEmailScope_.enabled = !plusMomentsWriteScope_.on;
  if (plusMomentsWriteScope_.on) {
    userinfoEmailScope_.on = NO;
  }
}

- (IBAction)userinfoEmailScopeToggle:(id)sender {
  signInButton_.shouldFetchGoogleUserEmail = userinfoEmailScope_.on;
}

@end
