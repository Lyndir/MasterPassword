//
//  MPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPGuideViewController.h"
#import "LocalyticsSession.h"


@implementation MPGuideViewController
@synthesize scrollView;
@synthesize pageControl;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidLoad {

    [super viewDidLoad];

    [self.scrollView autoSizeContent];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Guide will appear.");
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [[LocalyticsSession sharedLocalyticsSession] tagScreen:@"Guide"];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Guide will disappear.");
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

    [MPiOSConfig get].showQuickStart = @NO;

    [super viewWillDisappear:animated];
}

- (IBAction)close {

    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView_ {
    
    NSInteger page = (NSInteger)(self.scrollView.contentOffset.x / self.scrollView.bounds.size.width);

    self.pageControl.currentPage = page;
    self.pageControl.hidden = (page == self.pageControl.numberOfPages - 1);
}

@end
