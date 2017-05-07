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

#import <UIKit/UIKit.h>
#import "MPTypeViewController.h"

@interface MPPreferencesViewController : UITableViewController

@property(weak, nonatomic) IBOutlet UISwitch *savePasswordSwitch;
@property(weak, nonatomic) IBOutlet UISwitch *touchIDSwitch;
@property(weak, nonatomic) IBOutlet UITableViewCell *signOutCell;
@property(weak, nonatomic) IBOutlet UITableViewCell *feedbackCell;
@property(weak, nonatomic) IBOutlet UITableViewCell *showHelpCell;
@property(weak, nonatomic) IBOutlet UITableViewCell *exportCell;
@property(weak, nonatomic) IBOutlet UITableViewCell *checkInconsistencies;
@property(weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property(weak, nonatomic) IBOutlet UISegmentedControl *generated1TypeControl;
@property(weak, nonatomic) IBOutlet UISegmentedControl *generated2TypeControl;
@property(weak, nonatomic) IBOutlet UISegmentedControl *storedTypeControl;
@property(weak, nonatomic) IBOutlet UILabel *typeSamplePassword;

- (IBAction)previousAvatar:(id)sender;
- (IBAction)nextAvatar:(id)sender;
- (IBAction)valueChanged:(id)sender;
- (IBAction)homePageButton:(id)sender;
- (IBAction)securityButton:(id)sender;
- (IBAction)sourceButton:(id)sender;
- (IBAction)thanksButton:(id)sender;

@end
