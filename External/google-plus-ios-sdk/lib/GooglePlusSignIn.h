//
//  GooglePlusSignIn.h
//  Google+ iOS SDK
//
//  Copyright 2012 Google Inc.
//
//  Usage of this SDK is subject to the Google+ Platform Terms of Service:
//  https://developers.google.com/+/terms
//

#import <Foundation/Foundation.h>

@class GTMOAuth2Authentication;
@class GTMOAuth2ViewControllerTouch;

// Protocol implemented by the client of GooglePlusSignIn to receive a refresh
// token or an error. It is up to the client to present the OAuth 2.0 view
// controller if single sign-on is disabled via |attemptSSO| in |authenticate|.
@protocol GooglePlusSignInDelegate

// Authorization has finished and is successful if |error| is |nil|.
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error;

@end

// |GooglePlusSignIn| signs the user in with Google+. It provides single sign-on
// via the Google+ app, if installed, or Mobile Safari.
// Here is sample code to use GooglePlusSignIn:
//   1) GooglePlusSignIn *signIn =
//         [[GooglePlusSignIn alloc] initForClientID:clientID
//             language:@"en"
//                scope:@"https://www.googleapis.com/auth/plus.me"
//         keychainName:nil];
//      [signIn setDelegate:self];
//   2) Setup delegate methods |finishedWithAuth|, etc.
//   3) Call |handleURL| from |application:openUrl:...| in your app delegate.
//   4) [auth authenticate:YES];
@interface GooglePlusSignIn : NSObject

// The object to be notified when authentication is finished.
@property (nonatomic, assign) id<GooglePlusSignInDelegate> delegate;

// Initializes with your |clientID| from the Google APIs console. Set |scope| to
// an array of your API scopes. Set |keychainName| to |nil| to use the default
// name.
- (id)initWithClientID:(NSString *)clientID
              language:(NSString *)language
                 scope:(NSArray *)scope
          keychainName:(NSString *)keychainName;

// Starts the authentication process. Set |attemptSSO| to try single sign-on.
// Set |clearKeychain| to remove previously stored authentication in the
// keychain.
- (void)authenticate:(BOOL)attemptSSO clearKeychain:(BOOL)clearKeychain;

// This method should be called from your |UIApplicationDelegate|'s
// |application:openURL:sourceApplication:annotation|. Returns |YES| if
// |GooglePlusSignIn| handled this URL.
- (BOOL)handleURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation;

// Removes the OAuth 2.0 token from the keychain.
- (void)signOut;

@end
