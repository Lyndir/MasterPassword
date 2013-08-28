//
//  MPiOSAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "IASKSettingsReader.h"
#import <GooglePlus/GPPSignIn.h>

@interface MPiOSAppDelegate()

@property(nonatomic, strong) PearlAlert *handleCloudContentAlert;
@property(nonatomic, strong) PearlAlert *fixCloudContentAlert;
@property(nonatomic, strong) PearlOverlay *storeLoading;
@end

@implementation MPiOSAppDelegate

+ (void)initialize {

    [MPiOSConfig get];
    [PearlLogger get].historyLevel = [[MPiOSConfig get].traceMode boolValue]? PearlLogLevelTrace: PearlLogLevelInfo;
#ifdef DEBUG
    [PearlLogger get].printLevel = PearlLogLevelDebug;
    //[NSClassFromString(@"WebView") performSelector:NSSelectorFromString(@"_enableRemoteInspector")];
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[[NSBundle mainBundle] mutableInfoDictionary] setObject:@"Master Password" forKey:@"CFBundleDisplayName"];
    [[[NSBundle mainBundle] mutableLocalizedInfoDictionary] setObject:@"Master Password" forKey:@"CFBundleDisplayName"];

#ifdef TESTFLIGHT_SDK_VERSION
    @try {
        NSString *testFlightToken = [self testFlightToken];
        if ([testFlightToken length]) {
            inf(@"Initializing TestFlight");
            [TestFlight addCustomEnvironmentInformation:@"Anonymous" forKey:@"username"];
            [TestFlight addCustomEnvironmentInformation:[PearlKeyChain deviceIdentifier] forKey:@"deviceIdentifier"];
            [TestFlight setOptions:@{
                    @"logToConsole" : @NO,
                    @"logToSTDERR"  : @NO
            }];
            [TestFlight takeOff:testFlightToken];
            [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                PearlLogLevel level = PearlLogLevelWarn;
                if ([[MPiOSConfig get].sendInfo boolValue])
                    level = PearlLogLevelInfo;

                if (message.level >= level)
                    TFLog( @"%@", [message messageDescription] );

                return YES;
            }];
            TFLog( @"TestFlight (%@) initialized for: %@ v%@.", //
                    TESTFLIGHT_SDK_VERSION, [PearlInfoPlist get].CFBundleName, [PearlInfoPlist get].CFBundleVersion );
        }
    }
    @catch (id exception) {
        err(@"TestFlight: %@", exception);
    }
#endif
    @try {
        NSString *googlePlusClientID = [self googlePlusClientID];
        if ([googlePlusClientID length]) {
            inf(@"Initializing Google+");
            [[GPPSignIn sharedInstance] setClientID:googlePlusClientID];
        }
    }
    @catch (id exception) {
        err(@"Google+: %@", exception);
    }
#ifdef CRASHLYTICS
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
                    CLSLog( @"%@", [message messageDescription] );

                return YES;
            }];
            CLSLog( @"Crashlytics (%@) initialized for: %@ v%@.", //
                    [Crashlytics sharedInstance].version, [PearlInfoPlist get].CFBundleName, [PearlInfoPlist get].CFBundleVersion );
        }
    }
    @catch (id exception) {
        err(@"Crashlytics: %@", exception);
    }
#endif
#ifdef LOCALYTICS
    @try {
        NSString *localyticsKey = [self localyticsKey];
        if ([localyticsKey length]) {
            inf(@"Initializing Localytics");
            [[LocalyticsSession sharedLocalyticsSession] LocalyticsSession:localyticsKey];
            [[LocalyticsSession sharedLocalyticsSession] open];
            [LocalyticsSession sharedLocalyticsSession].enableHTTPS = YES;
            [[LocalyticsSession sharedLocalyticsSession] setCustomerId:[PearlKeyChain deviceIdentifier]];
            [[LocalyticsSession sharedLocalyticsSession] setCustomerName:@"Anonymous"];
            [[LocalyticsSession sharedLocalyticsSession] upload];
            [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
                if (message.level >= PearlLogLevelWarn)
                    MPCheckpoint( @"Problem", @{
                            @"level"   : @(PearlLogLevelStr( message.level )),
                            @"message" : NilToNSNull(message.message)
                    } );

                return YES;
            }];
        }
    }
    @catch (id exception) {
        err(@"Localytics exception: %@", exception);
    }
#endif

    UIImage *navBarImage = [[UIImage imageNamed:@"ui_navbar_container"] resizableImageWithCapInsets:UIEdgeInsetsMake( 0, 5, 0, 5 )];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:
            @{
                    UITextAttributeTextColor        : [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],
                    UITextAttributeTextShadowColor  : [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.8f],
                    UITextAttributeTextShadowOffset : [NSValue valueWithUIOffset:UIOffsetMake( 0, -1 )],
                    UITextAttributeFont             : [UIFont fontWithName:@"Exo-Bold" size:20.0f]
            }];

    UIImage *navBarButton = [[UIImage imageNamed:@"ui_navbar_button"] resizableImageWithCapInsets:UIEdgeInsetsMake( 0, 5, 0, 5 )];
    UIImage *navBarBack = [[UIImage imageNamed:@"ui_navbar_back"] resizableImageWithCapInsets:UIEdgeInsetsMake( 0, 13, 0, 5 )];
    [[UIBarButtonItem appearance] setBackgroundImage:navBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:navBarBack forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setTitleTextAttributes:
            @{
                    UITextAttributeTextColor        : [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f],
                    UITextAttributeTextShadowColor  : [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.5f],
                    UITextAttributeTextShadowOffset : [NSValue valueWithUIOffset:UIOffsetMake( 0, 1 )]//,
                    // Causes a bug in iOS where image views get oddly stretched... or something.
                    //UITextAttributeFont: [UIFont fontWithName:@"HelveticaNeue" size:13.0f]
            }
                                                forState:UIControlStateNormal];

    UIImage *toolBarImage = [[UIImage imageNamed:@"ui_toolbar_container"] resizableImageWithCapInsets:UIEdgeInsetsMake( 25, 5, 5, 5 )];
    [[UISearchBar appearance] setBackgroundImage:toolBarImage];
    [[UIToolbar appearance] setBackgroundImage:toolBarImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

    // UIImage *minImage = [[UIImage imageNamed:@"slider-minimum"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    // UIImage *maxImage = [[UIImage imageNamed:@"slider-maximum"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    // UIImage *thumbImage = [UIImage imageNamed:@"slider-handle"];
    //
    // [[UISlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    // [[UISlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
    // [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
    //
    // UIImage *segmentSelected = [[UIImage imageNamed:@"segcontrol_sel"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
    // UIImage *segmentUnselected = [[UIImage imageNamed:@"segcontrol_uns"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 15, 0, 15)];
    // UIImage *segmentSelectedUnselected = [UIImage imageNamed:@"segcontrol_sel-uns"];
    // UIImage *segUnselectedSelected = [UIImage imageNamed:@"segcontrol_uns-sel"];
    // UIImage *segmentUnselectedUnselected = [UIImage imageNamed:@"segcontrol_uns-uns"];
    //
    // [[UISegmentedControl appearance] setBackgroundImage:segmentUnselected forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    // [[UISegmentedControl appearance] setBackgroundImage:segmentSelected forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    //
    // [[UISegmentedControl appearance] setDividerImage:segmentUnselectedUnselected forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    // [[UISegmentedControl appearance] setDividerImage:segmentSelectedUnselected forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    // [[UISegmentedControl appearance] setDividerImage:segUnselectedSelected forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];

    [[NSNotificationCenter defaultCenter] addObserverForName:MPCheckConfigNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                if ([[MPiOSConfig get].sendInfo boolValue]) {
                    if ([PearlLogger get].printLevel > PearlLogLevelInfo)
                        [PearlLogger get].printLevel = PearlLogLevelInfo;

#ifdef CRASHLYTICS
                    [[Crashlytics sharedInstance] setBoolValue:[[MPConfig get].rememberLogin boolValue] forKey:@"rememberLogin"];
                    [[Crashlytics sharedInstance] setBoolValue:[self storeManager].cloudEnabled forKey:@"iCloud"];
                    [[Crashlytics sharedInstance] setBoolValue:[[MPConfig get].iCloudDecided boolValue] forKey:@"iCloudDecided"];
                    [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].sendInfo boolValue] forKey:@"sendInfo"];
                    [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].helpHidden boolValue] forKey:@"helpHidden"];
                    [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].showSetup boolValue] forKey:@"showQuickStart"];
                    [[Crashlytics sharedInstance] setBoolValue:[[PearlConfig get].firstRun boolValue] forKey:@"firstRun"];
                    [[Crashlytics sharedInstance] setIntValue:[[PearlConfig get].launchCount intValue] forKey:@"launchCount"];
                    [[Crashlytics sharedInstance] setBoolValue:[[PearlConfig get].askForReviews boolValue] forKey:@"askForReviews"];
                    [[Crashlytics sharedInstance]
                            setIntValue:[[PearlConfig get].reviewAfterLaunches intValue] forKey:@"reviewAfterLaunches"];
                    [[Crashlytics sharedInstance] setObjectValue:[PearlConfig get].reviewedVersion forKey:@"reviewedVersion"];
#endif

#ifdef TESTFLIGHT_SDK_VERSION
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [MPConfig get].rememberLogin )
                                                         forKey:@"rememberLogin"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringB( [self storeManager].cloudEnabled )
                                                         forKey:@"iCloud"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [MPConfig get].iCloudDecided )
                                                         forKey:@"iCloudDecided"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [MPiOSConfig get].sendInfo )
                                                         forKey:@"sendInfo"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [MPiOSConfig get].helpHidden )
                                                         forKey:@"helpHidden"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [MPiOSConfig get].showSetup )
                                                         forKey:@"showQuickStart"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [PearlConfig get].firstRun )
                                                         forKey:@"firstRun"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [PearlConfig get].launchCount )
                                                         forKey:@"launchCount"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [PearlConfig get].askForReviews )
                                                         forKey:@"askForReviews"];
                    [TestFlight addCustomEnvironmentInformation:PearlStringNSB( [PearlConfig get].reviewAfterLaunches )
                                                         forKey:@"reviewAfterLaunches"];
                    [TestFlight addCustomEnvironmentInformation:[PearlConfig get].reviewedVersion
                                                         forKey:@"reviewedVersion"];
#endif
                    MPCheckpoint( MPCheckpointConfig, @{
                            @"rememberLogin"       : @([[MPConfig get].rememberLogin boolValue]),
                            @"iCloud"              : @([self storeManager].cloudEnabled),
                            @"iCloudDecided"       : @([[MPConfig get].iCloudDecided boolValue]),
                            @"sendInfo"            : @([[MPiOSConfig get].sendInfo boolValue]),
                            @"helpHidden"          : @([[MPiOSConfig get].helpHidden boolValue]),
                            @"showQuickStart"      : @([[MPiOSConfig get].showSetup boolValue]),
                            @"firstRun"            : @([[PearlConfig get].firstRun boolValue]),
                            @"launchCount"         : NilToNSNull([PearlConfig get].launchCount),
                            @"askForReviews"       : @([[PearlConfig get].askForReviews boolValue]),
                            @"reviewAfterLaunches" : NilToNSNull([PearlConfig get].reviewAfterLaunches),
                            @"reviewedVersion"     : NilToNSNull([PearlConfig get].reviewedVersion)
                    } );
                }
            }];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:kIASKAppSettingChanged object:nil queue:nil usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:note userInfo:nil];
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

    dispatch_async( dispatch_get_main_queue(), ^{
        if ([[MPiOSConfig get].showSetup boolValue])
            [[MPiOSAppDelegate get] showSetup];
    } );

    MPCheckpoint( MPCheckpointStarted, @{
            @"simulator"  : PearlStringB( [PearlDeviceUtils isSimulator] ),
            @"encrypted"  : PearlStringB( [PearlDeviceUtils isAppEncrypted] ),
            @"jailbroken" : PearlStringB( [PearlDeviceUtils isJailbroken] ),
            @"platform"   : [PearlDeviceUtils platform],
#ifdef APPSTORE
            @"legal" : PearlStringB([PearlDeviceUtils isAppEncrypted]),
#else
            @"legal"      : @"YES",
#endif
    } );

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    // No URL?
    if (!url)
        return NO;

    // Google+
    if ([[GPPSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation])
        return YES;

    // Arbitrary URL to mpsites data.
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        NSError *error;
        NSURLResponse *response;
        NSData *importedSitesData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
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
            dispatch_group_enter( importPasswordGroup );
            dispatch_async( dispatch_get_main_queue(), ^{
                [PearlAlert showAlertWithTitle:@"Import File's Master Password"
                                       message:PearlString( @"%@'s export was done using a different master password.\n"
                                               @"Enter that master password to unlock the exported data.", userName )
                                     viewStyle:UIAlertViewStyleSecureTextInput
                                     initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                    @try {
                        if (buttonIndex_ == [alert_ cancelButtonIndex])
                            return;

                        masterPassword = [alert_ textFieldAtIndex:0].text;
                    }
                    @finally {
                        dispatch_group_leave( importPasswordGroup );
                    }
                }
                                   cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Unlock Import", nil];
            } );
            dispatch_group_wait( importPasswordGroup, DISPATCH_TIME_FOREVER );

            return masterPassword;
        }                         askUserPassword:^NSString *(NSString *userName, NSUInteger importCount, NSUInteger deleteCount) {
            __block NSString *masterPassword = nil;

            dispatch_group_t userPasswordGroup = dispatch_group_create();
            dispatch_group_enter( userPasswordGroup );
            dispatch_async( dispatch_get_main_queue(), ^{
                [PearlAlert showAlertWithTitle:PearlString( @"Master Password for\n%@", userName )
                                       message:PearlString( @"Imports %d sites, overwriting %d.", importCount,
                                               deleteCount )
                                     viewStyle:UIAlertViewStyleSecureTextInput
                                     initAlert:nil tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                    @try {
                        if (buttonIndex_ == [alert_ cancelButtonIndex])
                            return;

                        masterPassword = [alert_ textFieldAtIndex:0].text;
                    }
                    @finally {
                        dispatch_group_leave( userPasswordGroup );
                    }
                }
                                   cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Import", nil];
            } );
            dispatch_group_wait( userPasswordGroup, DISPATCH_TIME_FOREVER );

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

        [activityAlert cancelAlertAnimated:YES];
    } );

    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {

    inf(@"Received memory warning.");

    [super applicationDidReceiveMemoryWarning:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {

#ifdef LOCALYTICS
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif

    [super applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {

#ifdef LOCALYTICS
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif

    [super applicationWillEnterForeground:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {

#ifdef LOCALYTICS
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif

    [super applicationWillTerminate:application];
}

- (void)applicationWillResignActive:(UIApplication *)application {

    inf(@"Will deactivate");
    if (![[MPiOSConfig get].rememberLogin boolValue])
        [self signOutAnimated:NO];

#ifdef LOCALYTICS
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif

    [super applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    inf(@"Re-activated");
    [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:application userInfo:nil];

#ifdef LOCALYTICS
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
#endif

    [super applicationDidBecomeActive:application];
}

#pragma mark - Behavior

- (void)showGuide {

    [self.navigationController performSegueWithIdentifier:@"MP_Guide" sender:self];

    MPCheckpoint( MPCheckpointShowGuide, nil );
}

- (void)showSetup {

    [self.navigationController performSegueWithIdentifier:@"MP_Setup" sender:self];

    MPCheckpoint( MPCheckpointShowSetup, nil );
}

- (void)showReview {

    MPCheckpoint( MPCheckpointReview, nil );

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

    else if (logs)
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

    NSString *userName = [[MPiOSAppDelegate get] activeUserForMainThread].name;
    PearlLogLevel logLevel = PearlLogLevelInfo;
    if (logs && ([[MPiOSConfig get].sendInfo boolValue] || [[MPiOSConfig get].traceMode boolValue]))
        logLevel = PearlLogLevelDebug;

    [[[PearlEMail alloc] initForEMailTo:@"Master Password Development <masterpassword@lyndir.com>"
                                subject:PearlString( @"Feedback for Master Password [%@]",
                                        [[PearlKeyChain deviceIdentifier] stringByDeletingMatchesOf:@"-.*"] )
                                   body:PearlString( @"\n\n\n"
                                           @"--\n"
                                           @"%@"
                                           @"Master Password %@, build %@",
                                           userName? ([userName stringByAppendingString:@"\n"]): @"",
                                           [PearlInfoPlist get].CFBundleShortVersionString,
                                           [PearlInfoPlist get].CFBundleVersion )

                            attachments:(logs
                                         ? [[PearlEMailAttachment alloc]
                                            initWithContent:[[[PearlLogger get] formatMessagesWithLevel:logLevel]
                                                    dataUsingEncoding:NSUTF8StringEncoding]
                                                   mimeType:@"text/plain"
                                                   fileName:PearlString( @"%@-%@.log",
                                                           [[NSDateFormatter rfc3339DateFormatter] stringFromDate:[NSDate date]],
                                                           [PearlKeyChain deviceIdentifier] )]
                                         : nil), nil]
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
        message = PearlString( @"Export of Master Password sites with passwords included.\n\n"
                @"REMINDER: Make sure nobody else sees this file!  Passwords are visible!\n\n\n"
                @"--\n"
                @"%@\n"
                @"Master Password %@, build %@",
                [self activeUserForMainThread].name,
                [PearlInfoPlist get].CFBundleShortVersionString,
                [PearlInfoPlist get].CFBundleVersion );
    else
        message = PearlString( @"Backup of Master Password sites.\n\n\n"
                @"--\n"
                @"%@\n"
                @"Master Password %@, build %@",
                [self activeUserForMainThread].name,
                [PearlInfoPlist get].CFBundleShortVersionString,
                [PearlInfoPlist get].CFBundleVersion );

    NSDateFormatter *exportDateFormatter = [NSDateFormatter new];
    [exportDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];

    [PearlEMail sendEMailTo:nil subject:@"Master Password Export" body:message
                attachments:[[PearlEMailAttachment alloc] initWithContent:[exportedSites dataUsingEncoding:NSUTF8StringEncoding]
                                                                 mimeType:@"text/plain" fileName:
                                PearlString( @"%@ (%@).mpsites", [self activeUserForMainThread].name,
                                        [exportDateFormatter stringFromDate:[NSDate date]] )],
                            nil];
}

- (void)changeMasterPasswordFor:(MPUserEntity *)user saveInContext:(NSManagedObjectContext *)moc didResetBlock:(void (^)(void))didReset {

    [PearlAlert showAlertWithTitle:@"Changing Master Password"
                           message:
                                   @"If you continue, you'll be able to set a new master password.\n\n"
                                           @"Changing your master password will cause all your generated passwords to change!\n"
                                           @"Changing the master password back to the old one will cause your passwords to revert as well."
                         viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [moc performBlockAndWait:^{
            inf(@"Unsetting master password for: %@.", user.userID);
            user.keyID = nil;
            [self forgetSavedKeyFor:user];
            [moc saveToStore];
        }];

        [self signOutAnimated:YES];
        if (didReset)
            didReset();

        MPCheckpoint( MPCheckpointChangeMP, nil );
    }
                       cancelTitle:[PearlStrings get].commonButtonAbort
                       otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

#pragma mark - PearlConfigDelegate

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)value {

    if (configKey == @selector(traceMode)) {
        [PearlLogger get].historyLevel = [[MPiOSConfig get].traceMode boolValue]? PearlLogLevelTrace: PearlLogLevelInfo;
        inf(@"Trace is now: %@", [[MPiOSConfig get].traceMode boolValue]? @"ON": @"OFF");
    }

    [[NSNotificationCenter defaultCenter]
            postNotificationName:MPCheckConfigNotification object:NSStringFromSelector( configKey ) userInfo:nil];
}


#pragma mark - UbiquityStoreManager

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager willLoadStoreIsCloud:(BOOL)isCloudStore {

    dispatch_async( dispatch_get_main_queue(), ^{
        [self.handleCloudContentAlert cancelAlertAnimated:YES];
        if (![self.storeLoading isVisible])
            self.storeLoading = [PearlOverlay showOverlayWithTitle:@"Loading Sites"];
    } );

    [super ubiquityStoreManager:manager willLoadStoreIsCloud:isCloudStore];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didLoadStoreForCoordinator:(NSPersistentStoreCoordinator *)coordinator
                     isCloud:(BOOL)isCloudStore {

    [super ubiquityStoreManager:manager didLoadStoreForCoordinator:coordinator isCloud:isCloudStore];

    dispatch_async( dispatch_get_main_queue(), ^{
        [self.handleCloudContentAlert cancelAlertAnimated:YES];
        [self.fixCloudContentAlert cancelAlertAnimated:YES];
        [self.storeLoading cancelOverlayAnimated:YES];
    } );
}

- (BOOL)ubiquityStoreManager:(UbiquityStoreManager *)manager handleCloudContentCorruptionWithHealthyStore:(BOOL)storeHealthy {

    if (manager.cloudEnabled && !storeHealthy && !([self.handleCloudContentAlert.alertView isVisible] || [self.fixCloudContentAlert.alertView isVisible]))
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.storeLoading cancelOverlayAnimated:YES];
            [self showCloudContentAlert];
        } );

    return NO;
}

- (void)showCloudContentAlert {

    __weak MPiOSAppDelegate *wSelf = self;
    [self.handleCloudContentAlert cancelAlertAnimated:NO];
    self.handleCloudContentAlert = [PearlAlert showActivityWithTitle:@"iCloud Sync Problem" message:
            @"Waiting for your other device to auto‑correct the problem..."
                                                           initAlert:^(UIAlertView *alert) {
                                                               [alert addButtonWithTitle:@"Fix Now"];
                                                           }];

    self.handleCloudContentAlert.tappedButtonBlock = ^(UIAlertView *alert, NSInteger buttonIndex) {
        wSelf.fixCloudContentAlert = [PearlAlert showAlertWithTitle:@"Fix iCloud Now" message:
                @"This problem can be auto‑corrected by opening the app on another device where you recently made changes.\n"
                        @"You can correct the problem from this device anyway, but recent changes made on another device might get lost.\n\n"
                        @"You can also turn iCloud off and go back to your local sites."
                                                          viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:
                        ^(UIAlertView *alert_, NSInteger buttonIndex_) {
                            if (buttonIndex_ == alert_.cancelButtonIndex)
                                [wSelf showCloudContentAlert];
                            if (buttonIndex_ == [alert_ firstOtherButtonIndex])
                                [wSelf.storeManager rebuildCloudContentFromCloudStoreOrLocalStore:YES];
                            if (buttonIndex_ == [alert_ firstOtherButtonIndex] + 1)
                                wSelf.storeManager.cloudEnabled = NO;
                        }
                                                        cancelTitle:[PearlStrings get].commonButtonBack otherTitles:@"Fix Anyway",
                                                                                                                    @"Turn Off", nil];
    };
}


#pragma mark - Google+

- (NSDictionary *)googlePlusInfo {

    static NSDictionary *googlePlusInfo = nil;
    if (googlePlusInfo == nil)
        googlePlusInfo = [[NSDictionary alloc] initWithContentsOfURL:
                [[NSBundle mainBundle] URLForResource:@"Google+" withExtension:@"plist"]];

    return googlePlusInfo;
}

- (NSString *)googlePlusClientID {

    NSString *googlePlusClientID = NSNullToNil([[self googlePlusInfo] valueForKeyPath:@"ClientID"]);
    if (![googlePlusClientID length])
    wrn(@"Google+ client ID not set.  User won't be able to share via Google+.");

    return googlePlusClientID;
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

    NSString *testFlightToken = NSNullToNil([[self testFlightInfo] valueForKeyPath:@"Application Token"]);
    if (![testFlightToken length])
    wrn(@"TestFlight token not set.  Test Flight won't be aware of this test.");

    return testFlightToken;
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

    NSString *crashlyticsAPIKey = NSNullToNil([[self crashlyticsInfo] valueForKeyPath:@"API Key"]);
    if (![crashlyticsAPIKey length])
    wrn(@"Crashlytics API key not set.  Crash logs won't be recorded.");

    return crashlyticsAPIKey;
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
    NSString *localyticsKey = NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.development"]);
#else
    NSString *localyticsKey = NSNullToNil([[self localyticsInfo] valueForKeyPath:@"Key.distribution"]);
#endif
    if (![localyticsKey length])
    wrn(@"Localytics key not set.  Demographics won't be collected.");

    return localyticsKey;
}

@end
