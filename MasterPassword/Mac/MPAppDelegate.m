//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Key.h"
#import "MPConfig.h"

#import <netinet/in.h>
#import <sys/socket.h>


@interface MPAppDelegate ()

@property (readwrite, strong, nonatomic) MPPasswordWindowController     *passwordWindow;
@property (readwrite, strong, nonatomic) NSNetService                   *netService;
@property (readwrite, assign, nonatomic) CFSocketRef                    listeningSocket;

- (void)connectionEstablishedOnHandle:(CFSocketNativeHandle)handle;

@end

@implementation MPAppDelegate
@synthesize window = _window;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize netService, listeningSocket;
@synthesize passwordWindow;

@synthesize key;
@synthesize keyHash;
@synthesize keyHashHex;

static void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {

    [[MPAppDelegate get] connectionEstablishedOnHandle:*(const CFSocketNativeHandle *)data];
}

+ (void)initialize {
    
    [MPConfig get];
    
#ifdef DEBUG
    [PearlLogger get].autoprintLevel = PearlLogLevelTrace;
#endif
}

+ (NSManagedObjectContext *)managedObjectContext {
    
    return [[self get] managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    
    return [[self get] managedObjectModel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self setupNetworkListener];
}

- (void)setupNetworkListener {
    
    struct sockaddr_in6 serverAddress6;
    socklen_t serverAddress6_len    = sizeof(serverAddress6);
    memset(&serverAddress6, 0, serverAddress6_len);
    serverAddress6.sin6_len         = serverAddress6_len;
    serverAddress6.sin6_family      = AF_INET6;
    
    NSSocketNativeHandle socketHandle;
    if (0 > (socketHandle = socket(AF_INET6, SOCK_STREAM, 0))) {
        err(@"Couldn't create socket: %@", errstr());
        return;
    }
    if (0 > bind(socketHandle, (const struct sockaddr *) &serverAddress6, serverAddress6_len)) {
        err(@"Couldn't bind socket: %@", errstr());
        close(socketHandle);
        return;
    }
    if (0 > getsockname(socketHandle, (struct sockaddr *) &serverAddress6, &serverAddress6_len)) {
        err(@"Couldn't get socket info: %@", errstr());
        close(socketHandle);
        return;
    }
    if (0 > listen(socketHandle, 5)) {
        err(@"Couldn't get socket info: %@", errstr());
        close(socketHandle);
        return;
    }
    if (!(self.listeningSocket = CFSocketCreateWithNative(NULL, socketHandle, kCFSocketAcceptCallBack, ListeningSocketCallback, NULL))) {
        err(@"Couldn't start listening on the socket: %@", errstr());
        return;
    }
    
    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    CFRelease(runLoopSource);
    
    int chosenPort = ntohs(serverAddress6.sin6_port);
    inf(@"Master Password bound to port %d", chosenPort);
    self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_masterpassword._tcp." name:@"Master Password" port:chosenPort];
    if(!self.netService) {
        err(@"Couldn't initialize the Bonjour service.");
        return;
    }
    
    self.netService.delegate = self;
    [self.netService publish];
}

- (void)connectionEstablishedOnHandle:(CFSocketNativeHandle)handle {
    
    dbg(@"%@%d", NSStringFromSelector(_cmd), handle);
}

/* Sent to the NSNetService instance's delegate prior to advertising the service on the network. If for some reason the service cannot be published, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotPublish: method.
 */
- (void)netServiceWillPublish:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when the publication of the instance is complete and successful.
 */
- (void)netServiceDidPublish:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a successful publication.
 */
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    
    dbg(@"%@%@", NSStringFromSelector(_cmd), errorDict);
}

/* Sent to the NSNetService instance's delegate prior to resolving a service on the network. If for some reason the resolution cannot occur, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotResolve: method.
 */
- (void)netServiceWillResolve:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when one or more addresses have been resolved for an NSNetService instance. Some NSNetService methods will return different results before and after a successful resolution. An NSNetService instance may get resolved more than once; truly robust clients may wish to resolve again after an error, or to resolve more than once.
 */
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when an error in resolving the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants).
 */
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    
    dbg(@"%@%@", NSStringFromSelector(_cmd), errorDict);
}

/* Sent to the NSNetService instance's delegate when the instance's previously running publication or resolution request has stopped.
 */
- (void)netServiceDidStop:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when the instance is being monitored and the instance's TXT record has been updated. The new record is contained in the data parameter.
 */
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    
    dbg(@"%@%@", NSStringFromSelector(_cmd), data);
}


- (void)applicationDidBecomeActive:(NSNotification *)notification {
    
    if (!self.passwordWindow)
        self.passwordWindow = [[MPPasswordWindowController alloc] initWithWindowNibName:@"MPPasswordWindowController"];
    [self.passwordWindow showWindow:self];
    
    [self loadKey];
}

- (void)loadKey {
    
    if (!self.key)
        // Try and load the key from the keychain.
        [self loadStoredKey];
    
    if (!self.key)
        // Ask the user to set the key through his master password.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [NSAlert alertWithMessageText:@"Master Password is locked."
                                             defaultButton:@"Unlock" alternateButton:@"Change" otherButton:@"Quit"
                                 informativeTextWithFormat:@"Your master password is required to unlock the application."];
            NSTextField *passwordField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
            [alert setAccessoryView:passwordField];
            [alert layout];
            do {
                NSInteger button = [alert runModal];
                
                if (button == 0)
                    // "Change" button.
                    if ([[NSAlert alertWithMessageText:@"Changing Master Password"
                                         defaultButton:nil alternateButton:[PearlStrings get].commonButtonCancel otherButton:nil
                             informativeTextWithFormat:
                          @"This will allow you to log in with a different master password.\n\n"
                          @"Note that you will only see the sites and passwords for the master password you log in with.\n"
                          @"If you log in with a different master password, your current sites will be unavailable.\n\n"
                          @"You can always change back to your current master password later.\n"
                          @"Your current sites and passwords will then become available again."] runModal] == 1) {
                        [self forgetKey];
                        continue;
                    }
                if (button == -1) {
                    // "Quit" button.
                    [[NSApplication sharedApplication] terminate:self];
                    break;
                }
            } while (![self tryMasterPassword:[passwordField stringValue]]);
        });
}

- (NSURL *)applicationFilesDirectory {
    
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *applicationFilesDirectory = [appSupportURL URLByAppendingPathComponent:@"com.lyndir.lhunath.MasterPassword"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:applicationFilesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
        [[NSApplication sharedApplication] presentError:error];
    
    return applicationFilesDirectory;
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
    
    NSURL *storeURL = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"MasterPassword.sqlite"];
    
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
        
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    [__persistentStoreCoordinator unlock];
    
    return __persistentStoreCoordinator;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!__managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

@end
