//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

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
