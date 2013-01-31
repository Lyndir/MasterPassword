//
//  GPPDeepLink.h
//  Google+ iOS SDK
//
//  Copyright 2012 Google Inc.
//
//  Usage of this SDK is subject to the Google+ Platform Terms of Service:
//  https://developers.google.com/+/terms
//

#import <Foundation/Foundation.h>

@interface GPPDeepLink : NSObject

// Returns a |GPPDeepLink| for your app to handle, or |nil| if not found. The
// deep-link ID can be obtained from |GPPDeepLink|. It is stored when a user
// clicks a link to your app from a Google+ post, but hasn't yet installed your
// app. The user will be redirected to the App Store to install your app. This
// method should be called on or near your app launch to take the user to
// deep-link ID within your app.
+ (GPPDeepLink *)readDeepLinkAfterInstall;

// This method should be called from your |UIApplicationDelegate|'s
// |application:openURL:sourceApplication:annotation|. Returns
// |GooglePlusDeepLink| if |GooglePlusDeepLink| handled this URL, |nil|
// otherwise.
+ (GPPDeepLink *)handleURL:(NSURL *)url
         sourceApplication:(NSString *)sourceApplication
                annotation:(id)annotation;

// The deep-link ID in |GPPDeepLink| that was passed to the app.
- (NSString *)deepLinkID;

// This indicates where the user came from before arriving in your app. This is
// provided for you to collect engagement metrics. For the possible values,
// see our developer docs at http://developers.google.com/+/mobile/ios/.
- (NSString *)source;

@end
