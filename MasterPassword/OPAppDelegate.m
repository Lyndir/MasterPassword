//
//  OPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPAppDelegate.h"

#import "OPMainViewController.h"

@interface OPAppDelegate ()

+ (NSDictionary *)keyPhraseQuery;
+ (NSDictionary *)keyPhraseHashQuery;

- (void)forgetKeyPhrase;
- (void)loadStoredKeyPhrase;
- (void)askKeyPhrase;

@end

@implementation OPAppDelegate

@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

@synthesize keyPhrase = _keyPhrase;
@synthesize keyPhraseHash = _keyPhraseHash;
@synthesize keyPhraseHashHex = _keyPhraseHashHex;

+ (void)initialize {
    
#ifdef DEBUG
    [Logger get].autoprintLevel = LogLevelTrace;
    [NSClassFromString(@"WebView") performSelector:@selector(_enableRemoteInspector)];
#endif
}

+ (NSDictionary *)keyPhraseQuery {
    
    static NSDictionary *OPKeyPhraseQuery = nil;
    if (!OPKeyPhraseQuery)
        OPKeyPhraseQuery = [KeyChain createQueryForClass:kSecClassGenericPassword
                                              attributes:[NSDictionary dictionaryWithObject:@"MasterPassword"
                                                                                     forKey:(__bridge id)kSecAttrService]
                                                 matches:nil];
    
    return OPKeyPhraseQuery;
}

+ (NSDictionary *)keyPhraseHashQuery {
    
    static NSDictionary *OPKeyPhraseHashQuery = nil;
    if (!OPKeyPhraseHashQuery)
        OPKeyPhraseHashQuery = [KeyChain createQueryForClass:kSecClassGenericPassword
                                                  attributes:[NSDictionary dictionaryWithObject:@"MasterPasswordHash"
                                                                                         forKey:(__bridge id)kSecAttrService]
                                                     matches:nil];
    
    return OPKeyPhraseHashQuery;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
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
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    if ([[OPConfig get].showQuickStart boolValue])
        [self showGuide];
    else
        [self loadKeyPhrase];
}

- (void)showGuide {
    
    [self.navigationController performSegueWithIdentifier:@"OP_Guide" sender:self];
}

- (void)loadKeyPhrase {
    
    if ([[OPConfig get].forgetKeyPhrase boolValue]) {
        [self forgetKeyPhrase];
        return;
    }
    
    [self loadStoredKeyPhrase];
    if (!self.keyPhrase) {
        // Key phrase is not known.  Ask user to set/specify it.
        dbg(@"Key phrase not known.  Will ask user.");
        [self askKeyPhrase];
        return;
    }
}

- (void)forgetKeyPhrase {
    
    dbg(@"Forgetting key phrase.");
    [AlertViewController showAlertWithTitle:@"Changing Master Password"
                                    message:
     @"You've requested to change your master password.\n\n"
     @"If you continue, your current sites and passwords will become unavailable.\n\n"
     @"You can always change back to the old master password later.\n"
     @"Your old sites and passwords will then become available again."
                                  viewStyle:UIAlertViewStyleDefault
                          tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                              if (buttonIndex == [alert firstOtherButtonIndex]) {
                                  // Key phrase reset.  Delete it.
                                  dbg(@"Deleting master key phrase and hash from key chain.");
                                  [KeyChain deleteItemForQuery:[OPAppDelegate keyPhraseQuery]];
                                  [KeyChain deleteItemForQuery:[OPAppDelegate keyPhraseHashQuery]];
                              }
                              
                              [self loadKeyPhrase];
                          }
                                cancelTitle:[PearlStrings get].commonButtonAbort
                                otherTitles:[PearlStrings get].commonButtonContinue, nil];
    [OPConfig get].forgetKeyPhrase = [NSNumber numberWithBool:NO];
}

- (void)loadStoredKeyPhrase {
    
    if ([[OPConfig get].storeKeyPhrase boolValue]) {
        // Key phrase is stored in keychain.  Load it.
        dbg(@"Loading master key phrase from key chain.");
        NSData *keyPhraseData = [KeyChain dataOfItemForQuery:[OPAppDelegate keyPhraseQuery]];
        dbg(@" -> Master key phrase %@.", keyPhraseData? @"found": @"NOT found");
        
        self.keyPhrase = keyPhraseData? [[NSString alloc] initWithBytes:keyPhraseData.bytes length:keyPhraseData.length
                                                               encoding:NSUTF8StringEncoding]: nil;
    } else {
        // Key phrase should not be stored in keychain.  Delete it.
        dbg(@"Deleting master key phrase from key chain.");
        [KeyChain deleteItemForQuery:[OPAppDelegate keyPhraseQuery]];
    }
}

- (void)askKeyPhrase {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData *keyPhraseHash = [KeyChain dataOfItemForQuery:[OPAppDelegate keyPhraseHashQuery]];
        dbg(@"Key phrase hash %@.", keyPhraseHash? @"known": @"NOT known");
        
        [AlertViewController showAlertWithTitle:@"Master Password"
                                        message:keyPhraseHash? @"Unlock with your master password:": @"Choose your master password:"
                                      viewStyle:UIAlertViewStyleSecureTextInput
                              tappedButtonBlock:
         ^(UIAlertView *alert, NSInteger buttonIndex) {
             if (buttonIndex == [alert cancelButtonIndex])
                 exit(0);
             
             NSString *answer = [alert textFieldAtIndex:0].text;
             if (![answer length]) {
                 // User didn't enter a key phrase.
                 [AlertViewController showAlertWithTitle:[PearlStrings get].commonTitleError
                                                 message:@"No master password entered."
                                               viewStyle:UIAlertViewStyleDefault
                                       tappedButtonBlock:
                  ^(UIAlertView *alert, NSInteger buttonIndex) {
                      exit(0);
                  } cancelTitle:@"Quit" otherTitles:nil];
             }
             
             NSData *answerHash = [answer hashWith:PearlDigestSHA512];
             if (keyPhraseHash)
                 // A key phrase hash is known -> a key phrase is set.
                 // Make sure the user's entered key phrase matches it.
                 if (![keyPhraseHash isEqual:answerHash]) {
                     dbg(@"Key phrase hash mismatch. Expected: %@, answer: %@.", keyPhraseHash, answerHash);
                     
                     [AlertViewController showAlertWithTitle:[PearlStrings get].commonTitleError
                                                     message:
                                                             @"Incorrect master password.\n\n"
                             @"If you are trying to use the app with a different master password, "
                                                                     @"flip the 'Change my password' option in Settings."
                                                   viewStyle:UIAlertViewStyleDefault
                                           tappedButtonBlock:
                      ^(UIAlertView *alert, NSInteger buttonIndex) {
                          exit(0);
                      } cancelTitle:@"Quit" otherTitles:nil];
                     
                     return;
                 }
             
             self.keyPhrase = answer;
         } cancelTitle:@"Quit" otherTitles:@"Unlock", nil];
    });
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [self saveContext];
    
    if (![[OPConfig get].rememberKeyPhrase boolValue])
        self.keyPhrase = nil;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [self saveContext];
}

+ (OPAppDelegate *)get {
    
    return (OPAppDelegate *)[super get];
}

+ (NSManagedObjectContext *)managedObjectContext {
    
    return [(OPAppDelegate *)[UIApplication sharedApplication].delegate managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    
    return [(OPAppDelegate *)[UIApplication sharedApplication].delegate managedObjectModel];
}

- (void)saveContext {
    
    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
            err(@"Unresolved error %@", error);
    }];
}

- (void)setKeyPhrase:(NSString *)keyPhrase {
    
    _keyPhrase = keyPhrase;
    
    if (keyPhrase) {
        self.keyPhraseHash = [keyPhrase hashWith:PearlDigestSHA512];
        self.keyPhraseHashHex = [self.keyPhraseHash encodeHex];
        
        dbg(@"Updating master key phrase hash to: %@.", self.keyPhraseHashHex);
        [KeyChain addOrUpdateItemForQuery:[OPAppDelegate keyPhraseHashQuery]
                           withAttributes:[NSDictionary dictionaryWithObject:self.keyPhraseHash
                                                                      forKey:(__bridge id)kSecValueData]];
        if ([[OPConfig get].storeKeyPhrase boolValue]) {
            dbg(@"Storing master key phrase in key chain.");
            [KeyChain addOrUpdateItemForQuery:[OPAppDelegate keyPhraseQuery]
                               withAttributes:[NSDictionary dictionaryWithObject:[keyPhrase dataUsingEncoding:NSUTF8StringEncoding]
                                                                          forKey:(__bridge id)kSecValueData]];
        }
    }
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
                                                               [NSNotification notificationWithName:OPPersistentStoreDidChangeNotification
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
        @throw [NSException exceptionWithName:error.domain reason:error.localizedDescription
                                     userInfo:[NSDictionary dictionaryWithObject:error forKey:@"cause"]];
    }
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
