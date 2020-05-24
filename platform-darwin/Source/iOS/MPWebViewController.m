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
#import "MPiOSAppDelegate.h"

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

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void ( ^ )(WKNavigationActionPolicy))decisionHandler {

    if ([navigationAction.request.mainDocumentURL.scheme isEqualToString:@"masterpassword"]) {
        [[MPiOSAppDelegate get] openURL:navigationAction.request.mainDocumentURL];
        decisionHandler( WKNavigationActionPolicyCancel );
        return;
    }

    decisionHandler( WKNavigationActionPolicyAllow );
}

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

    [self.webNavigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector( action: )]];
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id o, NSError *error) {
        self.webNavigationItem.prompt = [o description];
    }];
}

#pragma mark - Actions

- (IBAction)action:(UIBarButtonItem *)sender {

    UIAlertController *controller = [UIAlertController alertControllerWithTitle:self.webView.URL.host
                                                                        message:self.webView.URL.absoluteString
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
    [controller.popoverPresentationController setBarButtonItem:sender];
    [controller addAction:[UIAlertAction actionWithTitle:@"Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [UIApp openURL:self.webView.URL];
    }]];
    if ([UIApp canOpenURL:[NSURL URLWithString:@"firefox:"]]) {
        [controller addAction:[UIAlertAction actionWithTitle:@"Firefox" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [UIApp openURL:[NSURL URLWithString:strf( @"firefox://open-url?url=%@",
                    [self.webView.URL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:
                            [NSCharacterSet URLQueryAllowedCharacterSet]] )]];
        }]];
    }
    if ([UIApp canOpenURL:[NSURL URLWithString:@"googlechrome:"]]) {
        NSURL *url = [[NSURL alloc] initWithScheme:[self.webView.URL.scheme isEqualToString:@"http"]? @"googlechrome": @"googlechromes"
                                              host:self.webView.URL.host path:self.webView.URL.path];
        [controller addAction:[UIAlertAction actionWithTitle:@"Chrome" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [UIApp openURL:url];
        }]];
    }
    if ([UIApp canOpenURL:[NSURL URLWithString:@"opera-http:"]]) {
        NSURL *url = [[NSURL alloc] initWithScheme:[self.webView.URL.scheme isEqualToString:@"http"]? @"opera-http": @"opera-https"
                                              host:self.webView.URL.host path:self.webView.URL.path];
        [controller addAction:[UIAlertAction actionWithTitle:@"Opera" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [UIApp openURL:url];
        }]];
    }
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)done:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
