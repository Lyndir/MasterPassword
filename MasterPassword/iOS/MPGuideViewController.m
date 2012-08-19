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
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated? UIStatusBarAnimationSlide: UIStatusBarAnimationNone];

    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Guide will disappear.");
    [super viewWillDisappear:animated];

    [MPiOSConfig get].showQuickStart = @NO;
}

- (void)viewDidUnload {

    [self setScrollView:nil];
    [self setPageControl:nil];
    [super viewDidUnload];
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
