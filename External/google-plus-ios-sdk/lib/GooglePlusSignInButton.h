//
//  GooglePlusSignInButton.h
//  Google+ iOS SDK
//
//  Copyright 2012 Google Inc.
//
//  Usage of this SDK is subject to the Google+ Platform Terms of Service:
//  https://developers.google.com/+/terms
//

#import <UIKit/UIKit.h>

@class GooglePlusSignIn;
@protocol GooglePlusSignInDelegate;

// The various visual styles supported by the GooglePlusSignInButton.
typedef enum {
  kGooglePlusSignInButtonStyleNormal,
  kGooglePlusSignInButtonStyleWide
} GooglePlusSignInButtonStyle;

// A view that displays the Google+ sign-in button. You can instantiate this
// class programmatically or from a NIB file. Once instantiated, you should
// set the client ID and delegate properties and add this view to your own view
// hierarchy.
@interface GooglePlusSignInButton : UIView

// The OAuth 2.0 client ID of the application.
@property(nonatomic, copy) NSString *clientID;

// See GooglePlusSignIn.h for details on this delegate.
@property(nonatomic, assign) id<GooglePlusSignInDelegate> delegate;

// Actually does the work of signing in with Google+.
@property(nonatomic, readonly) GooglePlusSignIn *googlePlusSignIn;

// The OAuth 2.0 scopes for the APIs that you are using. This is used to fetch
// an OAuth 2.0 token. By default, this is set to the
// https://www.googleapis.com/auth/plus.me scope.
@property(nonatomic, copy) NSArray *scope;

// Sets the sign-in button. The default style is normal.
- (void)setStyle:(GooglePlusSignInButtonStyle)style;

// This method should be called from your |UIApplicationDelegate|'s
// |application:openURL:sourceApplication:annotation|. Returns |YES| if
// |GooglePlusSignInButton| handled this URL.
- (BOOL)handleURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation;

@end
