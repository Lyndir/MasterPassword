//
//  GPPSignIn.h
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

// Protocol implemented by the client of GPPSignIn to receive a refresh
// token or an error. It is up to the client to present the OAuth 2.0 view
// controller if single sign-on is disabled via |attemptSSO| in |authenticate|.
@protocol GPPSignInDelegate

// Authorization has finished and is successful if |error| is |nil|.
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error;

@end

// |GPPSignIn| signs the user in with Google+. It provides single sign-on
// via the Google+ app, if installed, or Mobile Safari.
// Here is sample code to use GPPSignIn:
//   1) GPPSignIn *signIn =
//         [[GPPSignIn alloc] initForClientID:clientID
//             language:@"en"
//                scope:@"https://www.googleapis.com/auth/plus.me"
//         keychainName:nil];
//      [signIn setDelegate:self];
//   2) Setup delegate methods |finishedWithAuth|, etc.
//   3) Call |handleURL| from |application:openUrl:...| in your app delegate.
//   4) [auth authenticate:YES];
@interface GPPSignIn : NSObject

// The object to be notified when authentication is finished.
@property (nonatomic, assign) id<GPPSignInDelegate> delegate;

// Whether or not to fetch user email after signing in. The email is saved in
// the |GTMOAuth2Authentication| object.
@property (nonatomic, assign) BOOL shouldFetchGoogleUserEmail;

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
// |GPPSignIn| handled this URL.
- (BOOL)handleURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation;

// Removes the OAuth 2.0 token from the keychain.
- (void)signOut;

@end
