//
//  OPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPGuideViewController.h"
#import "OPAppDelegate.h"

@implementation OPGuideViewController
@synthesize scrollView;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [UIUtils autoSizeContent:self.scrollView];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [OPConfig get].showQuickstart = [NSNumber numberWithBool:NO];
    [[OPAppDelegate get] loadKeyPhrase];
}

- (void)viewDidUnload {

    [self setScrollView:nil];
    [super viewDidUnload];
}

- (IBAction)close {

    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
