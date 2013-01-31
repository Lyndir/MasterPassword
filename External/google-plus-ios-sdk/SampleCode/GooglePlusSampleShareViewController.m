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

@interface GooglePlusSampleShareViewController()
- (void)animateKeyboard:(NSNotification *)notification
             shouldShow:(BOOL)shouldShow;
- (void)layout;
- (void)placeView:(UIView *)view x:(CGFloat)x y:(CGFloat)y;
- (void)populateTextFields;
@end

@implementation GooglePlusSampleShareViewController

@synthesize attachDeepLinkSwitch = attachDeepLinkSwitch_;
@synthesize deepLinkDescription = deepLinkDescription_;
@synthesize deepLinkID = deepLinkID_;
@synthesize deepLinkTitle = deepLinkTitle_;
@synthesize deepLinkThumbnailURL = deepLinkThumbnailURL_;
@synthesize sharePrefillText = sharePrefillText_;
@synthesize shareURL = shareURL_;
@synthesize shareStatus = shareStatus_;
@synthesize shareToolbar = shareToolbar_;
@synthesize shareScrollView = shareScrollView_;
@synthesize shareView = shareView_;
@synthesize attachDeepLinkDataLabel = attachDeepLinkDataLabel_;
@synthesize urlToShareLabel = urlToShareLabel_;
@synthesize prefillTextLabel = prefillTextLabel_;
@synthesize deepLinkIDLabel = deepLinkIDLabel_;
@synthesize deepLinkTitleLabel = deepLinkTitleLabel_;
@synthesize deepLinkDescriptionLabel = deepLinkDescriptionLabel_;
@synthesize deepLinkThumbnailURLLabel = deepLinkThumbnailURLLabel_;
@synthesize shareButton = shareButton_;
@synthesize urlForDeepLinkMetadataSwitch = urlForDeepLinkMetadataSwitch_;
@synthesize urlForDeepLinkMetadataLabel = urlForDeepLinkMetadataLabel_;

- (void)dealloc {
  [attachDeepLinkSwitch_ release];
  [deepLinkID_ release];
  [deepLinkTitle_ release];
  [deepLinkDescription_ release];
  [deepLinkThumbnailURL_ release];
  [sharePrefillText_ release];
  [shareURL_ release];
  [shareStatus_ release];
  [share_ release];
  [shareToolbar_ release];
  [shareScrollView_ release];
  [shareView_ release];
  [attachDeepLinkDataLabel_ release];
  [urlToShareLabel_ release];
  [prefillTextLabel_ release];
  [deepLinkIDLabel_ release];
  [deepLinkTitleLabel_ release];
  [deepLinkDescriptionLabel_ release];
  [deepLinkThumbnailURLLabel_ release];
  [shareButton_ release];
  [urlForDeepLinkMetadataSwitch_ release];
  [urlForDeepLinkMetadataLabel_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  // Set up Google+ share dialog.
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  NSString *clientID = [GooglePlusSampleAppDelegate clientID];
  share_ = [[GPPShare alloc] initWithClientID:clientID];
  share_.delegate = self;
  appDelegate.share = share_;

  [attachDeepLinkSwitch_ setOn:NO];

  [self layout];
  [self populateTextFields];
  [super viewDidLoad];
}

- (void)viewDidUnload {
  GooglePlusSampleAppDelegate *appDelegate = (GooglePlusSampleAppDelegate *)
      [[UIApplication sharedApplication] delegate];
  appDelegate.share = nil;
  share_.delegate = nil;
  [share_ release];
  share_ = nil;
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillShowNotification
              object:nil];
  [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:UIKeyboardWillHideNotification
              object:nil];

  [self setAttachDeepLinkSwitch:nil];
  [self setDeepLinkID:nil];
  [self setDeepLinkTitle:nil];
  [self setDeepLinkDescription:nil];
  [self setDeepLinkThumbnailURL:nil];
  [self setShareScrollView:nil];
  [self setShareView:nil];
  [self setShareToolbar:nil];
  [self setAttachDeepLinkDataLabel:nil];
  [self setUrlToShareLabel:nil];
  [self setPrefillTextLabel:nil];
  [self setDeepLinkIDLabel:nil];
  [self setDeepLinkTitleLabel:nil];
  [self setDeepLinkDescriptionLabel:nil];
  [self setDeepLinkThumbnailURLLabel:nil];
  [self setShareButton:nil];
  [self setUrlForDeepLinkMetadataSwitch:nil];
  [self setUrlForDeepLinkMetadataLabel:nil];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
    shareScrollView_.frame = self.view.frame;
  }
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  activeField_ = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  activeField_ = nil;
}

#pragma mark - GPPShareDelegate

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

#pragma mark - UIKeyboard

- (void)keyboardWillShow:(NSNotification *)notification {
  [self animateKeyboard:notification shouldShow:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
  [self animateKeyboard:notification shouldShow:NO];
}

#pragma mark - IBActions

- (IBAction)shareButton:(id)sender {
  shareStatus_.text = @"Status: Sharing...";
  id<GPPShareBuilder> shareBuilder = [share_ shareDialog];

  NSString *inputURL = shareURL_.text;
  NSURL *urlToShare = [inputURL length] ? [NSURL URLWithString:inputURL] : nil;
  if (urlToShare) {
    shareBuilder = [shareBuilder setURLToShare:urlToShare];
  }

  if ([deepLinkID_ text]) {
    shareBuilder = [shareBuilder setContentDeepLinkID:[deepLinkID_ text]];
    NSString *title = [deepLinkTitle_ text];
    NSString *description = [deepLinkDescription_ text];
    if (title && description) {
      NSURL *thumbnailURL = [NSURL URLWithString:[deepLinkThumbnailURL_ text]];
      shareBuilder = [shareBuilder setTitle:title
                                description:description
                               thumbnailURL:thumbnailURL];
    }
  }

  NSString *inputText = sharePrefillText_.text;
  NSString *text = [inputText length] ? inputText : nil;
  if (text) {
    shareBuilder = [shareBuilder setPrefillText:text];
  }

  if (![shareBuilder open]) {
    shareStatus_.text = @"Status: Error (see console).";
  }
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

- (IBAction)urlForDeepLinkMetadataSwitchToggle:(id)sender {
  [self layout];
  [self populateTextFields];
}

- (IBAction)deepLinkSwitchToggle:(id)sender {
  if (!attachDeepLinkSwitch_.on) {
    [urlForDeepLinkMetadataSwitch_ setOn:YES];
  }
  [self layout];
  [self populateTextFields];
}

#pragma mark - helper methods

- (void) placeView:(UIView *)view x:(CGFloat)x y:(CGFloat)y {
  CGSize frameSize = view.frame.size;
  view.frame = CGRectMake(x, y, frameSize.width, frameSize.height);
}

- (void) layout {
  CGFloat originX = 20.0;
  CGFloat originY = 20.0;
  CGFloat yPadding = 20.0;
  CGFloat currentY = originY;
  CGFloat middleX = 150;

  // Place the switch for attaching deep-link data.
  [self placeView:attachDeepLinkDataLabel_ x:originX y:currentY];
  [self placeView:attachDeepLinkSwitch_ x:middleX + 50 y:currentY];
  CGSize frameSize = attachDeepLinkSwitch_.frame.size;
  currentY += frameSize.height + yPadding;

  // Place the switch for preview URL.
  if (attachDeepLinkSwitch_.on) {
    [self placeView:urlForDeepLinkMetadataLabel_ x:originX y:currentY];
    [self placeView:urlForDeepLinkMetadataSwitch_ x:middleX + 50 y:currentY];
    frameSize = urlForDeepLinkMetadataSwitch_.frame.size;
    currentY += frameSize.height + yPadding;
    urlForDeepLinkMetadataSwitch_.hidden = NO;
    urlForDeepLinkMetadataLabel_.hidden = NO;
  } else {
    urlForDeepLinkMetadataSwitch_.hidden = YES;
    urlForDeepLinkMetadataLabel_.hidden = YES;
  }

  // Place the field for URL to share.
  if (urlForDeepLinkMetadataSwitch_.on) {
    [self placeView:urlToShareLabel_ x:originX y:currentY];
    frameSize = urlToShareLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;

    [self placeView:shareURL_ x:originX y:currentY];
    frameSize = shareURL_.frame.size;
    currentY += frameSize.height + yPadding;
    urlToShareLabel_.hidden = NO;
    shareURL_.hidden = NO;
  } else {
    urlToShareLabel_.hidden = YES;
    shareURL_.hidden = YES;
  }

  // Place the field for prefill text.
  [self placeView:prefillTextLabel_ x:originX y:currentY];
  frameSize = prefillTextLabel_.frame.size;
  currentY += frameSize.height + 0.5 * yPadding;
  [self placeView:sharePrefillText_ x:originX y:currentY];
  frameSize = sharePrefillText_.frame.size;
  currentY += frameSize.height + yPadding;

  // Place the content deep-link ID field.
  if (attachDeepLinkSwitch_.on) {
    [self placeView:deepLinkIDLabel_ x:originX y:currentY];
    frameSize = deepLinkIDLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:deepLinkID_ x:originX y:currentY];
    frameSize = deepLinkID_.frame.size;
    currentY += frameSize.height + yPadding;
    deepLinkIDLabel_.hidden = NO;
    deepLinkID_.hidden = NO;
  } else {
    deepLinkIDLabel_.hidden = YES;
    deepLinkID_.hidden = YES;
  }

  // Place fields for content deep-link metadata.
  if (attachDeepLinkSwitch_.on && !urlForDeepLinkMetadataSwitch_.on) {
    [self placeView:deepLinkTitleLabel_ x:originX y:currentY];
    frameSize = deepLinkTitleLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:deepLinkTitle_ x:originX y:currentY];
    frameSize = deepLinkTitle_.frame.size;
    currentY += frameSize.height + yPadding;

    [self placeView:deepLinkDescriptionLabel_ x:originX y:currentY];
    frameSize = deepLinkDescriptionLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:deepLinkDescription_ x:originX y:currentY];
    frameSize = deepLinkDescription_.frame.size;
    currentY += frameSize.height + yPadding;

    [self placeView:deepLinkThumbnailURLLabel_ x:originX y:currentY];
    frameSize = deepLinkThumbnailURLLabel_.frame.size;
    currentY += frameSize.height + 0.5 * yPadding;
    [self placeView:deepLinkThumbnailURL_ x:originX y:currentY];
    frameSize = deepLinkThumbnailURL_.frame.size;
    currentY += frameSize.height + yPadding;

    deepLinkTitle_.hidden = NO;
    deepLinkTitleLabel_.hidden = NO;
    deepLinkDescriptionLabel_.hidden = NO;
    deepLinkDescription_.hidden = NO;
    deepLinkThumbnailURLLabel_.hidden = NO;
    deepLinkThumbnailURL_.hidden = NO;
  } else {
    deepLinkTitle_.hidden = YES;
    deepLinkTitleLabel_.hidden = YES;
    deepLinkDescriptionLabel_.hidden = YES;
    deepLinkDescription_.hidden = YES;
    deepLinkThumbnailURLLabel_.hidden = YES;
    deepLinkThumbnailURL_.hidden = YES;
  }

  // Place the share button and status.
  [self placeView:shareButton_ x:originX y:currentY];
  frameSize = shareButton_.frame.size;
  currentY += frameSize.height + yPadding;

  [self placeView:shareStatus_ x:originX y:currentY];
  frameSize = shareStatus_.frame.size;
  currentY += frameSize.height + yPadding;

  shareScrollView_.contentSize =
      CGSizeMake(shareScrollView_.frame.size.width, currentY);
}

- (void)populateTextFields {
  // Pre-populate text fields for Google+ share sample.
  if (sharePrefillText_.hidden) {
    sharePrefillText_.text = @"";
  } else {
    sharePrefillText_.text = @"Welcome to Google+ Platform";
  }

  if (shareURL_.hidden) {
    shareURL_.text = @"";
  } else {
    shareURL_.text = @"http://developers.google.com";
  }

  if (deepLinkID_.hidden) {
    deepLinkID_.text = @"";
  } else {
    deepLinkID_.text = @"reviews/314159265358";
  }

  if (deepLinkTitle_.hidden) {
    deepLinkTitle_.text = @"";
  } else {
    deepLinkTitle_.text = @"Joe's Diner Review";
  }

  if (deepLinkDescription_.hidden) {
    deepLinkDescription_.text = @"";
  } else {
    deepLinkDescription_.text = @"Check out my review of the awesome toast!";
  }

  if (deepLinkThumbnailURL_.hidden) {
    deepLinkThumbnailURL_.text = @"";
  } else {
    deepLinkThumbnailURL_.text =
        @"http://www.google.com/logos/2012/childrensday-2012-hp.jpg";
  }
}

- (void)animateKeyboard:(NSNotification *)notification
             shouldShow:(BOOL)shouldShow {
  if (!shouldShow) {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    shareScrollView_.contentInset = contentInsets;
    shareScrollView_.scrollIndicatorInsets = contentInsets;
    return;
  }

  NSDictionary *userInfo = [notification userInfo];
  CGRect kbFrame =
      [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
  CGSize kbSize = kbFrame.size;
  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
  shareScrollView_.contentInset = contentInsets;
  shareScrollView_.scrollIndicatorInsets = contentInsets;

  // If active text field is hidden by keyboard, scroll so it's visible.
  CGRect aRect = self.view.frame;
  aRect.size.height -= kbSize.height;
  CGPoint bottomLeft =
      CGPointMake(0.0, activeField_.frame.origin.y +
          activeField_.frame.size.height + 10);
  if (!CGRectContainsPoint(aRect, bottomLeft)) {
    CGPoint scrollPoint = CGPointMake(0.0, bottomLeft.y - aRect.size.height);
    [shareScrollView_ setContentOffset:scrollPoint animated:YES];
  }
  return;
}

@end
