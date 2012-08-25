//
//  GooglePlusSampleShareViewController.m
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

#import "GooglePlusSampleShareViewController.h"

#import "GooglePlusSampleAppDelegate.h"

@implementation GooglePlusSampleShareViewController

@synthesize sharePrefillText = sharePrefillText_;
@synthesize shareURL = shareURL_;
@synthesize shareStatus = shareStatus_;
@synthesize shareToolbar = shareToolbar_;

- (void)dealloc {
  [sharePrefillText_ release];
  [shareURL_ release];
  [shareStatus_ release];
  [share_ release];
  [shareToolbar_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  // Set up Google+ share dialog.
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  NSString *clientID = [GooglePlusSampleAppDelegate clientID];
  share_ = [[GooglePlusShare alloc] initWithClientID:clientID];
  share_.delegate = self;
  appDelegate.share = share_;

  [super viewDidLoad];
}

- (void)viewDidUnload {
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  appDelegate.share = nil;
  share_.delegate = nil;
  [share_ release];
  share_ = nil;

  [super viewDidUnload];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - GooglePlusShareDelegate

- (void)finishedSharing:(BOOL)shared {
  NSString *text = shared ? @"Success" : @"Canceled";
  shareStatus_.text = [NSString stringWithFormat:@"Status: %@", text];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet
    didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    [self shareButton:nil];
  } else if (buttonIndex == 1) {
    shareStatus_.text = @"Status: Sharing...";
    MFMailComposeViewController *picker =
        [[[MFMailComposeViewController alloc] init] autorelease];
    picker.mailComposeDelegate = self;
    [picker setSubject:sharePrefillText_.text];
    [picker setMessageBody:shareURL_.text isHTML:NO];

    [self presentModalViewController:picker animated:YES];
  }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error {
  NSString *text;
  switch (result) {
    case MFMailComposeResultCancelled:
      text = @"Canceled";
      break;
    case MFMailComposeResultSaved:
      text = @"Saved";
      break;
    case MFMailComposeResultSent:
      text = @"Sent";
      break;
    case MFMailComposeResultFailed:
      text = @"Failed";
      break;
    default:
      text = @"Not sent";
      break;
  }
  shareStatus_.text = [NSString stringWithFormat:@"Status: %@", text];
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - IBActions

- (IBAction)shareButton:(id)sender {
  NSString *inputURL = shareURL_.text;
  NSURL *urlToShare = [inputURL length] ? [NSURL URLWithString:inputURL] : nil;
  NSString *inputText = sharePrefillText_.text;
  NSString *text = [inputText length] ? inputText : nil;
  shareStatus_.text = @"Status: Sharing...";
  [[[[share_ shareDialog] setURLToShare:urlToShare] setPrefillText:text] open];
}

- (IBAction)shareToolbar:(id)sender {
  UIActionSheet *actionSheet =
      [[[UIActionSheet alloc] initWithTitle:@"Share this post"
                                   delegate:self
                          cancelButtonTitle:@"Cancel"
                     destructiveButtonTitle:nil
                          otherButtonTitles:@"Google+", @"Email", nil]
          autorelease];
  [actionSheet showFromToolbar:shareToolbar_];
}

@end
