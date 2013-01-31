//
//  GooglePlusSampleShareViewController.h
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

#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MessageUI.h>
#import <UIKit/UIKit.h>
#import "GPPShare.h"

// A view controller for the Google+ share dialog which contains a text field
// to prefill the user comment, and a text field for an optional URL to share.
// A Google+ share button is provided to launch the share dialog.
@interface GooglePlusSampleShareViewController : UIViewController<
    GPPShareDelegate,
    UITextFieldDelegate,
    UIActionSheetDelegate,
    MFMailComposeViewControllerDelegate> {
  // The Google+ share object to manage the share dialog.
  GPPShare *share_;
  // Whether the keyboard is visible or not.
  BOOL keyboardVisible_;
  // The text field being edited.
  UITextField *activeField_;
}

// The text to prefill the user comment in the share dialog.
@property (retain, nonatomic) IBOutlet UITextField *sharePrefillText;
// The URL resource to share in the share dialog.
@property (retain, nonatomic) IBOutlet UITextField *shareURL;
// A label to display the result of the share action.
@property (retain, nonatomic) IBOutlet UILabel *shareStatus;
// A toolbar to share via Google+ or email.
@property (retain, nonatomic) IBOutlet UIToolbar *shareToolbar;
// A switch to toggle Google+ share with deep linking.
@property (retain, nonatomic) IBOutlet UISwitch *attachDeepLinkSwitch;
// The deep-link ID to be attached with the Google+ share to qualify as
// a deep-link share.
@property (retain, nonatomic) IBOutlet UITextField *deepLinkID;
// The share's title.
@property (retain, nonatomic) IBOutlet UITextField *deepLinkTitle;
// The share's description.
@property (retain, nonatomic) IBOutlet UITextField *deepLinkDescription;
// The share's thumbnail URL.
@property (retain, nonatomic) IBOutlet UITextField *deepLinkThumbnailURL;
// The share view.
@property (retain, nonatomic) IBOutlet UIScrollView *shareScrollView;
@property (retain, nonatomic) IBOutlet UIView *shareView;
// Labels for Google+ share sample.
@property (retain, nonatomic) IBOutlet UILabel *attachDeepLinkDataLabel;
@property (retain, nonatomic) IBOutlet UILabel *urlToShareLabel;
@property (retain, nonatomic) IBOutlet UILabel *prefillTextLabel;
@property (retain, nonatomic) IBOutlet UILabel *deepLinkIDLabel;
@property (retain, nonatomic) IBOutlet UILabel *deepLinkTitleLabel;
@property (retain, nonatomic) IBOutlet UILabel *deepLinkDescriptionLabel;
@property (retain, nonatomic) IBOutlet UILabel *deepLinkThumbnailURLLabel;
@property (retain, nonatomic) IBOutlet UIButton *shareButton;
@property (retain, nonatomic) IBOutlet UISwitch *urlForDeepLinkMetadataSwitch;
@property (retain, nonatomic) IBOutlet UILabel *urlForDeepLinkMetadataLabel;

// Called when the switch for deep-link data is toggled.
- (IBAction)deepLinkSwitchToggle:(id)sender;
// Called when the switch for metadata from URL preview is toggled.
- (IBAction)urlForDeepLinkMetadataSwitchToggle:(id)sender;
// Called when the share button is pressed.
- (IBAction)shareButton:(id)sender;
// Called when the toolbar share button is pressed.
- (IBAction)shareToolbar:(id)sender;

@end
