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

@interface MPiOSAppDelegate()

@property(nonatomic, weak) PearlAlert *handleCloudDisabledAlert;
@property(nonatomic, weak) PearlAlert *handleCloudContentAlert;
@property(nonatomic, weak) PearlAlert *fixCloudContentAlert;
@property(nonatomic, weak) PearlOverlay *storeLoadingOverlay;
@end

@implementation MPiOSAppDelegate

+ (void)initialize {

    if ([self class] == [MPiOSAppDelegate class]) {
        [PearlLogger get].historyLevel = [[MPiOSConfig get].traceMode boolValue]? PearlLogLevelTrace: PearlLogLevelInfo;
#ifdef DEBUG
        [PearlLogger get].printLevel = PearlLogLevelDebug; //Trace;
#else
        [PearlLogger get].printLevel = [[MPiOSConfig get].traceMode boolValue]? PearlLogLevelDebug: PearlLogLevelInfo;
#endif
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    @try {
        [[NSBundle mainBundle] mutableInfoDictionary][@"CFBundleDisplayName"] = @"Master Password";
        [[NSBundle mainBundle] mutableLocalizedInfoDictionary][@"CFBundleDisplayName"] = @"Master Password";

#ifdef CRASHLYTICS
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
                PearlLogLevel level = PearlLogLevelInfo;
                if ([[MPiOSConfig get].sendInfo boolValue])
                    level = PearlLogLevelDebug;

                if (message.level >= level)
                    CLSLog( @"%@", [message messageDescription] );

                return YES;
            }];
            CLSLog( @"Crashlytics (%@) initialized for: %@ v%@.", //
                    [Crashlytics sharedInstance].version, [PearlInfoPlist get].CFBundleName, [PearlInfoPlist get].CFBundleVersion );
        }
#endif
    }
    @catch (id exception) {
        err( @"During Analytics Setup: %@", exception );
    }
    @try {
        [[NSNotificationCenter defaultCenter] addObserverForName:MPCheckConfigNotification object:nil queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            [self updateConfigKey:note.object];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:kIASKAppSettingChanged object:nil queue:nil usingBlock:
                ^(NSNotification *note) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:note.object];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:nil queue:nil usingBlock:
                ^(NSNotification *note) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:nil];
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
    }
    @catch (id exception) {
        err( @"During Config Test: %@", exception );
    }
    @try {
        [super application:application didFinishLaunchingWithOptions:launchOptions];
    }
    @catch (id exception) {
        err( @"During Pearl Application Launch: %@", exception );
    }
    @try {
        inf( @"Started up with device identifier: %@", [PearlKeyChain deviceIdentifier] );

        [[NSNotificationCenter defaultCenter] addObserverForName:MPFoundInconsistenciesNotification object:nil queue:nil usingBlock:
                ^(NSNotification *note) {
            switch ((MPFixableResult)[note.userInfo[MPInconsistenciesFixResultUserKey] unsignedIntegerValue]) {

                case MPFixableResultNoProblems:
                    break;
                case MPFixableResultProblemsFixed:
                    [PearlAlert showAlertWithTitle:@"Inconsistencies Fixed" message:
                            @"Some inconsistencies were detected in your sites.\n"
                                    @"All issues were fixed."
                                         viewStyle:UIAlertViewStyleDefault initAlert:nil
                                 tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
                    break;
                case MPFixableResultProblemsNotFixed:
                    [PearlAlert showAlertWithTitle:@"Inconsistencies Found" message:
                            @"Some inconsistencies were detected in your sites.\n"
                                    @"Not all issues could be fixed.  Try signing in to each user or checking the logs."
                                         viewStyle:UIAlertViewStyleDefault initAlert:nil
                                 tappedButtonBlock:nil cancelTitle:[PearlStrings get].commonButtonOkay otherTitles:nil];
                    break;
            }
        }];

        PearlMainQueue( ^{
            if ([[MPiOSConfig get].showSetup boolValue])
                [self.navigationController performSegueWithIdentifier:@"setup" sender:self];
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
    }
    @catch (id exception) {
        err( @"During Post-Startup: %@", exception );
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    // No URL?
    if (!url)
        return NO;

    // Arbitrary URL to mpsites data.
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^{
        NSError *error;
        NSURLResponse *response;
        NSData *importedSitesData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
                                                          returningResponse:&response error:&error];
        if (error)
            err( @"While reading imported sites from %@: %@", url, error );
        if (!importedSitesData)
            return;

        PearlOverlay *activityOverlay = [PearlOverlay showProgressOverlayWithTitle:@"Importing"];

        NSString *importedSitesString = [[NSString alloc] initWithData:importedSitesData encoding:NSUTF8StringEncoding];
        MPImportResult result = [self importSites:importedSitesString askImportPassword:^NSString *(NSString *userName) {
            __block NSString *masterPassword = nil;

            dispatch_group_t importPasswordGroup = dispatch_group_create();
            dispatch_group_enter( importPasswordGroup );
            dispatch_async( dispatch_get_main_queue(), ^{
                [PearlAlert showAlertWithTitle:@"Import File's Master Password"
                                       message:strf( @"%@'s export was done using a different master password.\n"
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
                [PearlAlert showAlertWithTitle:strf( @"Master Password for\n%@", userName )
                                       message:strf( @"Imports %lu sites, overwriting %lu.",
                                                       (unsigned long)importCount, (unsigned long)deleteCount )
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

        [activityOverlay cancelOverlayAnimated:YES];
    } );

    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {

    inf( @"Received memory warning." );

    [super applicationDidReceiveMemoryWarning:application];
}

- (void)applicationWillResignActive:(UIApplication *)application {

    inf( @"Will deactivate" );
    if (![[MPiOSConfig get].rememberLogin boolValue])
        [self signOutAnimated:NO];

    [super applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

    inf( @"Re-activated" );
    [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:nil];

    [super applicationDidBecomeActive:application];
}

#pragma mark - Behavior

- (void)showReview {

    [super showReview];

    MPCheckpoint( MPCheckpointReview, nil );
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
                                subject:strf( @"Feedback for Master Password [%@]",
                                                [[PearlKeyChain deviceIdentifier] stringByDeletingMatchesOf:@"-.*"] )
                                   body:strf( @"\n\n\n"
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
                                                        fileName:strf( @"%@-%@.log",
                                                                [[NSDateFormatter rfc3339DateFormatter] stringFromDate:[NSDate date]],
                                                                [PearlKeyChain deviceIdentifier] )]
                                         : nil), nil]
            showComposerForVC:viewController];
}

- (void)showExportForVC:(UIViewController *)viewController {

    [PearlAlert showAlertWithTitle:@"Exporting Your Sites"
                           message:@"An export is great for keeping a "
                                           @"backup list of your accounts.\n\n"
                                           @"When the file is ready, you will be "
                                           @"able to mail it to yourself.\n"
                                           @"You can open it with a text editor or "
                                           @"with Master Password if you need to "
                                           @"restore your list of sites."
                         viewStyle:UIAlertViewStyleDefault initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        if (buttonIndex != [alert cancelButtonIndex])
            [PearlAlert showAlertWithTitle:@"Show Passwords?"
                                   message:@"Would you like to make all your passwords "
                                                   @"visible in the export file?\n\n"
                                                   @"A safe export will include all sites "
                                                   @"but make their passwords invisible.\n"
                                                   @"It is great as a backup and remains "
                                                   @"safe when fallen in the wrong hands."
                                 viewStyle:UIAlertViewStyleDefault initAlert:nil
                         tappedButtonBlock:^(UIAlertView *alert_, NSInteger buttonIndex_) {
                if (buttonIndex_ == [alert_ firstOtherButtonIndex] + 0)
                    // Safe Export
                    [self showExportRevealPasswords:NO forVC:viewController];
                if (buttonIndex_ == [alert_ firstOtherButtonIndex] + 1)
                    // Show Passwords
                    [self showExportRevealPasswords:YES forVC:viewController];
            } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:@"Safe Export", @"Show Passwords", nil];
    } cancelTitle:@"Cancel" otherTitles:@"Export Sites", nil];
}

- (void)showExportRevealPasswords:(BOOL)revealPasswords forVC:(UIViewController *)viewController {

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

    NSString *exportedSites = [self exportSitesRevealPasswords:revealPasswords];
    NSString *message;

    if (revealPasswords)
        message = strf( @"Export of Master Password sites with passwords included.\n\n"
                @"REMINDER: Make sure nobody else sees this file!  Passwords are visible!\n\n\n"
                @"--\n"
                @"%@\n"
                @"Master Password %@, build %@",
                [self activeUserForMainThread].name,
                [PearlInfoPlist get].CFBundleShortVersionString,
                [PearlInfoPlist get].CFBundleVersion );
    else
        message = strf( @"Backup of Master Password sites.\n\n\n"
                @"--\n"
                @"%@\n"
                @"Master Password %@, build %@",
                [self activeUserForMainThread].name,
                [PearlInfoPlist get].CFBundleShortVersionString,
                [PearlInfoPlist get].CFBundleVersion );

    NSDateFormatter *exportDateFormatter = [NSDateFormatter new];
    [exportDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];

    [PearlEMail sendEMailTo:nil fromVC:viewController subject:@"Master Password Export" body:message
                attachments:[[PearlEMailAttachment alloc] initWithContent:[exportedSites dataUsingEncoding:NSUTF8StringEncoding]
                                                                 mimeType:@"text/plain" fileName:
                                strf( @"%@ (%@).mpsites", [self activeUserForMainThread].name,
                                        [exportDateFormatter stringFromDate:[NSDate date]] )],
                            nil];
}

- (void)changeMasterPasswordFor:(MPUserEntity *)user saveInContext:(NSManagedObjectContext *)moc didResetBlock:(void ( ^ )(void))didReset {

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
            inf( @"Unsetting master password for: %@.", user.userID );
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

    [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:NSStringFromSelector( configKey )];
}

- (void)updateConfigKey:(NSString *)key {

    // iCloud enabled / disabled
    BOOL iCloudEnabled = [[MPiOSConfig get].iCloudEnabled boolValue];
    BOOL cloudEnabled = self.storeManager.cloudEnabled;
    if (iCloudEnabled != cloudEnabled) {
        if ([[MPiOSConfig get].iCloudEnabled boolValue])
            [self.storeManager setCloudEnabledAndOverwriteCloudWithLocalIfConfirmed:^(void (^setConfirmationAnswer)(BOOL answer)) {
                __block NSUInteger siteCount = NSNotFound;
                [MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
                    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
                    NSError *error = nil;
                    if ((siteCount = [context countForFetchRequest:fetchRequest error:&error]) == NSNotFound) {
                        wrn( @"Couldn't count current sites: %@", error );
                        return;
                    }
                }];

                // If we currently have no sites, don't bother asking to copy them.
                if (siteCount == 0) {
                    setConfirmationAnswer( NO );
                    return;
                }

                // The current store has sites, ask the user if he wants to copy them to the cloud
                [PearlAlert showAlertWithTitle:@"Copy Sites To iCloud?"
                                       message:@"You can either switch to your old iCloud sites "
                                                       @"or overwrite them with your current sites."
                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                             tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                    if (buttonIndex == [alert cancelButtonIndex])
                        setConfirmationAnswer( NO );
                    if (buttonIndex == [alert firstOtherButtonIndex])
                        setConfirmationAnswer( YES );
                }
                                   cancelTitle:@"Use Old" otherTitles:@"Overwrite", nil];
            }];
        else
            [self.storeManager setCloudDisabledAndOverwriteLocalWithCloudIfConfirmed:^(void (^setConfirmationAnswer)(BOOL answer)) {
                __block NSUInteger siteCount = NSNotFound;
                [MPAppDelegate_Shared managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
                    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
                    NSError *error = nil;
                    if ((siteCount = [context countForFetchRequest:fetchRequest error:&error]) == NSNotFound) {
                        wrn( @"Couldn't count current sites: %@", error );
                        return;
                    }
                }];

                // If we currently have no sites, don't bother asking to copy them.
                if (siteCount == 0) {
                    setConfirmationAnswer( NO );
                    return;
                }

                [PearlAlert showAlertWithTitle:@"Copy iCloud Sites?"
                                       message:@"You can either switch to the old sites on your device "
                                                       @"or overwrite them with your current iCloud sites."
                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                             tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                    if (buttonIndex == [alert cancelButtonIndex])
                        setConfirmationAnswer( NO );
                    if (buttonIndex == [alert firstOtherButtonIndex])
                        setConfirmationAnswer( YES );
                }
                                   cancelTitle:@"Use Old" otherTitles:@"Overwrite", nil];
            }];
    }

    // Trace mode
    [PearlLogger get].historyLevel = [[MPiOSConfig get].traceMode boolValue]? PearlLogLevelTrace: PearlLogLevelInfo;

    // Send info
    if ([[MPiOSConfig get].sendInfo boolValue]) {
        if ([PearlLogger get].printLevel > PearlLogLevelInfo)
            [PearlLogger get].printLevel = PearlLogLevelInfo;

#ifdef CRASHLYTICS
                        [[Crashlytics sharedInstance] setBoolValue:[[MPConfig get].rememberLogin boolValue] forKey:@"rememberLogin"];
                        [[Crashlytics sharedInstance] setBoolValue:[[MPiOSConfig get].iCloudEnabled boolValue] forKey:@"iCloudEnabled"];
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

        MPCheckpoint( MPCheckpointConfig, @{
                @"rememberLogin"       : @([[MPConfig get].rememberLogin boolValue]),
                @"iCloudEnabled"       : @([[MPiOSConfig get].iCloudEnabled boolValue]),
                @"iCloudDecided"       : @([[MPConfig get].iCloudDecided boolValue]),
                @"sendInfo"            : @([[MPiOSConfig get].sendInfo boolValue]),
                @"helpHidden"          : @([[MPiOSConfig get].helpHidden boolValue]),
                @"showQuickStart"      : @([[MPiOSConfig get].showSetup boolValue]),
                @"firstRun"            : @([[PearlConfig get].firstRun boolValue]),
                @"launchCount"         : NilToNSNull( [PearlConfig get].launchCount ),
                @"askForReviews"       : @([[PearlConfig get].askForReviews boolValue]),
                @"reviewAfterLaunches" : NilToNSNull( [PearlConfig get].reviewAfterLaunches ),
                @"reviewedVersion"     : NilToNSNull( [PearlConfig get].reviewedVersion )
        } );
    }
}

#pragma mark - UbiquityStoreManager

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager willLoadStoreIsCloud:(BOOL)isCloudStore {

    dispatch_async( dispatch_get_main_queue(), ^{
        [self.handleCloudContentAlert cancelAlertAnimated:YES];
        if (!self.storeLoadingOverlay)
            self.storeLoadingOverlay = [PearlOverlay showProgressOverlayWithTitle:@"Loading Sites"];
    } );

    [super ubiquityStoreManager:manager willLoadStoreIsCloud:isCloudStore];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didLoadStoreForCoordinator:(NSPersistentStoreCoordinator *)coordinator
                     isCloud:(BOOL)isCloudStore {

    [MPiOSConfig get].iCloudEnabled = @(isCloudStore);
    [super ubiquityStoreManager:manager didLoadStoreForCoordinator:coordinator isCloud:isCloudStore];

    [self.handleCloudContentAlert cancelAlertAnimated:YES];
    [self.fixCloudContentAlert cancelAlertAnimated:YES];
    [self.storeLoadingOverlay cancelOverlayAnimated:YES];
    [self.handleCloudDisabledAlert cancelAlertAnimated:YES];
}

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager failedLoadingStoreWithCause:(UbiquityStoreErrorCause)cause context:(id)context
                    wasCloud:(BOOL)wasCloudStore {

    [self.storeLoadingOverlay cancelOverlayAnimated:YES];
    [self.handleCloudDisabledAlert cancelAlertAnimated:YES];
}

- (BOOL)ubiquityStoreManager:(UbiquityStoreManager *)manager handleCloudContentCorruptionWithHealthyStore:(BOOL)storeHealthy {

    if (manager.cloudEnabled && !storeHealthy && !(self.handleCloudContentAlert || self.fixCloudContentAlert)) {
        [self.storeLoadingOverlay cancelOverlayAnimated:YES];
        [self.handleCloudDisabledAlert cancelAlertAnimated:YES];
        [self showCloudContentAlert];
    };

    return NO;
}

- (BOOL)ubiquityStoreManagerHandleCloudDisabled:(UbiquityStoreManager *)manager {

    if (!self.handleCloudDisabledAlert)
        self.handleCloudDisabledAlert = [PearlAlert showAlertWithTitle:@"iCloud Login" message:
                @"You haven't added an iCloud account to your device yet.\n"
                        @"To add one, go into Apple's Settings -> iCloud."
                                                             viewStyle:UIAlertViewStyleDefault initAlert:nil
                                                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                    if (buttonIndex == alert.firstOtherButtonIndex) {
                        [MPiOSConfig get].iCloudEnabled = @NO;
                        return;
                    }

                    [self.storeManager reloadStore];
                } cancelTitle:@"Try Again" otherTitles:@"Disable iCloud", nil];

    return YES;
}

- (void)showCloudContentAlert {

    __weak MPiOSAppDelegate *wSelf = self;
    [self.handleCloudContentAlert cancelAlertAnimated:NO];
    // TODO: Add the activity indicator back.
    self.handleCloudContentAlert = [PearlAlert showAlertWithTitle:@"iCloud Sync Problem"
                                                          message:@"Waiting for your other device to auto‑correct the problem..."
                                                        viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:
                    ^(UIAlertView *alert, NSInteger buttonIndex) {
                if (buttonIndex == [alert firstOtherButtonIndex])
                    wSelf.fixCloudContentAlert = [PearlAlert showAlertWithTitle:@"Fix iCloud Now" message:
                            @"This problem can be auto‑corrected by opening the app on another device where you recently made changes.\n"
                                    @"You can fix the problem from this device anyway, but recent changes from another device might get lost.\n\n"
                                    @"You can also turn iCloud off for now."
                                                                      viewStyle:UIAlertViewStyleDefault
                                                                      initAlert:nil tappedButtonBlock:
                                    ^(UIAlertView *alert_, NSInteger buttonIndex_) {
                                if (buttonIndex_ == alert_.cancelButtonIndex)
                                    [wSelf showCloudContentAlert];
                                if (buttonIndex_ == [alert_ firstOtherButtonIndex])
                                    [wSelf.storeManager rebuildCloudContentFromCloudStoreOrLocalStore:YES];
                                if (buttonIndex_ == [alert_ firstOtherButtonIndex] + 1)
                                    [MPiOSConfig get].iCloudEnabled = @NO;
                            }
                                                                    cancelTitle:[PearlStrings get].commonButtonBack
                                                                    otherTitles:@"Fix Anyway",
                                                                                @"Turn Off", nil];
                if (buttonIndex == [alert firstOtherButtonIndex] + 1)
                    [MPiOSConfig get].iCloudEnabled = @NO;
            }                                         cancelTitle:nil otherTitles:@"Fix Now", @"Turn Off", nil];
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

    NSString *crashlyticsAPIKey = NSNullToNil( [[self crashlyticsInfo] valueForKeyPath:@"API Key"] );
    if (![crashlyticsAPIKey length])
        wrn( @"Crashlytics API key not set.  Crash logs won't be recorded." );

    return crashlyticsAPIKey;
}

@end
