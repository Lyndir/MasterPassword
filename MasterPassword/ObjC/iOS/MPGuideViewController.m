//
//  MPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPGuideViewController.h"


@implementation MPGuideViewController

- (BOOL)shouldAutorotate {
    
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    
    return UIInterfaceOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Guide will appear.");
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Guide"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Guide will disappear.");
    [super viewWillDisappear:animated];
}

- (IBAction)close {

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
