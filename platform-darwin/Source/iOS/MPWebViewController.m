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

    [self.webView.scrollView insetOcclusion];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    if (!self.initialURL)
        self.initialURL = [NSURL URLWithString:@"https://masterpassword.app"];

    self.webNavigationItem.title = self.initialURL.host;

    self.webView.visible = NO;
    [self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.initialURL]];
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {

    if ([[request.URL absoluteString] rangeOfString:@"thanks.lhunath.com"].location != NSNotFound) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"tipped.thanks"];
        if (![[NSUserDefaults standardUserDefaults] synchronize])
            wrn( @"Couldn't synchronize thanks tip." );
    }

    if ([request.URL isEqual:request.mainDocumentURL]) {
        self.webNavigationItem.title = request.URL.host;
        self.webNavigationItem.prompt = strl( @"Loading" );
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {

    UIActivityIndicatorView *activityView =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.webNavigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:activityView]];
    [activityView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    [UIView animateWithDuration:0.3 animations:^{
        self.webView.visible = YES;
    }];

    [self.webNavigationItem setLeftBarButtonItem:[webView canGoBack]? [[UIBarButtonItem alloc]
            initWithTitle:@"⬅︎" style:UIBarButtonItemStylePlain target:webView action:@selector( goBack )]: nil];
    self.webNavigationItem.prompt = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

#pragma mark - Actions

- (IBAction)done:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
