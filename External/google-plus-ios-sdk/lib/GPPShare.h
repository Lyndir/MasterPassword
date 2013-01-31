//
//  GPPShare.h
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
// 1. Initialize a GPPShare instance with your registered client ID:
//
//    GPPShare *gppShare = [[GPPShare alloc] initWithClientID:myClientID];
//
// 2. In the code where the share dialog is to be opened:
//
//    [[gppShare shareDialog] open];
//
//    You may optionally call |setURLToShare:| and/or |setPrefillText:| before
//    calling |open|, if there is a particular URL resource to be shared, or
//    you want to set text to prefill user comment in the share dialog, e.g.
//
//    NSURL *urlToShare = [NSURL URLWithString:@"http://www.google.com/"];
//    NSString *prefillText = @"You probably already know this site...";
//    [[[[gppShare shareDialog] setURLToShare:urlToShare]
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
//      if ([gppShare handleURL:url
//            sourceApplication:sourceApplication
//                   annotation:annotation]) {
//        return YES;
//      }
//      // Other handling code here...
//    }
//
// 5. Optionally, if you want to be notified of the result of the share action,
//    have a delegate class implement |GPPShareDelegate|, e.g.
//
//    @interface MyDelegateClass : NSObject<GPPShareDelegate>;
//
//    - (void)finishedSharing:(BOOL)shared {
//      // The share action was successful if |shared| is YES.
//    }
//
//    MyDelegateClass *myDelegate = [[MyDelegateClass alloc] init];
//    gppShare.delegate = myDelegate;

#import <Foundation/Foundation.h>

// Protocol to receive the result of the share action.
@protocol GPPShareDelegate

// Reports the status of the share action, |shared| is |YES| if user has
// successfully shared her post, |NO| otherwise, e.g. user canceled the post.
- (void)finishedSharing:(BOOL)shared;

@end

// The builder protocol to open the share dialog.
@protocol GPPShareBuilder<NSCopying>

// Sets the URL resource to be shared.
- (id<GPPShareBuilder>)setURLToShare:(NSURL *)urlToShare;

// Sets the text to prefill user comment in the share dialog.
- (id<GPPShareBuilder>)setPrefillText:(NSString *)prefillText;

// Sets the title, description, and thumbnail URL of the shared content preview
// in the share dialog. Only set these fields if you are sharing with a content
// deep link and don't have a URL resource. Title and description are required
// fields.
- (id<GPPShareBuilder>)setTitle:(NSString *)title
                    description:(NSString *)description
                   thumbnailURL:(NSURL *)thumbnailURL;

// Sets the content deep-link ID that takes the user straight to your shared
// content. Only set this field if you want the content deep-linking feature.
// The content deep-link ID can either be a fully qualified URI, or URI path,
// which can be up to 64 characters in length.
- (id<GPPShareBuilder>)setContentDeepLinkID:(NSString *)contentDeepLinkID;

// Opens the share dialog. Returns |NO| if there was an error, |YES| otherwise.
- (BOOL)open;

@end

// The primary class for the share action on Google+.
@interface GPPShare : NSObject

// The object to be notified when the share action has finished.
@property (nonatomic, assign) id<GPPShareDelegate> delegate;

// All Google+ objects must be initialized with a client ID registered
// in the Google APIs console, https://code.google.com/apis/console/
// with their corresponding bundle ID before they can be used.
- (id)initWithClientID:(NSString *)clientID;

// Returns a share dialog builder instance. Call its |open| method to
// create the dialog after setting the parameters as needed.
- (id<GPPShareBuilder>)shareDialog;

// This method should be called from your |UIApplicationDelegate|'s
// |application:openURL:sourceApplication:annotation|. Returns |YES| if
// |GPPShare| handled this URL.
- (BOOL)handleURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation;

@end
