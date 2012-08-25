//
//  GooglePlusShare.h
//  Google+ iOS SDK
//
//  Copyright 2012 Google Inc.
//
//  Usage of this SDK is subject to the Google+ Platform Terms of Service:
//  https://developers.google.com/+/terms
//

// To allow a user to share with Google+, please follow these steps:
//
// 0. Create a project on Google APIs console,
//    https://code.google.com/apis/console . Under "API Access", create a
//    client ID as "Installed application" with the type "iOS", and
//    register the bundle ID of your application.
//
// 1. Initialize a GooglePlusShare instance with your registered client ID:
//
//    GooglePlusShare *googlePlusShare =
//        [[GooglePlusShare alloc] initWithClientID:myClientID];
//
// 2. In the code where the share dialog is to be opened:
//
//    [[googlePlusShare shareDialog] open];
//
//    You may optionally call |setURLToShare:| and/or |setPrefillText:| before
//    calling |open|, if there is a particular URL resource to be shared, or
//    you want to set text to prefill user comment in the share dialog, e.g.
//
//    NSURL *urlToShare = [NSURL URLWithString:@"http://www.google.com/"];
//    NSString *prefillText = @"You probably already know this site...";
//    [[[[googlePlusShare shareDialog] setURLToShare:urlToShare]
//        setPrefillText:prefillText] open];
//
// 3. In the 'YourApp-info.plist' settings for your application, add a URL
//    type to be handled by your application. Make the URL scheme the same as
//    the bundle ID of your application.
//
// 4. In your application delegate, implement
//    - (BOOL)application:(NSString*)application
//                openURL:(NSURL *)url
//      sourceApplication:(NSString*)sourceApplication
//             annotation:(id)annotation {
//      if ([googlePlusShare handleURL:url
//                   sourceApplication:sourceApplication
//                          annotation:annotation]) {
//        return YES;
//      }
//      // Other handling code here...
//    }
//
// 5. Optionally, if you want to be notified of the result of the share action,
//    have a delegate class implement |GooglePlusShareDelegate|, e.g.
//
//    @interface MyDelegateClass : NSObject<GooglePlusShareDelegate>;
//
//    - (void)finishedSharing:(BOOL)shared {
//      // The share action was successful if |shared| is YES.
//    }
//
//    MyDelegateClass *myDelegate = [[MyDelegateClass alloc] init];
//    googlePlusShare.delegate = myDelegate;

#import <Foundation/Foundation.h>

// Protocol to receive the result of the share action.
@protocol GooglePlusShareDelegate

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared;

@end

// The builder protocol to open the share dialog.
@protocol GooglePlusShareBuilder<NSCopying>

// Sets the URL resource to be shared.
- (id<GooglePlusShareBuilder>)setURLToShare:(NSURL *)urlToShare;

// Sets the text to prefill user comment in the share dialog.
- (id<GooglePlusShareBuilder>)setPrefillText:(NSString *)prefillText;

// Opens the share dialog.
- (void)open;

@end

// The primary class for the share action on Google+.
@interface GooglePlusShare : NSObject

// The object to be notified when the share action has finished.
@property (nonatomic, assign) id<GooglePlusShareDelegate> delegate;

// All Google+ objects must be initialized with a client ID registered
// in the Google APIs console, https://code.google.com/apis/console/
// with their corresponding bundle ID before they can be used.
- (id)initWithClientID:(NSString *)clientID;

// Returns a share dialog builder instance. Call its |open| method to
// create the dialog after setting the parameters as needed.
- (id<GooglePlusShareBuilder>)shareDialog;

// This method should be called from your |UIApplicationDelegate|'s
// |application:openURL:sourceApplication:annotation|. Returns |YES| if
// |GooglePlusShare| handled this URL.
- (BOOL)handleURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation;

@end
