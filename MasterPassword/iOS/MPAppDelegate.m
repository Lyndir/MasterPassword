//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"

#import "MPMainViewController.h"
#import "IASKSettingsReader.h"

@implementation MPAppDelegate

@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize key;
@synthesize keyHash;
@synthesize keyHashHex;

+ (void)initialize {

    [MPiOSConfig get];

#ifdef DEBUG
    [PearlLogger get].autoprintLevel = PearlLogLevelTrace;
    [NSClassFromString(@"WebView") performSelector:@selector(_enableRemoteInspector)];
#endif
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#ifdef TESTFLIGHT
    @try {
        [TestFlight takeOff:@"bd44885deee7adce0645ce8e5498d80a_NDQ5NDQyMDExLTEyLTAyIDExOjM1OjQ4LjQ2NjM4NA"];
        [TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:NO],   @"logToConsole",
                                [NSNumber numberWithBool:NO],   @"logToSTDERR",
                                nil]];
        [TestFlight passCheckpoint:MPTestFlightCheckpointLaunched];
        [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
            if (message.level >= PearlLogLevelInfo)
                TFLog(@"%@", message);
            
            return YES;
        }];
    }
    @catch (NSException *exception) {
        err(@"TestFlight: %@", exception);
    }
#endif
    
    UIImage *navBarImage = [[UIImage imageNamed:@"ui_navbar_container"]  resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsLandscapePhone];
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],  UITextAttributeTextColor,
      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8],                          UITextAttributeTextShadowColor, 
      [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],                                  UITextAttributeTextShadowOffset, 
      [UIFont fontWithName:@"Helvetica-Neue" size:0.0],                                 UITextAttributeFont, 
      nil]];
    
    UIImage *navBarButton   = [[UIImage imageNamed:@"ui_navbar_button"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    UIImage *navBarBack     = [[UIImage imageNamed:@"ui_navbar_back"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 13, 0, 5)];
    [[UIBarButtonItem appearance] setBackgroundImage:navBarButton forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:navBarBack forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    [[UIBarButtonItem appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0],                          UITextAttributeTextColor,
      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5],                          UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset:UIOffsetMake(0, 1)],                                   UITextAttributeTextShadowOffset,
      [UIFont fontWithName:@"Helvetica-Neue" size:0.0],                                 UITextAttributeFont,
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
                                                      if ([NSStringFromSelector(@selector(storeKey))
                                                           isEqualToString:[note.object description]]) {
                                                          [self updateKey:self.key];
                                                          [self loadKey:YES];
                                                      }
                                                      if ([NSStringFromSelector(@selector(forgetKey))
                                                           isEqualToString:[note.object description]])
                                                          [self loadKey:YES];
                                                  }];
    
#ifdef TESTFLIGHT
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
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointActivated];
#endif
}

- (void)showGuide {
    
    [self.navigationController performSegueWithIdentifier:@"MP_Guide" sender:self];
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointShowGuide];
#endif
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

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [self saveContext];
    
    if (![[MPiOSConfig get].rememberKey boolValue])
        [self updateKey:nil];
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointDeactivated];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
    
#ifdef TESTFLIGHT
    [TestFlight passCheckpoint:MPTestFlightCheckpointTerminated];
#endif
}

+ (NSManagedObjectContext *)managedObjectContext {
    
    return [[self get] managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    
    return [[self get] managedObjectModel];
}

- (void)saveContext {
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
            err(@"Unresolved error %@", error);
    }];
}

#pragma mark - Core Data stack

- (NSManagedObjectModel *)managedObjectModel {

    if (__managedObjectModel)
        return __managedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MasterPassword" withExtension:@"momd"];
    return __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (__managedObjectContext)
        return __managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        __managedObjectContext.persistentStoreCoordinator = coordinator;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                          object:coordinator
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note) {
                                                          dbg(@"Ubiquitous content change: %@", note);
                                                          
                                                          [__managedObjectContext performBlock:^{
                                                              [__managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                              
                                                              [[NSNotificationCenter defaultCenter] postNotification:
                                                               [NSNotification notificationWithName:MPNotificationStoreUpdated
                                                                                             object:self userInfo:[note userInfo]]];
                                                          }];
                                                      }];
    }
    
    return __managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (__persistentStoreCoordinator)
        return __persistentStoreCoordinator;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MasterPassword.sqlite"];
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [__persistentStoreCoordinator lock];
    NSError *error = nil;
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                                                          options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSNumber numberWithBool:YES],   NSInferMappingModelAutomaticallyOption,
                                                                   [NSNumber numberWithBool:YES],   NSMigratePersistentStoresAutomaticallyOption,
                                                                   [[[NSFileManager defaultManager]
                                                                     URLForUbiquityContainerIdentifier:nil]
                                                                    URLByAppendingPathComponent:@"store"
                                                                    isDirectory:YES],               NSPersistentStoreUbiquitousContentURLKey,
                                                                   @"MasterPassword.store",         NSPersistentStoreUbiquitousContentNameKey,
                                                                   nil]
                                                            error:&error]) {
        err(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
        wrn(@"Deleted datastore: %@", storeURL);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];        
#endif
        
#ifdef TESTFLIGHT
        [TestFlight passCheckpoint:MPTestFlightCheckpointStoreIncompatible];
#endif
        
        @throw [NSException exceptionWithName:error.domain reason:error.localizedDescription
                                     userInfo:[NSDictionary dictionaryWithObject:error forKey:@"cause"]];
    }
    
    if (![[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                                                   forKey:NSFileProtectionKey]
                                          ofItemAtPath:storeURL.path error:&error])
        err(@"Unresolved error %@, %@", error, [error userInfo]);
    [__persistentStoreCoordinator unlock];
    
    return __persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
