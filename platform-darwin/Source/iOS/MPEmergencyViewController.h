//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

@interface MPEmergencyViewController : UIViewController<UITextFieldDelegate>

@property(weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property(weak, nonatomic) IBOutlet UIView *dialogView;
@property(weak, nonatomic) IBOutlet UIView *containerView;
@property(weak, nonatomic) IBOutlet UITextField *fullNameField;
@property(weak, nonatomic) IBOutlet UITextField *masterPasswordField;
@property(weak, nonatomic) IBOutlet UITextField *siteField;
@property(weak, nonatomic) IBOutlet UIStepper *counterStepper;
@property(weak, nonatomic) IBOutlet UISegmentedControl *typeControl;
@property(weak, nonatomic) IBOutlet UILabel *counterLabel;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property(weak, nonatomic) IBOutlet UIButton *passwordButton;
@property(weak, nonatomic) IBOutlet UIView *tipContainer;

- (IBAction)controlChanged:(UIControl *)control;
- (IBAction)copyPassword:(UITapGestureRecognizer *)recognizer;

@end
