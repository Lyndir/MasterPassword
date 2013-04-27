//
//  GooglePlusSampleListMomentsViewController.m
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

#import "GooglePlusSampleListMomentsViewController.h"

#import "GPPSignIn.h"
#import "GTLPlus.h"
#import "GTMLogger.h"
#import "GTMOAuth2Authentication.h"

@interface GooglePlusSampleListMomentsViewController ()
- (void)clearSelectedMoment;
- (void)refreshData;
- (NSString *)textForMoment:(GTLPlusMoment *)moment;
@end

#pragma mark - View lifecycle

@implementation GooglePlusSampleListMomentsViewController

@synthesize momentsTable = momentsTable_;
@synthesize momentStatus = momentStatus_;
@synthesize momentTarget = momentTarget_;
@synthesize momentTime = momentTime_;
@synthesize momentRemoval = momentsRemoval_;

#pragma mark - Object lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    verbMap_ = [[NSDictionary dictionaryWithObjectsAndKeys:
        @"Added", @"http://schemas.google.com/AddActivity",
        @"Bought", @"http://schemas.google.com/BuyActivity",
        @"Checked in", @"http://schemas.google.com/CheckInActivity",
        @"Commented on", @"http://schemas.google.com/CommentActivity",
        @"Created", @"http://schemas.google.com/CreateActivity",
        @"Listened to", @"http://schemas.google.com/ListenActivity",
        @"Made a reservation at", @"http://schemas.google.com/ReserveActivity",
        @"Reviewed", @"http://schemas.google.com/ReviewActivity",
        nil] retain];
  }
  return self;
}

- (void)dealloc {
  [verbMap_ release];
  [momentsData_ release];
  [selectedMoment_ release];
  [momentsTable_ release];
  [momentStatus_ release];
  [momentTarget_ release];
  [momentTime_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  [self refreshData];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return momentsData_.count;
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
  GTLPlusMoment *moment = momentsData_[indexPath.row];
  cell.textLabel.text = [self textForMoment:moment];
  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  GTLPlusMoment *moment = momentsData_[indexPath.row];
  [selectedMoment_ autorelease];
  selectedMoment_ = [moment retain];
  momentStatus_.text = [NSString stringWithFormat:@"Target for \"%@\":",
      [self textForMoment:moment]];
  momentTarget_.text = moment.target.url;
  momentTime_.text = [NSString stringWithFormat:@"Start time: %@",
      [NSDateFormatter localizedStringFromDate:moment.startDate.date
                                     dateStyle:kCFDateFormatterMediumStyle
                                     timeStyle:kCFDateFormatterMediumStyle]];
  momentsRemoval_.hidden = NO;
}

- (void)tableView:(UITableView *)tableView
    didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self clearSelectedMoment];
}

#pragma mark - IBActions

- (IBAction)removeMoment:(id)sender {
  if (!selectedMoment_) {
    return;
  }

  // Here is an example of removing a moment from Google+:
  // 1. Create a |GTLServicePlus| instance to send a request to Google+.
  GTLServicePlus* plusService = [[[GTLServicePlus alloc] init] autorelease];
  plusService.retryEnabled = YES;

  // 2. Set a valid |GTMOAuth2Authentication| object as the authorizer.
  GTMOAuth2Authentication *auth = [GPPSignIn sharedInstance].authentication;
  [plusService setAuthorizer:auth];

  // 3. Create a |GTLQuery| object to remove the moment.
  GTLQueryPlus *query = [GTLQueryPlus
      queryForMomentsRemoveWithIdentifier:selectedMoment_.identifier];
  [plusService executeQuery:query
          completionHandler:^(GTLServiceTicket *ticket,
                              id object,
                              NSError *error) {
              if (error) {
                momentStatus_.text =
                    [NSString stringWithFormat:@"Error: %@", error];
                GTMLoggerError(@"Status: Error: %@", error);
              } else {
                [momentsData_ removeObject:selectedMoment_];
                [self clearSelectedMoment];
                [momentsTable_ reloadData];
              }
          }];
}

#pragma mark - Helper methods

- (void)clearSelectedMoment {
  [selectedMoment_ autorelease];
  selectedMoment_ = nil;
  momentStatus_.text = @"";
  momentTarget_.text = @"";
  momentTime_.text = @"";
  momentsRemoval_.hidden = YES;
}

- (void)refreshData {
  GTMOAuth2Authentication *auth = [GPPSignIn sharedInstance].authentication;
  if (!auth) {
    // To authenticate, use Google+ sign-in button.
    momentStatus_.text = @"Status: Not authenticated";
    return;
  }
  // Clear old moments data.
  [momentsData_ autorelease];
  momentsData_ = nil;
  [momentsTable_ reloadData];
  [self clearSelectedMoment];
  momentStatus_.text = @"Status: Loading";

  // Here is an example of reading list of moments from Google+:
  // 1. Create a |GTLServicePlus| instance to send a request to Google+.
  GTLServicePlus* plusService = [[[GTLServicePlus alloc] init] autorelease];
  plusService.retryEnabled = YES;

  // 2. Set a valid |GTMOAuth2Authentication| object as the authorizer.
  [plusService setAuthorizer:auth];

  // 3. Create a |GTLQuery| object to list moments.
  GTLQueryPlus *query =
      [GTLQueryPlus queryForMomentsListWithUserId:@"me"
                                       collection:kGTLPlusCollectionVault];
  [plusService executeQuery:query
          completionHandler:^(GTLServiceTicket *ticket,
                              id object,
                              NSError *error) {
              if (error) {
                momentStatus_.text =
                    [NSString stringWithFormat:@"Error: %@", error];
                GTMLoggerError(@"Status: Error: %@", error);
              } else {
                GTLPlusMomentsFeed *moments = (GTLPlusMomentsFeed *)object;
                momentsData_ =
                    [[NSMutableArray arrayWithArray:moments.items] retain];
                momentStatus_.text = [NSString stringWithFormat:
                    @"Status: Loaded %d moment(s)", momentsData_.count];
                [momentsTable_ reloadData];
              }
          }];
}

- (NSString *)textForMoment:(GTLPlusMoment *)moment {
  NSString *verb = [verbMap_ objectForKey:moment.type];
  if (!verb) {
    // Fallback for verbs we don't recognize.
    verb = [moment.type lastPathComponent];
  }
  return [NSString stringWithFormat:@"%@ %@", verb, moment.target.name];
}

@end
