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

#import "MPWebViewController.h"

@implementation MPWebViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    if (!self.initialURL)
        self.initialURL = [NSURL URLWithString:@"https://masterpassword.app"];
    self.webNavigationItem.title = self.initialURL.host;

    // WKWebView can't be on the storyboard for iOS pre 11 due to an NSCoding bug.
    [self.view insertSubview:self.webView = [WKWebView new] atIndex:0];
    [self.webView setNavigationDelegate:self];
    [self.webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.initialURL]];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];
}

- (void)viewDidLayoutSubviews {
    [self.webView.scrollView insetOcclusion];
    [super viewDidLayoutSubviews];
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {

    self.webNavigationItem.title = webView.URL.host;
    self.webNavigationItem.prompt = strl( @"Loading" );

    UIActivityIndicatorView *activityView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.webNavigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:activityView]];
    [activityView startAnimating];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

    if ([[webView.URL absoluteString] rangeOfString:@"thanks.lhunath.com"].location != NSNotFound) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"tipped.thanks"];
        if (![[NSUserDefaults standardUserDefaults] synchronize])
            wrn( @"Couldn't synchronize thanks tip." );
    }

    [self.webNavigationItem setLeftBarButtonItem:[webView canGoBack]? [[UIBarButtonItem alloc]
            initWithTitle:@"⬅︎" style:UIBarButtonItemStylePlain target:webView action:@selector( goBack )]: nil];
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id o, NSError *error) {
        self.webNavigationItem.prompt = [o description];
    }];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
