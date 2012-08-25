//
//  GooglePlusSampleMasterViewController.m
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

#import "GooglePlusSampleMasterViewController.h"

#import "GooglePlusSampleShareViewController.h"
#import "GooglePlusSampleSignInViewController.h"
#import "GooglePlusSampleMomentsViewController.h"

static const int kNumViewControllers = 3;
static NSString * const kMenuOptions[kNumViewControllers] = {
    @"Sign In", @"Share", @"Moments" };
static NSString * const kNibNames[kNumViewControllers] = {
    @"GooglePlusSampleSignInViewController",
    @"GooglePlusSampleShareViewController",
    @"GooglePlusSampleMomentsViewController" };

@implementation GooglePlusSampleMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"Google+ SDK Sample";
    UIBarButtonItem *backButton = [[[UIBarButtonItem alloc]
        initWithTitle:@"Back"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(backPressed)] autorelease];
    self.navigationItem.backBarButtonItem = backButton;
  }
  return self;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)
    interfaceOrientation {
  if ([[UIDevice currentDevice] userInterfaceIdiom] ==
      UIUserInterfaceIdiomPhone) {
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
  return YES;
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return kNumViewControllers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell =
        [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:kCellIdentifier] autorelease];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }

  cell.textLabel.text = kMenuOptions[indexPath.row];
  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  Class nibClass = NSClassFromString(kNibNames[indexPath.row]);
  UIViewController *controller =
      [[[nibClass alloc] initWithNibName:nil bundle:nil] autorelease];
  controller.navigationItem.title = kMenuOptions[indexPath.row];

  [self.navigationController pushViewController:controller animated:YES];
}

@end
