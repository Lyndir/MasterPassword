//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"

#import "MPMainViewController.h"
#import "IASKSettingsReader.h"

@interface MPAppDelegate ()

@property (strong, nonatomic) NSData                                    *keyPhrase;
@property (strong, nonatomic) NSData                                    *keyPhraseHash;
@property (strong, nonatomic) NSString                                  *keyPhraseHashHex;

+ (NSDictionary *)keyPhraseQuery;
+ (NSDictionary *)keyPhraseHashQuery;

- (void)loadStoredKeyPhrase;
- (void)askKeyPhrase:(BOOL)animated;

@end

@implementation MPAppDelegate

@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize keyPhrase = _keyPhrase;
@synthesize keyPhraseHash = _keyPhraseHash;
@synthesize keyPhraseHashHex = _keyPhraseHashHex;

+ (void)initialize {

    [MPConfig get];

#ifdef DEBUG
    [PearlLogger get].autoprintLevel = PearlLogLevelTrace;
    [NSClassFromString(@"WebView") performSelector:@selector(_enableRemoteInspector)];
#endif
}

+ (NSDictionary *)keyPhraseQuery {
    
    static NSDictionary *MPKeyPhraseQuery = nil;
    if (!MPKeyPhraseQuery)
        MPKeyPhraseQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                              attributes:[NSDictionary dictionaryWithObject:@"MasterPassword"
                                                                                     forKey:(__bridge id)kSecAttrService]
                                                 matches:nil];
    
    return MPKeyPhraseQuery;
}

+ (NSDictionary *)keyPhraseHashQuery {
    
    static NSDictionary *MPKeyPhraseHashQuery = nil;
    if (!MPKeyPhraseHashQuery)
        MPKeyPhraseHashQuery = [PearlKeyChain createQueryForClass:kSecClassGenericPassword
                                                  attributes:[NSDictionary dictionaryWithObject:@"MasterPasswordHash"
                                                                                         forKey:(__bridge id)kSecAttrService]
                                                     matches:nil];
    
    return MPKeyPhraseHashQuery;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#ifndef PRODUCTION
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
                                                      if ([NSStringFromSelector(@selector(storeKeyPhrase))
                                                           isEqualToString:[note.object description]]) {
                                                          self.keyPhrase = self.keyPhrase;
                                                          [self loadKeyPhrase:YES];
                                                      }
                                                      if ([NSStringFromSelector(@selector(forgetKeyPhrase))
                                                           isEqualToString:[note.object description]])
                                                          [self loadKeyPhrase:YES];
                                                  }];

    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationSlide];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    if ([[MPConfig get].showQuickStart boolValue])
        [self showGuide];
    else
        [self loadKeyPhrase:NO];
    
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointActivated];
#endif
}

- (void)showGuide {
    
    [self.navigationController performSegueWithIdentifier:@"MP_Guide" sender:self];
    
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointShowGuide];
#endif
}

- (void)loadKeyPhrase:(BOOL)animated {
    
    if (self.keyPhrase)
        return;
    
    [self loadStoredKeyPhrase];
    if (!self.keyPhrase) {
        // Key phrase is not known.  Ask user to set/specify it.
        dbg(@"Key phrase not known.  Will ask user.");
        [self askKeyPhrase:animated];
        return;
    }
}

- (void)forgetKeyPhrase {
    
    dbg(@"Forgetting key phrase.");
    [PearlAlert showAlertWithTitle:@"Changing Master Password"
                                    message:
     @"This will allow you to log in with a different master password.\n\n"
     @"Note that you will only see the sites and passwords for the master password you log in with.\n"
     @"If you log in with a different master password, your current sites will be unavailable.\n\n"
     @"You can always change back to your current master password later.\n"
     @"Your current sites and passwords will then become available again."
                                  viewStyle:UIAlertViewStyleDefault
                          tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                              if (buttonIndex != [alert cancelButtonIndex]) {
                                  // Key phrase reset.  Delete it.
                                  dbg(@"Deleting master key phrase and hash from key chain.");
                                  [PearlKeyChain deleteItemForQuery:[MPAppDelegate keyPhraseQuery]];
                                  [PearlKeyChain deleteItemForQuery:[MPAppDelegate keyPhraseHashQuery]];
                                  
                                  [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyForgotten object:self];
#ifndef PRODUCTION
                                  [TestFlight passCheckpoint:MPTestFlightCheckpointMPForgotten];
#endif
                              }
                              
                              [self loadKeyPhrase:YES];
                              
#ifndef PRODUCTION
                              [TestFlight passCheckpoint:MPTestFlightCheckpointMPChanged];
#endif
                          }
                                cancelTitle:[PearlStrings get].commonButtonAbort
                                otherTitles:[PearlStrings get].commonButtonContinue, nil];
}

- (void)signOut {
    
    self.keyPhrase = nil;
    [self loadKeyPhrase:YES];
}

- (void)loadStoredKeyPhrase {
    
    if ([[MPConfig get].storeKeyPhrase boolValue]) {
        // Key phrase is stored in keychain.  Load it.
        dbg(@"Loading master key phrase from key chain.");
        self.keyPhrase = [PearlKeyChain dataOfItemForQuery:[MPAppDelegate keyPhraseQuery]];
        dbg(@" -> Master key phrase %@.", self.keyPhrase? @"found": @"NOT found");
    } else {
        // Key phrase should not be stored in keychain.  Delete it.
        dbg(@"Deleting master key phrase from key chain.");
        [PearlKeyChain deleteItemForQuery:[MPAppDelegate keyPhraseQuery]];
#ifndef PRODUCTION
        [TestFlight passCheckpoint:MPTestFlightCheckpointMPUnstored];
#endif
    }
}

- (void)askKeyPhrase:(BOOL)animated {

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController presentViewController:
                [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"MPUnlockViewController"]
                                                animated:animated completion:nil];
    });
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [self saveContext];
    
    if (![[MPConfig get].rememberKeyPhrase boolValue])
        self.keyPhrase = nil;
    
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointDeactivated];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
    
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointTerminated];
#endif
}

+ (MPAppDelegate *)get {
    
    return (MPAppDelegate *)[super get];
}

+ (NSManagedObjectContext *)managedObjectContext {
    
    return [(MPAppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    
    return [(MPAppDelegate *)[UIApplication sharedApplication].delegate managedObjectModel];
}

- (void)saveContext {
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
            err(@"Unresolved error %@", error);
    }];
}

- (BOOL)tryMasterPassword:(NSString *)tryPassword {
    
    NSData *keyPhraseHash = [PearlKeyChain dataOfItemForQuery:[MPAppDelegate keyPhraseHashQuery]];
    dbg(@"Key phrase hash %@.", keyPhraseHash? @"known": @"NOT known");
    
    if (![tryPassword length])
        return NO;
    
    NSData *tryKeyPhrase = keyPhraseForPassword(tryPassword);
    NSData *tryKeyPhraseHash = keyPhraseHashForKeyPhrase(tryKeyPhrase);
    if (keyPhraseHash)
        // A key phrase hash is known -> a key phrase is set.
        // Make sure the user's entered key phrase matches it.
        if (![keyPhraseHash isEqual:tryKeyPhraseHash]) {
            dbg(@"Key phrase hash mismatch. Expected: %@, answer: %@.", keyPhraseHash, tryKeyPhraseHash);
            
#ifndef PRODUCTION
            [TestFlight passCheckpoint:MPTestFlightCheckpointMPMismatch];
#endif
            return NO;
        }
    
#ifndef PRODUCTION
    [TestFlight passCheckpoint:MPTestFlightCheckpointMPAsked];
#endif
    
    self.keyPhrase = tryKeyPhrase;
    return YES;
}

- (void)setKeyPhrase:(NSData *)keyPhrase {
    
    _keyPhrase = keyPhrase;
    
    if (keyPhrase)
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeySet object:self];
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:MPNotificationKeyUnset object:self];
    
    if (keyPhrase) {
        self.keyPhraseHash = keyPhraseHashForKeyPhrase(keyPhrase);
        self.keyPhraseHashHex = [self.keyPhraseHash encodeHex];
        
        dbg(@"Updating master key phrase hash to: %@.", self.keyPhraseHashHex);
        [PearlKeyChain addOrUpdateItemForQuery:[MPAppDelegate keyPhraseHashQuery]
                           withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                           self.keyPhraseHash,                                      (__bridge id)kSecValueData,
                                           kSecAttrAccessibleWhenUnlocked,                          (__bridge id)kSecAttrAccessible,
                                           nil]];
        if ([[MPConfig get].storeKeyPhrase boolValue]) {
            dbg(@"Storing master key phrase in key chain.");
            [PearlKeyChain addOrUpdateItemForQuery:[MPAppDelegate keyPhraseQuery]
                               withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                               keyPhrase,  (__bridge id)kSecValueData,
                                               kSecAttrAccessibleWhenUnlocked,                      (__bridge id)kSecAttrAccessible,
                                               nil]];
        }
        
#ifndef PRODUCTION
        [TestFlight passCheckpoint:[NSString stringWithFormat:MPTestFlightCheckpointSetKeyphraseLength, _keyPhrase.length]];
#endif
    }
}

- (NSData *)keyPhraseWithLength:(NSUInteger)keyLength {
    
    return [self.keyPhrase subdataWithRange:NSMakeRange(0, MIN(keyLength, self.keyPhrase.length))];
}

#pragma mark - Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
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
                                                               [NSNotification notificationWithName:UIScreenModeDidChangeNotification
                                                                                             object:self userInfo:[note userInfo]]];
                                                          }];
                                                      }];
    }
    
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel)
        return __managedObjectModel;
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MasterPassword" withExtension:@"momd"];
    return __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
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
                                                                   @"MasterPassword.store",         NSPersistentStoreUbiquitousContentNameKey,
                                                                   [[[NSFileManager defaultManager]
                                                                     URLForUbiquityContainerIdentifier:nil]
                                                                    URLByAppendingPathComponent:@"store"
                                                                    isDirectory:YES],               NSPersistentStoreUbiquitousContentURLKey,
                                                                   nil]
                                                            error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        err(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
        wrn(@"Deleted datastore: %@", storeURL);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];        
#endif
        
#ifndef PRODUCTION
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
