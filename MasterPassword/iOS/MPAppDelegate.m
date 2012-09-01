//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>

#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

#import "IASKSettingsReader.h"
#import "LocalyticsSession.h"

@interface MPAppDelegate ()

- (NSDictionary *)testFlightInfo;
- (NSString *)testFlightToken;

- (NSDictionary *)crashlyticsInfo;
- (NSString *)crashlyticsAPIKey;

- (NSDictionary *)localyticsInfo;
- (NSString *)localyticsKey;

@end


@implementation MPAppDelegate

+ (void)initialize {

    [MPiOSConfig get];

#ifdef DEBUG
    [PearlLogger get].printLevel = PearlLogLevelDebug;
    //[NSClassFromString(@"WebView") performSelector:NSSelectorFromString(@"_enableRemoteInspector")];
#endif
}

+ (MPAppDelegate *)get {

    return (MPAppDelegate *)[super get];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[[NSBundle mainBundle] mutableInfoDictionary] setObject:@"Master Password" forKey:@"CFBundleDisplayName"];
    [[[NSBundle mainBundle] mutableLocalizedInfoDictionary] setObject:@"Master Password" forKey:@"CFBundleDisplayName"];

#ifdef ADHOC
    @try {
        NSString *testFlightToken = [self testFlightToken];
        if ([testFlightToken length]) {
            inf(@"Initializing TestFlight");
            [TestFlight setDeviceIdentifier:[(id)[UIDevice currentDevice] uniqueIdentifier]];
            //[TestFlight setDeviceIdentifier[PearlKeyChain deviceIdentifier]];
            [TestFlight addCustomEnvironmentInformation:@"Anonymous" forKey:@"username"];
            [TestFlight addCustomEnvironmentInformation:[PearlKeyChain deviceIdentifier] forKey:@"deviceIdentifier"];
            [TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO],   @"logToConsole",
                                    [NSNumber numberWithBool:NO],   @"logToSTDERR",
                                    nil]];
            [TestFlight takeOff:testFlightToken];
            [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                PearlLogLevel level = PearlLogLevelWarn;
                if ([[MPiOSConfig get].sendInfo boolValue])
                    level = PearlLogLevelInfo;

                if (message.level >= level)
                    TFLog(@"%@", [message messageDescription]);

                return YES;
            }];
            TFLog(@"TestFlight (%@) initialized for: %@ v%@.", //
             TESTFLIGHT_SDK_VERSION, [PearlInfoPlist get].CFBundleName, [PearlInfoPlist get].CFBundleVersion);
        }
    }
    @catch (id exception) {
        err(@"TestFlight: %@", exception);
    }
#endif
    @try {
        NSString *crashlyticsAPIKey = [self crashlyticsAPIKey];
        if ([crashlyticsAPIKey length]) {
            inf(@"Initializing Crashlytics");
#if defined (DEBUG) || defined (ADHOC)
            [Crashlytics sharedInstance].debugMode = YES;
#endif
            [Crashlytics setUserIdentifier:[PearlKeyChain deviceIdentifier]];
            [Crashlytics setObjectValue:[PearlKeyChain deviceIdentifier] forKey:@"deviceIdentifier"];
            [Crashlytics setUserName:@"Anonymous"];
            [Crashlytics setObjectValue:@"Anonymous" forKey:@"username"];
            [Crashlytics startWithAPIKey:crashlyticsAPIKey];
            [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                PearlLogLevel level = PearlLogLevelWarn;
                if ([[MPiOSConfig get].sendInfo boolValue])
                    level = PearlLogLevelInfo;

                if (message.level >= level)
                    CLSLog(@"%@", [message messageDescription]);

                return YES;
            }];
            CLSLog(@"Crashlytics (%@) initialized for: %@ v%@.", //
                   [Crashlytics sharedInstance].version, [PearlInfoPlist get].CFBundleName, [PearlInfoPlist get].CFBundleVersion);
        }
    }
    @catch (id exception) {
        err(@"Crashlytics: %@", exception);
    }
    @try {
        NSString *localyticsKey = [self localyticsKey];
        if ([localyticsKey length]) {
            inf(@"Initializing Localytics");
            [[LocalyticsSession sharedLocalyticsSession] startSession:localyticsKey];
            [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                if (message.level >= PearlLogLevelWarn)
                    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Problem"
                                                               attributes:@{
                                                               @"level": @(PearlLogLevelStr(message.level)),
                                                               @"message": message.message
                                                               }];

                return YES;
            }];
        }
    }
    @catch (id exception) {
        err(@"Localytics exception: %@", exception);
    }

    UIImage *navBarImage = [[UIImage imageNamed:@"ui_navbar_container"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:
     @{
     UITextAttributeTextColor: [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],
     UITextAttributeTextShadowColor: [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f],
     UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
     UITextAttributeFont: [UIFont fontWithName:@"Exo-Bold" size:20.0f]
     }];

    UIImage *navBarButton = [[UIImage imageNamed:@"ui_navbar_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    UIImage *navBarBack   = [[UIImage imageNamed:@"ui_navbar_back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 5)];
    [[UIBarButtonItem appearance] setBackgroundImage:navBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:navBarBack forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     @{
     UITextAttributeTextColor: [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],
     UITextAttributeTextShadowColor: [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f],
     UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)]//,
     // Causes a bug in iOS where image views get oddly stretched... or something.
     //UITextAttributeFont: [UIFont fontWithName:@"HelveticaNeue" size:13.0f]
     }
                                                forState:UIControlStateNormal];

    UIImage *toolBarImage = [[UIImage imageNamed:@"ui_toolbar_container"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 5, 5, 5)];
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
     [[UISegmentedControl appearance] setDividerImage:segUnselectedSelected forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
     */

    [[NSNotificationCenter defaultCenter] addObserverForName:MPNotificationSignedOut object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([[note.userInfo objectForKey:@"animated"] boolValue])
                                                          [self.navigationController performSegueWithIdentifier:@"MP_Unlock" sender:nil];
                                                      else
                                                          [self.navigationController presentViewController:[self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MPUnlockViewController"]
                                                                                                  animated:NO completion:nil];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:kIASKAppSettingChanged object:nil queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self checkConfig];
                                                  }];

#ifdef ADHOC
    [PearlAlert showAlertWithTitle:@"Welcome, tester!" message:
     @"Thank you for taking the time to test Master Password.\n\n"
     @"Please provide any feedback, however minor it may seem, via the Feedback action item accessible from the top right.\n\n"
     @"Contact me directly at:\n"
     @"lhunath@lyndir.com\n"
     @"Or report detailed issues at:\n"
     @"https://youtrack.lyndir.com\n"
                         viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                       cancelTitle:nil otherTitles:[PearlStrings get].commonButtonOkay, nil];
#endif

    [super application:application didFinishLaunchingWithOptions:launchOptions];

    inf(@"Started up with device identifier: %@", [PearlKeyChain deviceIdentifier]);

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    // No URL?
    if (!url)
        return NO;

    // Check if this is a Facebook login URL.
    if ([FBSession.activeSession handleOpenURL:url])
        return YES;

    // Arbitrary URL to mpsites data.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError       *error;
        NSURLResponse *response;
        NSData        *importedSitesData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
                                                                 returningResponse:&response error:&error];
        if (error)
        err(@"While reading imported sites from %@: %@", url, error);
        if (!importedSitesData)
            return;

        PearlAlert *activityAlert = [PearlAlert showActivityWithTitle:@"Importing"];

        NSString *importedSitesString = [[NSString alloc] initWithData:importedSitesData encoding:NSUTF8StringEncoding];
        MPImportResult result = [self importSites:importedSitesString askImportPassword:^NSString *(NSString *userName) {
            __block NSString *masterPassword = nil;

            dispatch_group_t importPasswordGroup = dispatch_group_create();
            dispatch_group_enter(importPasswordGroup);
            dispatch_async(dispatch_get_main_queue(), ^{
                [PearlAlert showAlertWithTitle:@"Import File's Master Password"
                                       message:PearlString(@"%@'s export was done using a different master password.\n"
                                                            @"Enter that master password to unlock the exported data.", userName)
                                     viewStyle:UIAlertViewStyleSecureTextInput
                                     initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                    @try {
                        if (buttonIndex_ == [alert_ cancelButtonIndex])
                            return;

                        masterPassword = [alert_ textFieldAtIndex:0].text;
                    }
                    @finally {
                        dispatch_group_leave(importPasswordGroup);
                    }
                }
                                   cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Unlock Import", nil];
            });
            dispatch_group_wait(importPasswordGroup, DISPATCH_TIME_FOREVER);

            return masterPassword;
        }                         askUserPassword:^NSString *(NSString *userName, NSUInteger importCount, NSUInteger deleteCount) {
            __block NSString *masterPassword = nil;

            dispatch_group_t userPasswordGroup = dispatch_group_create();
            dispatch_group_enter(userPasswordGroup);
            dispatch_async(dispatch_get_main_queue(), ^{
                [PearlAlert showAlertWithTitle:PearlString(@"Master Password for\n%@", userName)
                                       message:PearlString(@"Imports %d sites, overwriting %d.", importCount,
                                                           deleteCount)
                                     viewStyle:UIAlertViewStyleSecureTextInput
                                     initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                    @try {
                        if (buttonIndex_ == [alert_ cancelButtonIndex])
                            return;

                        masterPassword = [alert_ textFieldAtIndex:0].text;
                    }
                    @finally {
                        dispatch_group_leave(userPasswordGroup);
                    }
                }
                                   cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Import", nil];
            });
            dispatch_group_wait(userPasswordGroup, DISPATCH_TIME_FOREVER);

            return masterPassword;
        }];

        switch (result) {
            case MPImportResultSuccess:
            case MPImportResultCancelled:
                break;
            case MPImportResultInternalError:
                [PearlAlert showError:@"Import failed because of an internal error."];
                break;
            case MPImportResultMalformedInput:
                [PearlAlert showError:@"The import doesn't look like a Master Password export."];
                break;
            case MPImportResultInvalidPassword:
                [PearlAlert showError:@"Incorrect master password for the import sites."];
                break;
        }

        [activityAlert dismissAlert];
    });

    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {

    wrn(@"Received memory warning.");

    [super applicationDidReceiveMemoryWarning:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    inf(@"Re-activated");
    [[MPAppDelegate get] checkConfig];

    if (FBSession.activeSession.state == FBSessionStateCreatedOpening)
     // An old Facebook Login session that wasn't finished.  Clean it up.
        [FBSession.activeSession close];

    [super applicationDidBecomeActive:application];
}

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

    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];

    [FBSession.activeSession close];

    [super applicationWillTerminate:application];
}

- (void)applicationWillResignActive:(UIApplication *)application {

    inf(@"Will deactivate");
    [self saveContext];

    if (![[MPiOSConfig get].rememberLogin boolValue])
        [self signOutAnimated:NO];
}

#pragma mark - Behavior

- (void)checkConfig {

    if ([[MPConfig get].iCloud boolValue] != [self.storeManager iCloudEnabled])
        [self.storeManager useiCloudStore:[[MPConfig get].iCloud boolValue] alertUser:YES];
    if ([[MPiOSConfig get].sendInfo boolValue]) {
        if ([PearlLogger get].printLevel > PearlLogLevelInfo)
            [PearlLogger get].printLevel = PearlLogLevelInfo;

        [[Crashlytics sharedInstance] setBoolValue:[[MPConfig get].rememberLogin boolValue] forKey:@"rememberLogin"];
        [[Crashlytics sharedInstance] setBoolValue:[[MPConfig get].iCloud boolValue] forKey:@"iCloud"];
        [[Crashlytics sharedInstance] setBoolValue:[[MPConfig get].iCloudDecided boolValue] forKey:@"iCloudDecided"];
        [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].sendInfo boolValue] forKey:@"sendInfo"];
        [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].helpHidden boolValue] forKey:@"helpHidden"];
        [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].showQuickStart boolValue] forKey:@"showQuickStart"];
        [[Crashlytics sharedInstance] setBoolValue:[[PearlConfig get].firstRun boolValue] forKey:@"firstRun"];
        [[Crashlytics sharedInstance] setIntValue:[[PearlConfig get].launchCount intValue] forKey:@"launchCount"];
        [[Crashlytics sharedInstance] setBoolValue:[[PearlConfig get].askForReviews boolValue] forKey:@"askForReviews"];
        [[Crashlytics sharedInstance] setIntValue:[[PearlConfig get].reviewAfterLaunches intValue] forKey:@"reviewAfterLaunches"];
        [[Crashlytics sharedInstance] setObjectValue:[PearlConfig get].reviewedVersion forKey:@"reviewedVersion"];

        [TestFlight addCustomEnvironmentInformation:[[MPConfig get].rememberLogin boolValue]? @"YES": @"NO" forKey:@"rememberLogin"];
        [TestFlight addCustomEnvironmentInformation:[[MPConfig get].iCloud boolValue]? @"YES": @"NO" forKey:@"iCloud"];
        [TestFlight addCustomEnvironmentInformation:[[MPConfig get].iCloudDecided boolValue]? @"YES": @"NO" forKey:@"iCloudDecided"];
        [TestFlight addCustomEnvironmentInformation:[[MPiOSConfig get].sendInfo boolValue]? @"YES": @"NO" forKey:@"sendInfo"];
        [TestFlight addCustomEnvironmentInformation:[[MPiOSConfig get].helpHidden boolValue]? @"YES": @"NO" forKey:@"helpHidden"];
        [TestFlight addCustomEnvironmentInformation:[[MPiOSConfig get].showQuickStart boolValue]? @"YES": @"NO" forKey:@"showQuickStart"];
        [TestFlight addCustomEnvironmentInformation:[[PearlConfig get].firstRun boolValue]? @"YES": @"NO" forKey:@"firstRun"];
        [TestFlight addCustomEnvironmentInformation:[[PearlConfig get].launchCount description] forKey:@"launchCount"];
        [TestFlight addCustomEnvironmentInformation:[[PearlConfig get].askForReviews boolValue]? @"YES": @"NO" forKey:@"askForReviews"];
        [TestFlight addCustomEnvironmentInformation:[[PearlConfig get].reviewAfterLaunches description] forKey:@"reviewAfterLaunches"];
        [TestFlight addCustomEnvironmentInformation:[PearlConfig get].reviewedVersion forKey:@"reviewedVersion"];

        [TestFlight passCheckpoint:MPCheckpointConfig];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointConfig attributes:
                                                                                  @{
                                                                                  @"rememberLogin": [[MPConfig get].rememberLogin boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"iCloud": [[MPConfig get].iCloud boolValue]? @"YES"
                                                                                   : @"NO",
                                                                                  @"iCloudDecided": [[MPConfig get].iCloudDecided boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"sendInfo": [[MPiOSConfig get].sendInfo boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"helpHidden": [[MPiOSConfig get].helpHidden boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"showQuickStart": [[MPiOSConfig get].showQuickStart boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"firstRun": [[PearlConfig get].firstRun boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"launchCount": [[PearlConfig get].launchCount description],
                                                                                  @"askForReviews": [[PearlConfig get].askForReviews boolValue]
                                                                                   ? @"YES": @"NO",
                                                                                  @"reviewAfterLaunches": [[PearlConfig get].reviewAfterLaunches description],
                                                                                  @"reviewedVersion": [PearlConfig get].reviewedVersion
                                                                                  }];
    }
}

- (void)showGuide {

    [self.navigationController performSegueWithIdentifier:@"MP_Guide" sender:self];

    [TestFlight passCheckpoint:MPCheckpointShowGuide];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointShowGuide attributes:nil];
}

- (void)showFeedback {

    [self showFeedbackWithLogs:NO forVC:nil];
}

- (void)showReview {

    [TestFlight passCheckpoint:MPCheckpointReview];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointReview attributes:nil];

    [super showReview];
}

- (void)showFeedbackWithLogs:(BOOL)logs forVC:(UIViewController *)viewController {

    if (![PearlEMail canSendMail])
        [PearlAlert showAlertWithTitle:@"Feedback"
                               message:
                                @"Have a question, comment, issue or just saying thanks?\n\n"
                                 @"We'd love to hear what you think!\n"
                                 @"masterpassword@lyndir.com"
                             viewStyle:UIAlertViewStyleDefault
                             initAlert:nil tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay
                           otherTitles:nil];

    else
        if (logs)
            [PearlAlert showAlertWithTitle:@"Feedback"
                                   message:
                                    @"Have a question, comment, issue or just saying thanks?\n\n"
                                     @"If you're having trouble, it may help us if you can first reproduce the problem "
                                     @"and then include log files in your message."
                                 viewStyle:UIAlertViewStyleDefault
                                 initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                [self openFeedbackWithLogs:(buttonIndex_ == [alert_ firstOtherButtonIndex]) forVC:viewController];
            }                  cancelTitle:nil otherTitles:@"Include Logs", @"No Logs", nil];
        else
            [self openFeedbackWithLogs:NO forVC:viewController];
}

- (void)openFeedbackWithLogs:(BOOL)logs forVC:(UIViewController *)viewController {

    NSString *userName = [MPAppDelegate get].activeUser.name;
    PearlLogLevel logLevel = [[MPiOSConfig get].sendInfo boolValue]? PearlLogLevelDebug: PearlLogLevelInfo;

    [[[PearlEMail alloc] initForEMailTo:@"Master Password Development <masterpassword@lyndir.com>"
                                subject:PearlString(@"Feedback for Master Password [%@]",
                                                    [[PearlKeyChain deviceIdentifier] stringByDeletingMatchesOf:@"-.*"])
                                   body:PearlString(@"\n\n\n"
                                                     @"--\n"
                                                     @"%@"
                                                     @"Master Password %@, build %@",
                                                    userName? ([userName stringByAppendingString:@"\n"]): @"",
                                                    [PearlInfoPlist get].CFBundleShortVersionString,
                                                    [PearlInfoPlist get].CFBundleVersion)

                            attachments:logs
                                         ? [[PearlEMailAttachment alloc] initWithContent:[[[PearlLogger get] formatMessagesWithLevel:logLevel] dataUsingEncoding:NSUTF8StringEncoding]
                                                                                mimeType:@"text/plain"
                                                                                fileName:PearlString(@"%@-%@.log",
                                                                                                     [[NSDateFormatter rfc3339DateFormatter] stringFromDate:[NSDate date]],
                                                                                                     [PearlKeyChain deviceIdentifier])]
                                         : nil, nil]
                  showComposerForVC:viewController];
}

- (void)export {

    [PearlAlert showNotice:
                 @"This will export all your site names.\n\n"
                  @"You can open the export with a text editor to get an overview of all your sites.\n\n"
                  @"The file also acts as a personal backup of your site list in case you don't sync with iCloud/iTunes."
         tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
             [PearlAlert showAlertWithTitle:@"Reveal Passwords?" message:
                                                                  @"Would you like to make all your passwords visible in the export?\n\n"
                                                                   @"A safe export will only include your stored passwords, in an encrypted manner, "
                                                                   @"making the result safe from falling in the wrong hands.\n\n"
                                                                   @"If all your passwords are shown and somebody else finds the export, "
                                                                   @"they could gain access to all your sites!"
                                  viewStyle:UIAlertViewStyleDefault initAlert:nil
                          tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                              if (buttonIndex_ == [alert_ firstOtherButtonIndex] + 0)
                               // Safe Export
                                  [self exportShowPasswords:NO];
                              if (buttonIndex_ == [alert_ firstOtherButtonIndex] + 1)
                               // Show Passwords
                                  [self exportShowPasswords:YES];
                          }     cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Safe Export", @"Show Passwords", nil];
         }     otherTitles:nil];
}

- (void)exportShowPasswords:(BOOL)showPasswords {

    if (![PearlEMail canSendMail]) {
        [PearlAlert showAlertWithTitle:@"Cannot Send Mail"
                               message:
                                @"Your device is not yet set up for sending mail.\n"
                                 @"Close Master Password, go into Settings and add a Mail account."
                             viewStyle:UIAlertViewStyleDefault
                             initAlert:nil tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay
                           otherTitles:nil];
        return;
    }

    NSString *exportedSites = [self exportSitesShowingPasswords:showPasswords];
    NSString *message;

    if (showPasswords)
        message = PearlString(@"Export of Master Password sites with passwords included.\n"
                               @"REMINDER: Make sure nobody else sees this file!  Passwords are visible!\n\n\n"
                               @"--\n"
                               @"%@\n"
                               @"Master Password %@, build %@",
                              self.activeUser.name,
                              [PearlInfoPlist get].CFBundleShortVersionString,
                              [PearlInfoPlist get].CFBundleVersion);
    else
        message = PearlString(@"Backup of Master Password sites.\n\n\n"
                               @"--\n"
                               @"%@\n"
                               @"Master Password %@, build %@",
                              self.activeUser.name,
                              [PearlInfoPlist get].CFBundleShortVersionString,
                              [PearlInfoPlist get].CFBundleVersion);

    NSDateFormatter *exportDateFormatter = [NSDateFormatter new];
    [exportDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];

    [PearlEMail sendEMailTo:nil subject:@"Master Password Export" body:message
                attachments:[[PearlEMailAttachment alloc] initWithContent:[exportedSites dataUsingEncoding:NSUTF8StringEncoding]
                                                                 mimeType:@"text/plain" fileName:
                  PearlString(@"%@ (%@).mpsites", self.activeUser.name, [exportDateFormatter stringFromDate:[NSDate date]])],
                            nil];
}

- (void)changeMasterPasswordFor:(MPUserEntity *)user didResetBlock:(void (^)(void))didReset {

    [PearlAlert showAlertWithTitle:@"Changing Master Password"
                           message:
                            @"If you continue, you'll be able to set a new master password.\n\n"
                             @"Changing your master password will cause all your generated passwords to change!\n"
                             @"Changing the master password back to the old one will cause your passwords to revert as well."
                         viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        inf(@"Unsetting master password for: %@.", user.userID);
        user.keyID = nil;
        [self forgetSavedKeyFor:user];
        [self signOutAnimated:YES];

        if (didReset)
            didReset();

        [TestFlight passCheckpoint:MPCheckpointChangeMP];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointChangeMP attributes:nil];
    }
                       cancelTitle:[PearlStrings get].commonButtonAbort
                       otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

#pragma mark - PearlConfigDelegate

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)value {

    [self checkConfig];
}

#pragma mark - UbiquityStoreManagerDelegate

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didSwitchToiCloud:(BOOL)iCloudEnabled {

    [super ubiquityStoreManager:manager didSwitchToiCloud:iCloudEnabled];

    if (![[MPConfig get].iCloudDecided boolValue]) {
        if (!iCloudEnabled) {
            [PearlAlert showAlertWithTitle:@"iCloud"
                                   message:
                                    @"iCloud is now disabled.\n\n"
                                     @"It is highly recommended you enable iCloud."
                                 viewStyle:UIAlertViewStyleDefault initAlert:nil
                         tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                             if (buttonIndex == [alert firstOtherButtonIndex] + 0) {
                                 [PearlAlert showAlertWithTitle:@"About iCloud"
                                                        message:
                                                         @"iCloud is Apple's solution for saving your data in \"the cloud\" "
                                                          @"and making sure your other iPhones, iPads and Macs are in sync.\n\n"
                                                          @"For Master Password, that means your sites are available on all your "
                                                          @"Apple devices, and you always have a backup of them in case "
                                                          @"you loose one or need to restore.\n\n"
                                                          @"Because of the way Master Password works, it doesn't need to send your "
                                                          @"site's passwords to Apple.  Only their names are saved to make it easier "
                                                          @"for you to find the site you need.  For some sites you may have set "
                                                          @"a user-specified password: these are sent to iCloud after being encrypted "
                                                          @"with your master password.\n\n"
                                                          @"Apple can never see any of your passwords."
                                                      viewStyle:UIAlertViewStyleDefault
                                                      initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                                     [self ubiquityStoreManager:manager didSwitchToiCloud:iCloudEnabled];
                                 }
                                                    cancelTitle:[PearlStrings get].commonButtonThanks otherTitles:nil];
                                 return;
                             }

                             [MPConfig get].iCloudDecided = @YES;
                             if (buttonIndex == [alert cancelButtonIndex])
                                 return;
                             if (buttonIndex == [alert firstOtherButtonIndex] + 1)
                                 [manager useiCloudStore:YES alertUser:NO];
                         }     cancelTitle:@"Leave iCloud Off" otherTitles:@"Explain?", @"Enable iCloud", nil];
        }
    }
}

#pragma mark - TestFlight


- (NSDictionary *)testFlightInfo {

    static NSDictionary *testFlightInfo = nil;
    if (testFlightInfo == nil)
        testFlightInfo = [[NSDictionary alloc] initWithContentsOfURL:
         [[NSBundle mainBundle] URLForResource:@"TestFlight" withExtension:@"plist"]];

    return testFlightInfo;
}

- (NSString *)testFlightToken {

    return NSNullToNil([[self testFlightInfo] valueForKeyPath:@"Team Token"]);
}


#pragma mark - Crashlytics


- (NSDictionary *)crashlyticsInfo {

    static NSDictionary *crashlyticsInfo = nil;
    if (crashlyticsInfo == nil)
        crashlyticsInfo = [[NSDictionary alloc] initWithContentsOfURL:
         [[NSBundle mainBundle] URLForResource:@"Crashlytics" withExtension:@"plist"]];

    return crashlyticsInfo;
}

- (NSString *)crashlyticsAPIKey {

    return NSNullToNil([[self crashlyticsInfo] valueForKeyPath:@"API Key"]);
}


#pragma mark - Localytics


- (NSDictionary *)localyticsInfo {

    static NSDictionary *localyticsInfo = nil;
    if (localyticsInfo == nil)
        localyticsInfo = [[NSDictionary alloc] initWithContentsOfURL:
         [[NSBundle mainBundle] URLForResource:@"Localytics" withExtension:@"plist"]];

    return localyticsInfo;
}

- (NSString *)localyticsKey {

#ifdef DEBUG
    return NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.development"]);
#else
    return NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.distribution"]);
#endif
}

@end
