//
//  GooglePlusSampleMomentsViewController.m
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

#import "GooglePlusSampleMomentsViewController.h"

#import <QuartzCore/QuartzCore.h>
#import "GTLPlus.h"
#import "GTLPlusConstants.h"
#import "GTLPlusItemScope.h"
#import "GTLPlusMoment.h"
#import "GTLQueryPlus.h"
#import "GTLServicePlus.h"
#import "GTMLogger.h"
#import "GTMOAuth2Authentication.h"
#import "GooglePlusSampleAppDelegate.h"

@interface GooglePlusSampleMomentsViewController ()
- (GTLPlusItemScope *)resultFor:(NSString *)selectedMoment;
- (void)animateKeyboard:(NSNotification *)notification
             shouldShow:(BOOL)shouldShow;
- (NSString *)momentURLForIndex:(int)i;
- (void)reportAuthStatus;
@end

@implementation GooglePlusSampleMomentsViewController

@synthesize momentsTable = momentsTable_;
@synthesize momentURL = momentURL_;
@synthesize momentStatus = momentStatus_;
@synthesize addButton = addButton_;

// The different kinds of moments.
static const int kNumMomentTypes = 9;
static NSString * const kMomentTypes[kNumMomentTypes] = {
    @"AddActivity",
    @"BuyActivity",
    @"CheckInActivity",
    @"CommentActivity",
    @"CreateActivity",
    @"ListenActivity",
    @"ReserveActivity",
    @"ReviewActivity",
    @"ViewActivity" };
static NSString * const kMomentURLs[kNumMomentTypes] = {
    @"thing",
    @"a-book",
    @"place",
    @"blog-entry",
    @"photo",
    @"song",
    @"restaurant",
    @"widget",
    @"video" };
static NSString * const kMomentURLFormat =
    @"https://developers.google.com/+/plugins/snippet/examples/%@";

#pragma mark - Object lifecycle

- (void)dealloc {
  // Unregister for keyboard notifications while not visible.
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillHideNotification
              object:nil];
  [momentsTable_ release];
  [momentURL_ release];
  [momentStatus_ release];
  [addButton_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  // Set up "Add Moment" button.
  [[addButton_ layer] setCornerRadius:5];
  [[addButton_ layer] setMasksToBounds:YES];
  CGColorRef borderColor = [[UIColor colorWithWhite:203.0/255.0
                                              alpha:1.0] CGColor];
  [[addButton_ layer] setBorderColor:borderColor];
  [[addButton_ layer] setBorderWidth:1.0];

  // Set up sample view of writing moments.
  int selectedRow = [[momentsTable_ indexPathForSelectedRow] row];
  momentURL_.text = [self momentURLForIndex:selectedRow];

  [self reportAuthStatus];
  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // Register for keyboard notifications while visible.
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillShow:)
             name:UIKeyboardWillShowNotification
           object:nil];
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(keyboardWillHide:)
             name:UIKeyboardWillHideNotification
           object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  // Unregister for keyboard notifications while not visible.
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
   removeObserver:self
             name:UIKeyboardWillHideNotification
           object:nil];

  [super viewWillDisappear:animated];
}

#pragma mark - IBActions

- (IBAction)momentButton:(id)sender {
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  if (!appDelegate.auth) {
    // To authenticate, use Google+ sign-in button.
    momentStatus_.text = @"Status: Not authenticated";
    return;
  }

  // Here is an example of writing a moment to Google+ history:
  // 1. Create a |GTLServicePlus| instance to send a request to Google+.
  GTLServicePlus* plusService = [[[GTLServicePlus alloc] init] autorelease];
  plusService.retryEnabled = YES;

  // 2. Set a valid |GTMOAuth2Authentication| object as the authorizer.
  [plusService setAuthorizer:appDelegate.auth];

  // 3. Create a |GTLPlusMoment| object with required fields. For reference, see
  // https://developers.google.com/+/history/ .
  int selectedRow = [[momentsTable_ indexPathForSelectedRow] row];
  NSString *selectedMoment = kMomentTypes[selectedRow];

  GTLPlusMoment *moment = [[[GTLPlusMoment alloc] init] autorelease];
  moment.type = [NSString stringWithFormat:@"https://schemas.google.com/%@",
                                           selectedMoment];
  GTLPlusItemScope *target = [[[GTLPlusItemScope alloc] init] autorelease];
  target.url = momentURL_.text;
  if ([target.url isEqualToString:@""]) {
    target.url = [self momentURLForIndex:selectedRow];
  }
  moment.target = target;

  // CommentActivity, ReserveActivity, and ReviewActivity require setting a
  // |result| field in the request.
  GTLPlusItemScope *result = [self resultFor:selectedMoment];
  if (result) {
    moment.result = result;
  }

  // 4. Create a |GTLQuery| object to write a moment.
  GTLQueryPlus *query =
      [GTLQueryPlus queryForMomentsInsertWithObject:moment
                                             userId:@"me"
                                         collection:kGTLPlusCollectionVault];

  [plusService executeQuery:query
          completionHandler:^(GTLServiceTicket *ticket,
                              id object,
                              NSError *error) {
              if (error) {
                GTMLoggerError(@"Error: %@", error);
                momentStatus_.text =
                    [NSString stringWithFormat:@"Status: Error: %@", error];
              } else {
                momentStatus_.text = [NSString stringWithFormat:
                    @"Status: Saved to Google+ history (%@)",
                    selectedMoment];
              }
          }];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return kNumMomentTypes;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:kCellIdentifier]
        autorelease];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  // Configure the cell.
  cell.textLabel.text = kMomentTypes[indexPath.row];
  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  int selectedRow = [[momentsTable_ indexPathForSelectedRow] row];
  momentURL_.text = [self momentURLForIndex:selectedRow];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - UIKeyboard

- (void)keyboardWillShow:(NSNotification *)notification {
  [self animateKeyboard:notification shouldShow:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
  [self animateKeyboard:notification shouldShow:NO];
}

#pragma mark - Private methods

// Helps set required result field for select moment types.
- (GTLPlusItemScope *)resultFor:(NSString *)selectedMoment {
  GTLPlusItemScope *result = [[[GTLPlusItemScope alloc] init] autorelease];
  if ([selectedMoment isEqualToString:@"CommentActivity"]) {
    result.type = @"http://schema.org/Comment";
    result.url =
    @"https://developers.google.com/+/plugins/snippet/examples/blog-entry#comment-1";
    result.name = @"This is amazing!";
    result.text = @"I can't wait to use it on my site :)";
    return result;
  } else if ([selectedMoment isEqualToString:@"ReserveActivity"]) {
    result.type = @"http://schema.org/Reservation";
    result.startDate = @"2012-06-28T19:00:00-08:00";
    result.attendeeCount = [[[NSNumber alloc] initWithInt:3] autorelease];
    return result;
  } else if ([selectedMoment isEqualToString:@"ReviewActivity"]) {
    result.type = @"http://schema.org/Review";
    result.name = @"A Humble Review of Widget";
    result.url =
    @"https://developers.google.com/+/plugins/snippet/examples/review";
    result.text =
    @"It's amazingly effective at whatever it is that it's supposed to do.";
    GTLPlusItemScope *rating = [[[GTLPlusItemScope alloc] init] autorelease];
    rating.type = @"http://schema.org/Rating";
    rating.ratingValue = @"100";
    rating.bestRating = @"100";
    rating.worstRating = @"0";
    result.reviewRating =
    [[[NSArray alloc] initWithObjects:rating, nil] autorelease];
    return result;
  }
  return nil;
}

// Helps animate keyboard for target URL text field.
- (void)animateKeyboard:(NSNotification *)notification
             shouldShow:(BOOL)shouldShow {
  NSDictionary *userInfo = [notification userInfo];
  CGFloat height = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]
      CGRectValue].size.height;
  CGFloat duration = [[userInfo
      objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
  [UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:duration];
  CGRect newFrame = self.view.frame;
  if (shouldShow) {
    newFrame.size.height -= height;
  } else {
    newFrame.size.height += height;
  }
  self.view.frame = newFrame;
  [UIView commitAnimations];
  if (shouldShow) {
    keyboardVisible_ = YES;
  } else {
    keyboardVisible_ = NO;
  }
}

- (NSString *)momentURLForIndex:(int)i {
  return [NSString stringWithFormat:kMomentURLFormat, kMomentURLs[i]];
}

- (void)reportAuthStatus {
  NSString *authStatus = @"";
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];

  if (appDelegate.auth) {
    authStatus = @"Status: Authenticated";
  } else {
    // To authenticate, use Google+ sign-in button.
    authStatus = @"Status: Not authenticated";
  }

  momentStatus_.text = authStatus;
}

@end
