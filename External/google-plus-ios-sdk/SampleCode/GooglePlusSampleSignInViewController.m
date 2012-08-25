//
//  GooglePlusSignInViewController.m
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
#import "GooglePlusSignIn.h"
#import "GooglePlusSignInButton.h"

@implementation GooglePlusSampleSignInViewController

@synthesize signInButton = signInButton_;
@synthesize signInAuthStatus = signInAuthStatus_;
@synthesize signOutButton = signOutButton_;

- (void)dealloc {
  [signInButton_ release];
  [signInAuthStatus_ release];
  [signOutButton_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)reportAuthStatus {
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  if (appDelegate.auth) {
    signInAuthStatus_.text = @"Status: Authenticated";
  } else {
    // To authenticate, use Google+ sign-in button.
    signInAuthStatus_.text = @"Status: Not authenticated";
  }
}

- (void)viewDidLoad {
  // Set up sign-out button.
  [[signOutButton_ layer] setCornerRadius:5];
  [[signOutButton_ layer] setMasksToBounds:YES];
  CGColorRef borderColor = [[UIColor colorWithWhite:203.0/255.0
                                              alpha:1.0] CGColor];
  [[signOutButton_ layer] setBorderColor:borderColor];
  [[signOutButton_ layer] setBorderWidth:1.0];

  // Set up sample view of Google+ sign-in.
  signInButton_.delegate = self;
  signInButton_.clientID = [GooglePlusSampleAppDelegate clientID];
  signInButton_.scope = [NSArray arrayWithObjects:
      @"https://www.googleapis.com/auth/plus.moments.write",
      @"https://www.googleapis.com/auth/plus.me",
      nil];

  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  appDelegate.signInButton = signInButton_;
  [self reportAuthStatus];
  [super viewDidLoad];
}

- (void)viewDidUnload {
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  appDelegate.signInButton = nil;
  [super viewDidUnload];
}

#pragma mark - GooglePlusSignInDelegate

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error {
  if (error) {
    signInAuthStatus_.text =
        [NSString stringWithFormat:@"Status: Authentication error: %@", error];
    return;
  }
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  appDelegate.auth = auth;
  [self reportAuthStatus];
}

#pragma mark - IBActions

- (IBAction)signOut:(id)sender {
  [[signInButton_ googlePlusSignIn] signOut];

  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  appDelegate.auth = nil;

  [self reportAuthStatus];
}

@end
