//
//  MPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPGuideViewController.h"


@implementation MPGuideViewController
@synthesize scrollView;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [self.scrollView autoSizeContent];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [MPiOSConfig get].showQuickStart = [NSNumber numberWithBool:NO];
}

- (void)viewDidUnload {

    [self setScrollView:nil];
    [super viewDidUnload];
}

- (IBAction)close {

    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
