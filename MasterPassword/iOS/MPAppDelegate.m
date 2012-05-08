//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

#import "MPMainViewController.h"
#import "IASKSettingsReader.h"
#import "LocalyticsSession.h"
#import "TestFlight.h"
#import <Crashlytics/Crashlytics.h>

@interface MPAppDelegate ()

- (NSString *)testFlightInfo;
- (NSString *)testFlightToken;

- (NSString *)crashlyticsInfo;
- (NSString *)crashlyticsAPIKey;

- (NSString *)localyticsInfo;
- (NSString *)localyticsKey;

@end


@implementation MPAppDelegate

@synthesize key;
@synthesize keyHash;
@synthesize keyHashHex;

+ (void)initialize {
    
    [MPiOSConfig get];
    
#ifdef DEBUG
    [PearlLogger get].autoprintLevel = PearlLogLevelDebug;
    //[NSClassFromString(@"WebView") performSelector:NSSelectorFromString(@"_enableRemoteInspector")];
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#ifndef DEBUG
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @try {
            NSString *testFlightToken = [self testFlightToken];
            if ([testFlightToken length]) {
                dbg(@"Initializing TestFlight");
                [TestFlight addCustomEnvironmentInformation:@"Anonymous" forKey:@"username"];
                [TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO],   @"logToConsole",
                                        [NSNumber numberWithBool:NO],   @"logToSTDERR",
                                        nil]];
                [TestFlight takeOff:testFlightToken];
                [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                    if (message.level >= PearlLogLevelInfo)
                        TFLog(@"%@", message);
                    
                    return YES;
                }];
                [TestFlight passCheckpoint:MPTestFlightCheckpointLaunched];
            }
        }
        @catch (NSException *exception) {
            err(@"TestFlight: %@", exception);
        }
        @try {
            NSString *crashlyticsAPIKey = [self crashlyticsAPIKey];
            if ([crashlyticsAPIKey length]) {
                dbg(@"Initializing Crashlytics");
                //[Crashlytics sharedInstance].debugMode = YES;
                [Crashlytics startWithAPIKey:crashlyticsAPIKey afterDelay:0];
            }
        }
        @catch (NSException *exception) {
            err(@"Crashlytics: %@", exception);
        }
        @try {
            NSString *localyticsKey = [self localyticsKey];
            if ([localyticsKey length]) {
                dbg(@"Initializing Localytics");
                [[LocalyticsSession sharedLocalyticsSession] startSession:localyticsKey];
                [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                    if (message.level >= PearlLogLevelError)
                        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Problem" attributes:
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          [message levelDescription],
                          @"level",
                          message.message,
                          @"message",
                          nil]];
                    
                    return YES;
                }];
            }
        }
        @catch (NSException *exception) {
            err(@"Localytics exception: %@", exception);
        }
    });
#endif
    
    UIImage *navBarImage = [[UIImage imageNamed:@"ui_navbar_container"]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],                          UITextAttributeTextColor,
      [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f],                          UITextAttributeTextShadowColor, 
      [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],                                      UITextAttributeTextShadowOffset, 
      [UIFont fontWithName:@"Helvetica-Neue" size:0.0f],                                    UITextAttributeFont, 
      nil]];
    
    UIImage *navBarButton   = [[UIImage imageNamed:@"ui_navbar_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    UIImage *navBarBack     = [[UIImage imageNamed:@"ui_navbar_back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 5)];
    [[UIBarButtonItem appearance] setBackgroundImage:navBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:navBarBack forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],                          UITextAttributeTextColor,
      [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f],                          UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],                                       UITextAttributeTextShadowOffset,
      [UIFont fontWithName:@"Helvetica-Neue" size:0.0f],                                    UITextAttributeFont,
      nil]
                                                forState:UIControlStateNormal];
    
    UIImage *toolBarImage = [[UIImage imageNamed:@"ui_toolbar_container"]  resizableImageWithCapInsets:UIEdgeInsetsMake(25, 5, 5, 5)];
    [[UISearchBar appearance] setBackgroundImage:toolBarImage];
    [[UIToolbar appearance] setBackgroundImage:toolBarImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    
    /*
     UIImage *minImage = [[UIImage imageNamed:@"slider-minimum.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
     UIImage *maxImage = [[UIImage imageNamed:@"slider-maximum.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
     UIImage *thumbImage = [UIImage imageNamed:@"slider-handle.png"];
     
     [[UISlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
     [[UISlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
     [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
     
     UIImage *segmentSelected = [[UIImage imageNamed:@"segcontrol_sel.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
     UIImage *segmentUnselected = [[UIImage imageNamed:@"segcontrol_uns.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
     UIImage *segmentSelectedUnselected = [UIImage imageNamed:@"segcontrol_sel-uns.png"];
     UIImage *segUnselectedSelected = [UIImage imageNamed:@"segcontrol_uns-sel.png"];
     UIImage *segmentUnselectedUnselected = [UIImage imageNamed:@"segcontrol_uns-uns.png"];
     
     [[UISegmentedControl appearance] setBackgroundImage:segmentUnselected forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
     [[UISegmentedControl appearance] setBackgroundImage:segmentSelected forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
     
     [[UISegmentedControl appearance] setDividerImage:segmentUnselectedUnselected forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
     [[UISegmentedControl appearance] setDividerImage:segmentSelectedUnselected forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
     [[UISegmentedControl appearance] setDividerImage:segUnselectedSelected forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];*/
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kIASKAppSettingChanged object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([NSStringFromSelector(@selector(saveKey))
                                                           isEqualToString:[note.object description]]) {
                                                          [self updateKey:self.key];
                                                          [self loadKey:YES];
                                                      }
                                                      if ([NSStringFromSelector(@selector(forgetKey))
                                                           isEqualToString:[note.object description]])
                                                          [self loadKey:YES];
                                                  }];
    
#ifdef ADHOC
    [PearlAlert showAlertWithTitle:@"Welcome, tester!" message:
     @"Thank you for taking the time to test Master Password.\n\n"
     @"Please provide any feedback, however minor it may seem, via the Feedback action item accessible from the top right.\n\n"
     @"Contact me directly at:\n"
     @"lhunath@lyndir.com\n"
     @"Or report detailed issues at:\n"
     @"https://youtrack.lyndir.com\n"
                         viewStyle:UIAlertViewStyleDefault tappedButtonBlock:nil
                       cancelTitle:nil otherTitles:[PearlStrings get].commonButtonOkay, nil];
#endif
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationSlide];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    if ([[MPiOSConfig get].showQuickStart boolValue])
        [self showGuide];
    else
        [self loadKey:NO];
    
    [TestFlight passCheckpoint:MPTestFlightCheckpointActivated];
}

- (void)showGuide {
    
    [self.navigationController performSegueWithIdentifier:@"MP_Guide" sender:self];
    
    [TestFlight passCheckpoint:MPTestFlightCheckpointShowGuide];
}

- (void)loadKey:(BOOL)animated {
    
    if (!self.key)
        // Try and load the key from the keychain.
        [self loadStoredKey];
    
    if (!self.key)
        // Ask the user to set the key through his master password.
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:
             [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MPUnlockViewController"]
                                                    animated:animated completion:nil];
        });
}

- (void)export {
    
    [PearlAlert showNotice:
     @"This export contains the names of all your sites.  "
     @"You can even open it in a text editor to view its contents.\n\n"
     @"If you ever loose your device and don't have iCloud enabled or sync with iTunes, "
     @"this will help you remember what sites you had an account with.\n"
     @"Don't worry: Even if you don't have an export of your sites, "
     @"loosing your device never means loosing your generated passwords."];
    [PearlAlert showAlertWithTitle:@"Reveal Passwords?" message:
     @"Would you like to make all your passwords visible in the export?\n\n"
     @"By default, only your stored passwords are exported, in an encrypted manner, "
     @"making it safe from falling in the wrong hands.\n"
     @"If you make all your passwords visible and somebody else finds the file, "
     @"they can gain access to all your sites with it!"
                         viewStyle:UIAlertViewStyleDefault tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                             if (buttonIndex == [alert firstOtherButtonIndex] + 0)
                                 // Safe Export
                                 [self exportShowPasswords:NO];
                             if (buttonIndex == [alert firstOtherButtonIndex] + 1)
                                 // Safe Export
                                 [self exportShowPasswords:YES];
                         } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Safe Export", @"Show Passwords", nil];
}

- (void)exportShowPasswords:(BOOL)showPasswords {
    
    NSString *exportedSites = [self exportSitesShowingPasswords:showPasswords];
    
    NSDateFormatter *exportDateFormatter = [NSDateFormatter new];
    [exportDateFormatter setDateFormat:@"yyyy'-'MM'-'DD'T'HH':'mm'.mpsites'"];
    
    MFMailComposeViewController *composer = [[MFMailComposeViewController alloc] init];
    [composer setMailComposeDelegate:self];
    [composer setSubject:@"Master Password site export"];
    [composer addAttachmentData:[exportedSites dataUsingEncoding:NSUTF8StringEncoding] mimeType:@"text/plain"
                       fileName:[exportDateFormatter stringFromDate:[NSDate date]]];
    [self.window.rootViewController presentModalViewController:composer animated:YES];
}

#pragma mark - UIApplicationDelegate

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    [super applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    [super applicationWillEnterForeground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
    
    [TestFlight passCheckpoint:MPTestFlightCheckpointTerminated];
    
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    [super applicationWillTerminate:application];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [self saveContext];
    
    if (![[MPiOSConfig get].rememberKey boolValue])
        [self updateKey:nil];
    
    [TestFlight passCheckpoint:MPTestFlightCheckpointDeactivated];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    if (error)
        err(@"Error composing mail message: %@", error);
    
    switch (result) {
        case MFMailComposeResultSaved:
        case MFMailComposeResultSent:
            break;
            
        case MFMailComposeResultFailed:
            break;
        case MFMailComposeResultCancelled:
            break;
    }
}

#pragma mark - TestFlight


static NSDictionary *testFlightInfo = nil;

- (NSDictionary *)testFlightInfo {
    
    if (testFlightInfo == nil)
        testFlightInfo = [[NSDictionary alloc] initWithContentsOfURL:
                          [[NSBundle mainBundle] URLForResource:@"TestFlight" withExtension:@"plist"]];
    
    return testFlightInfo;
}

- (NSString *)testFlightToken {
    
    return NSNullToNil([[self testFlightInfo] valueForKeyPath:@"Team Token"]);
}


#pragma mark - Crashlytics


static NSDictionary *crashlyticsInfo = nil;

- (NSDictionary *)crashlyticsInfo {
    
    if (crashlyticsInfo == nil)
        crashlyticsInfo = [[NSDictionary alloc] initWithContentsOfURL:
                           [[NSBundle mainBundle] URLForResource:@"Crashlytics" withExtension:@"plist"]];
    
    return crashlyticsInfo;
}

- (NSString *)crashlyticsAPIKey {
    
    return NSNullToNil([[self crashlyticsInfo] valueForKeyPath:@"API Key"]);
}


#pragma mark - Localytics


static NSDictionary *localyticsInfo = nil;

- (NSDictionary *)localyticsInfo {
    
    if (localyticsInfo == nil)
        localyticsInfo = [[NSDictionary alloc] initWithContentsOfURL:
                          [[NSBundle mainBundle] URLForResource:@"Localytics" withExtension:@"plist"]];
    
    return localyticsInfo;
}

- (NSString *)localyticsKey {
    
#ifdef DEBUG
    return NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.development"]);
#elif defined(LITE)
    return NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.distribution.lite"]);
#else
    return NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.distribution"]);
#endif
}

@end
