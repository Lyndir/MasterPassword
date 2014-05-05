//
//  MPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPGuideViewController.h"

@interface MPGuideViewController()

@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic) int tickCount;
@property(nonatomic) int currentTick;
@property(nonatomic) int lastTick;
@property(nonatomic) BOOL muted;
@end

@implementation MPGuideViewController

- (BOOL)shouldAutorotate {

    return NO;
}

- (BOOL)prefersStatusBarHidden {

    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.siteNameTip.hidden = NO;
    self.contentTip.hidden = NO;
    self.usernameTip.hidden = NO;
    self.typeTip.hidden = NO;
    self.toolTip.hidden = NO;
    self.alertTip.hidden = NO;

    self.tickCount = 30;
}

- (void)viewWillAppear:(BOOL)animated {

    [self.navigationController setNavigationBarHidden:YES animated:animated];

    inf(@"Guide will appear.");
    [super viewWillAppear:animated];

    if (self.navigationController) {
        // Via setup
        self.smallPlayButton.hidden = YES;

        self.searchBar.text = nil;
        self.siteNameTip.alpha = 0;
        self.content.alpha = 0;
        self.content.frame = CGRectSetHeight( self.content.frame, 180 );
        self.contentTip.alpha = 0;
        self.contentButton.highlighted = NO;
        self.usernameTip.alpha = 0;
        self.usernameButton.highlighted = NO;
        self.typeTip.alpha = 0;
        self.typeButton.highlighted = NO;
        self.toolTip.alpha = 0;
        self.toolButton.highlighted = NO;
        self.alertTip.alpha = 0;
    }
    else {
        // Via segue
        self.largePlayButton.hidden = YES;

        self.searchBar.text = @"gmail.com";
        self.siteNameTip.alpha = 1;
        self.content.alpha = 1;
        self.content.frame = CGRectSetHeight( self.content.frame, 231 );
        self.contentTip.alpha = 1;
        self.contentTipText.text = @"Tap to copy";
        self.contentButton.highlighted = NO;
        self.usernameTip.alpha = 1;
        self.usernameButton.highlighted = NO;
        self.typeTip.alpha = 1;
        self.typeButton.highlighted = NO;
        self.toolTip.alpha = 0;
        self.toolButton.highlighted = NO;
        self.alertTip.alpha = 1;
    }
}

- (void)viewDidAppear:(BOOL)animated {

#ifdef LOCALYTICS
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Guide"];
#endif

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Guide will disappear.");
    [super viewWillDisappear:animated];
}

- (IBAction)play {

    if (self.timer) {
        // Pause
        [self.timer invalidate];
        self.timer = nil;

        self.smallPlayButton.hidden = NO;
        [self.smallPlayButton setImage:[UIImage imageNamed:@"icon_play"] forState:UIControlStateNormal];
    }

    else {
        // Play
        self.smallPlayButton.hidden = NO;
        self.largePlayButton.hidden = YES;
        [self.smallPlayButton setImage:[UIImage imageNamed:@"icon_pause"] forState:UIControlStateNormal];

        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tick:)
                                                    userInfo:nil repeats:YES];
    }
}

- (IBAction)close {

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)tick:(NSTimer *)timer {

    self.lastTick = self.currentTick;
    ++self.currentTick;
    [self.progress setProgress:(float)self.currentTick / self.tickCount animated:YES];

    if (self.currentTick < 5) {
        [UIView animateWithDuration:0.5 animations:^{
            self.searchBar.text = nil;
            self.siteNameTip.alpha = 1;
            self.content.alpha = 0;
            self.content.frame = CGRectSetHeight( self.content.frame, 180 );
            self.contentTip.alpha = 0;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.toolTip.alpha = 0;
            self.alertTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 10) {
        [UIView animateWithDuration:0.5 animations:^{
            self.searchBar.text = @"gmail.com";
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 1;
            self.contentTipText.text = @"Your password";
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.toolTip.alpha = 0;
            self.alertTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 15) {
        [UIView animateWithDuration:0.5 animations:^{
            self.searchBar.text = @"gmail.com";
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 1;
            self.contentTipText.text = @"Tap to copy";
            self.contentButton.highlighted = YES;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.toolButton.highlighted = NO;
            self.toolTip.alpha = 0;
            self.alertTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 20) {
        [UIView animateWithDuration:0.5 animations:^{
            self.searchBar.text = @"gmail.com";
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.content.frame = CGRectSetHeight( self.content.frame, 231 );
            self.contentTip.alpha = 0;
            self.contentButton.highlighted = NO;
            self.usernameButton.highlighted = YES;
            self.usernameTip.alpha = 1;
            self.typeTip.alpha = 0;
            self.toolTip.alpha = 0;
            self.alertTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 25) {
        [UIView animateWithDuration:0.5 animations:^{
            self.searchBar.text = @"gmail.com";
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 0;
            self.usernameButton.highlighted = NO;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 1;
            self.typeButton.highlighted = YES;
            self.toolTip.alpha = 0;
            self.alertTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 30) {
        [UIView animateWithDuration:0.5 animations:^{
            self.searchBar.text = @"gmail.com";
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 0;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.typeButton.highlighted = NO;
            self.toolButton.highlighted = YES;
            self.toolTip.alpha = 1;
            self.alertTip.alpha = 0;
            self.contentText.text = @"XupuMajf4'Hafh";
        }];
    }
    else if (self.currentTick <= self.tickCount) {
        [self.timer invalidate];
        self.timer = nil;
        self.currentTick = 0;
        [UIView animateWithDuration:0.5 animations:^{
            [self.smallPlayButton setImage:[UIImage imageNamed:@"icon_play"] forState:UIControlStateNormal];
            self.searchBar.text = @"gmail.com";
            self.siteNameTip.alpha = 1;
            self.content.alpha = 1;
            self.contentTip.alpha = 1;
            self.usernameTip.alpha = 1;
            self.typeTip.alpha = 1;
            self.toolButton.highlighted = NO;
            self.toolTip.alpha = 0;
            self.alertTip.alpha = 1;
        }];
    }
}

@end
