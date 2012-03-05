//
//  MPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPGuideViewController.h"
#import "MPAppDelegate_Key.h"

@implementation MPGuideViewController
@synthesize scrollView;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [PearlUIUtils autoSizeContent:self.scrollView];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [MPiOSConfig get].showQuickStart = [NSNumber numberWithBool:NO];
}

- (void)viewDidDisappear:(BOOL)animated {

    [super viewDidDisappear:animated];

    [[MPAppDelegate get] loadKey:animated];
}


- (void)viewDidUnload {

    [self setScrollView:nil];
    [super viewDidUnload];
}

- (IBAction)close {

    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
