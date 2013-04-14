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

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.tickCount = 30;
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Guide will appear.");
    [super viewWillAppear:animated];

    if (self.navigationController) {
        // Via setup
        [self.navigationController setNavigationBarHidden:YES animated:animated];
        self.smallPlayButton.hidden = YES;
        self.siteNameTip.alpha = 0;
        self.content.alpha = 0;
        self.content.frame = CGRectSetHeight( self.content.frame, 180 );
        self.contentTip.alpha = 0;
        self.usernameTip.alpha = 0;
        self.typeTip.alpha = 0;
        self.toolTip.alpha = 0;
    }
    else {
        // Via segue
        self.largePlayButton.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Guide"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Guide will disappear.");
    [self.navigationController setNavigationBarHidden:NO animated:animated];
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

- (IBAction)toggleVolume {

    if ((self.muted = !self.muted))
        [self.volumeButton setImage:[UIImage imageNamed:@"icon_volume-mute"] forState:UIControlStateNormal];
    else
        [self.volumeButton setImage:[UIImage imageNamed:@"icon_volume-high"] forState:UIControlStateNormal];
}

- (void)tick:(NSTimer *)timer {

    self.lastTick = self.currentTick;
    ++self.currentTick;
    [self.progress setProgress:(float)self.currentTick / self.tickCount animated:YES];

    if (self.currentTick < 5) {
        [UIView animateWithDuration:0.5 animations:^{
            self.siteNameTip.alpha = 1;
            self.content.alpha = 0;
            self.content.frame = CGRectSetHeight( self.content.frame, 180 );
            self.contentTip.alpha = 0;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.toolTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 10) {
        [UIView animateWithDuration:0.5 animations:^{
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 1;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.toolTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 15) {
        [UIView animateWithDuration:0.5 animations:^{
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 1;
            self.contentButton.highlighted = YES;
            self.contentTipText.text = @"Tap to copy";
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.toolButton.highlighted = NO;
            self.toolTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 20) {
        [UIView animateWithDuration:0.5 animations:^{
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.content.frame = CGRectSetHeight( self.content.frame, 231 );
            self.contentTip.alpha = 0;
            self.contentButton.highlighted = NO;
            self.contentTipText.text = @"Use this password";
            self.usernameButton.highlighted = YES;
            self.usernameTip.alpha = 1;
            self.typeTip.alpha = 0;
            self.toolTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 25) {
        [UIView animateWithDuration:0.5 animations:^{
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 0;
            self.usernameButton.highlighted = NO;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 1;
            self.typeButton.highlighted = YES;
            self.toolTip.alpha = 0;
        }];
    }
    else if (self.currentTick < 30) {
        [UIView animateWithDuration:0.5 animations:^{
            self.siteNameTip.alpha = 0;
            self.content.alpha = 1;
            self.contentTip.alpha = 0;
            self.usernameTip.alpha = 0;
            self.typeTip.alpha = 0;
            self.typeButton.highlighted = NO;
            self.toolButton.highlighted = YES;
            self.toolTip.alpha = 1;
            self.contentText.text = @"XupuMajf4'Hafh";
        }];
    }
    else if (self.currentTick <= self.tickCount) {
        [self.timer invalidate];
        self.timer = nil;
        self.currentTick = 0;
        [UIView animateWithDuration:0.5 animations:^{
            [self.smallPlayButton setImage:[UIImage imageNamed:@"icon_play"] forState:UIControlStateNormal];
            self.siteNameTip.alpha = 1;
            self.content.alpha = 1;
            self.contentTip.alpha = 1;
            self.usernameTip.alpha = 1;
            self.typeTip.alpha = 1;
            self.toolButton.highlighted = NO;
            self.toolTip.alpha = 0;
        }];
    }
}

@end
