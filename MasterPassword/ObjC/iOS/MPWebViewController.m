/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPWebViewController.h
//  MPWebViewController
//
//  Created by lhunath on 2014-05-09.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPWebViewController.h"

@implementation MPWebViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    [self.webView.scrollView insetOcclusion];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    if (!self.initialURL)
        self.initialURL = [NSURL URLWithString:@"http://masterpasswordapp.com"];

    self.webNavigationItem.title = self.initialURL.host;

    self.webView.alpha = 0;
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
        self.webView.alpha = 1;
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
