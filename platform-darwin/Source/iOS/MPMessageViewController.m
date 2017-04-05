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

#import "MPMessageViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPOverlayViewController.h"

@interface MPMessageViewController()

@property(nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic) IBOutlet UILabel *messageLabel;
@property(nonatomic) IBOutlet UIView *infoView;

@end

@implementation MPMessage

+ (instancetype)messageWithTitle:(NSString *)title text:(NSString *)text info:(BOOL)info {

    MPMessage *message = [MPMessage new];
    message.title = title;
    message.text = text;
    message.info = info;

    return message;
}

@end

@implementation MPMessageViewController

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.titleLabel.text = self.message.title;
    self.messageLabel.text = self.message.text;
    self.infoView.gone = !self.message.info;

    PearlAddNotificationObserver( MPSignedOutNotification, nil, [NSOperationQueue mainQueue],
            ^(MPMessageViewController *self, NSNotification *note) {
                if (![note.userInfo[@"animated"] boolValue])
                    [UIView setAnimationsEnabled:NO];
                [[MPOverlaySegue dismissViewController:self] perform];
                [UIView setAnimationsEnabled:YES];
            } );
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObservers();
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - State

@end
