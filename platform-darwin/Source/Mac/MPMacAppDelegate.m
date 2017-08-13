//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import <Carbon/Carbon.h>
#import <ServiceManagement/ServiceManagement.h>

#define LOGIN_HELPER_BUNDLE_ID @"com.lyndir.lhunath.MasterPassword.Mac.LoginHelper"

@implementation MPMacAppDelegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
static EventHotKeyID MPShowHotKey = { .signature = 'show', .id = 1 };
static EventHotKeyID MPLockHotKey = { .signature = 'lock', .id = 1 };
#pragma clang diagnostic pop

+ (void)initialize {

    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        [MPMacConfig get];

#ifdef DEBUG
        [PearlLogger get].printLevel = PearlLogLevelDebug; //Trace;
#endif
    } );
}

static OSStatus MPHotKeyHander(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {

    // Extract the hotkey ID.
    EventHotKeyID hotKeyID;
    GetEventParameter( theEvent, kEventParamDirectObject, typeEventHotKeyID,
            NULL, sizeof( hotKeyID ), NULL, &hotKeyID );

    // Check which hotkey this was.
    if (hotKeyID.signature == MPShowHotKey.signature && hotKeyID.id == MPShowHotKey.id) {
        [((__bridge MPMacAppDelegate *)userData) showPasswordWindow:nil];
        return noErr;
    }
    if (hotKeyID.signature == MPLockHotKey.signature && hotKeyID.id == MPLockHotKey.id) {
        [((__bridge MPMacAppDelegate *)userData) lock:nil];
        return noErr;
    }

    return eventNotHandledErr;
}

#pragma mark - Life

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

#ifdef CRASHLYTICS
    NSString *crashlyticsAPIKey = [self crashlyticsAPIKey];
    if ([crashlyticsAPIKey length]) {
        inf(@"Initializing Crashlytics");
#if DEBUG
        [Crashlytics sharedInstance].debugMode = YES;
#endif
        [[Crashlytics sharedInstance] setUserIdentifier:[PearlKeyChain deviceIdentifier]];
        [[Crashlytics sharedInstance] setObjectValue:[PearlKeyChain deviceIdentifier] forKey:@"deviceIdentifier"];
        [[Crashlytics sharedInstance] setUserName:@"Anonymous"];
        [Crashlytics startWithAPIKey:crashlyticsAPIKey];
        [[PearlLogger get] registerListener:^BOOL(PearlLogMessage *message) {
            PearlLogLevel level = PearlLogLevelInfo;
            if ([[MPConfig get].sendInfo boolValue])
                level = PearlLogLevelDebug;

            if (message.level >= level)
                CLSLog( @"%@", [message messageDescription] );

            return YES;
        }];
        CLSLog( @"Crashlytics (%@) initialized for: %@ v%@.", //
                [Crashlytics sharedInstance].version, [PearlInfoPlist get].CFBundleName, [PearlInfoPlist get].CFBundleVersion );
    }
#endif

    // Setup delegates and listeners.
    [MPConfig get].delegate = self;
    __weak id weakSelf = self;
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        dispatch_async( dispatch_get_main_queue(), ^{
            [weakSelf updateMenuItems];
        } );
    }           forKeyPath:@"key" options:0 context:nil];
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        dispatch_async( dispatch_get_main_queue(), ^{
            [weakSelf updateMenuItems];
        } );
    }           forKeyPath:@"activeUser" options:0 context:nil];

    // Status item.
    self.statusView = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusView.image = [NSImage imageNamed:@"menu-icon"];
    self.statusView.image.template = YES;
    self.statusView.menu = self.statusMenu;
    self.statusView.target = self;
    self.statusView.action = @selector( showMenu );

    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresWillChangeNotification, self.storeCoordinator, nil,
            ^(id self, NSNotification *note) {
                PearlMainQueue( ^{
                    [self updateUsers];
                } );
            } );
    PearlAddNotificationObserver( NSPersistentStoreCoordinatorStoresDidChangeNotification, self.storeCoordinator, nil,
            ^(id self, NSNotification *note) {
                PearlMainQueue( ^{
                    [self updateUsers];
                } );
            } );
    PearlAddNotificationObserver( MPCheckConfigNotification, nil, nil,
            ^(MPMacAppDelegate *self, NSNotification *note) {
                PearlMainQueue( ^{
                    NSString *key = note.object;
                    if (!key || [key isEqualToString:NSStringFromSelector( @selector( hidePasswords ) )])
                        self.hidePasswordsItem.state = [[MPConfig get].hidePasswords boolValue]? NSOnState: NSOffState;
                    if (!key || [key isEqualToString:NSStringFromSelector( @selector( rememberLogin ) )])
                        self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;
                } );
            } );
    [self updateUsers];

    // Global hotkey.
    EventHotKeyRef hotKeyRef;
    EventTypeSpec hotKeyEvents[1] = { { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed } };
    OSStatus status = InstallApplicationEventHandler( NewEventHandlerUPP( MPHotKeyHander ), GetEventTypeCount( hotKeyEvents ), hotKeyEvents,
            (__bridge void *)self, NULL );
    if (status != noErr)
        err( @"Error installing application event handler: %i", (int)status );
    status = RegisterEventHotKey( 35 /* p */, controlKey + cmdKey, MPShowHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
        err( @"Error registering 'show' hotkey: %i", (int)status );
    status = RegisterEventHotKey( 35 /* p */, controlKey + optionKey + cmdKey, MPLockHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
        err( @"Error registering 'lock' hotkey: %i", (int)status );

    // Initial display.
    if ([[MPMacConfig get].firstRun boolValue]) {
        [(self.initialWindowController = [[MPInitialWindowController alloc] initWithWindowNibName:@"MPInitialWindow"])
                .window makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {

    if (![[MPConfig get].rememberLogin boolValue])
        [self lock:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    NSManagedObjectContext *mainContext = [MPMacAppDelegate managedObjectContextForMainThreadIfReady];
    if (!mainContext)
        return NSTerminateNow;

    if (![mainContext commitEditing])
        return NSTerminateCancel;

    if (![mainContext hasChanges])
        return NSTerminateNow;

    [mainContext saveToStore];
    return NSTerminateNow;
}

#pragma mark - State

- (void)setActiveUser:(MPUserEntity *)activeUser {

    [super setActiveUser:activeUser];

    if (activeUser)
        [MPMacConfig get].usedUserName = activeUser.name;

    PearlMainQueue( ^{
        [self updateUsers];
    } );
}

- (void)setLoginItemEnabled:(BOOL)enabled {

    BOOL loginItemEnabled = [self loginItemEnabled];
    if (loginItemEnabled != enabled) {
        if (SMLoginItemSetEnabled( (__bridge CFStringRef)LOGIN_HELPER_BUNDLE_ID, (Boolean)enabled ) == true)
            loginItemEnabled = enabled;
        else
            wrn( @"Failed to set login item." );
    }

    self.openAtLoginItem.state = loginItemEnabled? NSOnState: NSOffState;
    self.initialWindowController.openAtLoginButton.state = loginItemEnabled? NSOnState: NSOffState;
}

- (BOOL)loginItemEnabled {

    // The easy and sane method (SMJobCopyDictionary) can pose problems when the app is sandboxed. -_-
    NSArray *jobs = (__bridge_transfer NSArray *)SMCopyAllJobDictionaries( kSMDomainUserLaunchd );

    for (NSDictionary *job in jobs)
        if ([LOGIN_HELPER_BUNDLE_ID isEqualToString:job[@"Label"]])
            return [job[@"OnDemand"] boolValue];

    return NO;
}

- (BOOL)isFeatureUnlocked:(NSString *)productIdentifier {

    // All features are unlocked for mac versions.
    return YES;
}

#pragma mark - Actions

- (void)selectUser:(NSMenuItem *)item {

    [self signOutAnimated:NO];

    NSManagedObjectContext *mainContext = [MPMacAppDelegate managedObjectContextForMainThreadIfReady];
    self.activeUser = [MPUserEntity existingObjectWithID:[item representedObject] inContext:mainContext];
}

- (IBAction)exportSitesSecure:(id)sender {

    [self exportSitesAndRevealPasswords:NO];
}

- (IBAction)exportSitesReveal:(id)sender {

    [self exportSitesAndRevealPasswords:YES];
}

- (IBAction)importSites:(id)sender {

    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories = NO;
    openPanel.title = @"Master Password";
    openPanel.message = @"Locate the Master Password export file to import.";
    openPanel.prompt = @"Import";
    openPanel.directoryURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    openPanel.allowedFileTypes = @[ @"mpsites" ];
    [NSApp activateIgnoringOtherApps:YES];
    if ([openPanel runModal] == NSFileHandlingPanelCancelButton)
        return;

    NSURL *url = openPanel.URL;
    [openPanel close];

    [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:
            ^(NSData *importedSitesData, NSURLResponse *response, NSError *urlError) {
                if (urlError)
                    [[NSAlert alertWithError:MPError( urlError, @"While reading imported sites from %@.", url )] runModal];
                if (!importedSitesData)
                    return;

                NSString *importedSitesString = [[NSString alloc] initWithData:importedSitesData encoding:NSUTF8StringEncoding];
                [self importSites:importedSitesString askImportPassword:^NSString *(NSString *userName) {
                    __block NSString *masterPassword = nil;

                    PearlMainQueueWait( ^{
                        NSAlert *alert = [NSAlert new];
                        [alert addButtonWithTitle:@"Unlock"];
                        [alert addButtonWithTitle:@"Cancel"];
                        alert.messageText = strf( @"Importing Sites For\n%@", userName );
                        alert.informativeText = @"Enter the master password used to create this export file.";
                        alert.accessoryView = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
                        [alert layout];
                        if ([alert runModal] == NSAlertFirstButtonReturn)
                            masterPassword = ((NSTextField *)alert.accessoryView).stringValue;
                    } );

                    return masterPassword;
                } askUserPassword:^NSString *(NSString *userName) {
                    __block NSString *masterPassword = nil;

                    PearlMainQueueWait( ^{
                        NSAlert *alert = [NSAlert new];
                        [alert addButtonWithTitle:@"Import"];
                        [alert addButtonWithTitle:@"Cancel"];
                        alert.messageText = strf( @"Master Password For\n%@", userName );
                        alert.informativeText = @"Enter the current master password for this user.";
                        alert.accessoryView = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
                        [alert layout];
                        if ([alert runModal] == NSAlertFirstButtonReturn)
                            masterPassword = ((NSTextField *)alert.accessoryView).stringValue;
                    } );

                    return masterPassword;
                }          result:^(NSError *error) {
                    [self updateUsers];

                    if (error && !(error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError))
                        [[NSAlert alertWithError:error] runModal];
                }];
            }] resume];
}

- (IBAction)togglePreference:(id)sender {

    if (sender == self.hidePasswordsItem)
        [MPConfig get].hidePasswords = @(self.hidePasswordsItem.state != NSOnState);
    if (sender == self.rememberPasswordItem)
        [MPConfig get].rememberLogin = @(self.rememberPasswordItem.state != NSOnState);
    if (sender == self.openAtLoginItem)
        [self setLoginItemEnabled:self.openAtLoginItem.state != NSOnState];
    if (sender == self.showFullScreenItem) {
        [MPMacConfig get].fullScreen = @(self.showFullScreenItem.state != NSOnState);
        [NSApp updateWindows];
    }
    if (sender == self.savePasswordItem) {
        [MPMacAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            MPUserEntity *activeUser = [[MPMacAppDelegate get] activeUserInContext:context];
            if ((activeUser.saveKey = !activeUser.saveKey))
                [[MPMacAppDelegate get] storeSavedKeyFor:activeUser];
            else
                [[MPMacAppDelegate get] forgetSavedKeyFor:activeUser];
            [context saveToStore];
        }];
    }

    [MPMacConfig flush];
    [self updateMenuItems];
}

- (IBAction)newUser:(NSMenuItem *)sender {

    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"New User"];
    [alert setInformativeText:@"To begin, enter your full name.\n\n"
            @"IMPORTANT: Enter your name correctly, including the right capitalization, "
            @"as you would on an official document."];
    [alert addButtonWithTitle:@"Create User"];
    [alert addButtonWithTitle:@"Cancel"];
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
    [alert setAccessoryView:nameField];
    [alert layout];
    [nameField becomeFirstResponder];
    if ([alert runModal] != NSAlertFirstButtonReturn)
        return;

    NSString *name = [(NSSecureTextField *)alert.accessoryView stringValue];
    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPUserEntity *newUser = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass( [MPUserEntity class] )
                                                              inManagedObjectContext:context];
        newUser.name = name;
        [context saveToStore];
        [self setActiveUser:newUser];

        PearlMainQueue( ^{
            [self showPasswordWindow:nil];
        } );
    }];
}

- (IBAction)deleteUser:(NSMenuItem *)sender {

    NSAlert *alert = [NSAlert new];
    [alert setMessageText:@"Delete User"];
    [alert setInformativeText:strf( @"This will delete %@ and all their sites.", self.activeUserForMainThread.name )];
    [alert addButtonWithTitle:@"Delete"];
    [alert addButtonWithTitle:@"Cancel"];
    if ([alert runModal] != NSAlertFirstButtonReturn)
        return;

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        [context deleteObject:[self activeUserInContext:context]];
        [self setActiveUser:nil];
        [context saveToStore];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateUsers];
            [self showPasswordWindow:nil];
        }];
    }];
}

- (IBAction)lock:(id)sender {

    [self signOutAnimated:YES];
}

- (IBAction)terminate:(id)sender {

    [self.sitesWindowController close];
    self.sitesWindowController = nil;

    [NSApp terminate:nil];
}

- (IBAction)showPopup:(id)sender {

    [self.statusView popUpStatusItemMenu:self.statusView.menu];
}

- (IBAction)showPasswordWindow:(id)sender {

    prof_new( @"showPasswordWindow" );
    [NSApp activateIgnoringOtherApps:YES];
    prof_rewind( @"activateIgnoringOtherApps" );

    // If no user, can't activate.
    if (![self activeUserForMainThread]) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"No User Selected";
        alert.informativeText = @"Begin by selecting or creating your user from the status menu (●●●|) next to the clock.";
        [alert runModal];
        [self showPopup:nil];
        prof_finish( @"activeUserForMainThread" );
        return;
    }
    prof_rewind( @"activeUserForMainThread" );

    // Don't show window if we weren't already running (ie. if we haven't been activated before).
    if (!self.sitesWindowController)
        self.sitesWindowController = [[MPSitesWindowController alloc] initWithWindowNibName:@"MPSitesWindowController"];
    prof_rewind( @"initWithWindow" );

    [self.sitesWindowController showWindow:self];
    prof_finish( @"showWindow" );
}

#pragma mark - Private

- (void)exportSitesAndRevealPasswords:(BOOL)revealPasswords {

    MPUserEntity *mainActiveUser = [self activeUserForMainThread];
    if (!mainActiveUser) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"No User Selected";
        alert.informativeText = @"To export your sites, first select the user whose sites to export.";
        [alert runModal];
        [self showPopup:nil];
        return;
    }

    if (!self.key) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"User Locked";
        alert.informativeText = @"To export your sites, first unlock your user by opening Master Password.";
        [alert runModal];
        [self showPopup:nil];
        return;
    }

    NSDateFormatter *exportDateFormatter = [NSDateFormatter new];
    [exportDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];

    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.title = @"Master Password";
    savePanel.message = @"Pick a location for the export Master Password's sites.";
    if (revealPasswords)
        savePanel.message = strf( @"%@\nWARNING: Your passwords will be visible.  Make sure to always keep the file in a secure location.",
                savePanel.message );
    savePanel.prompt = @"Export";
    savePanel.directoryURL = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    savePanel.nameFieldStringValue = strf( @"%@ (%@).mpsites", mainActiveUser.name,
            [exportDateFormatter stringFromDate:[NSDate date]] );
    savePanel.allowedFileTypes = @[ @"mpsites" ];
    [NSApp activateIgnoringOtherApps:YES];
    if ([savePanel runModal] == NSFileHandlingPanelCancelButton)
        return;

    [self exportSitesRevealPasswords:revealPasswords
                   askExportPassword:^NSString *(NSString *userName) {
                       return PearlMainQueueAwait( ^id {
                           NSAlert *alert = [NSAlert new];
                           [alert addButtonWithTitle:@"Import"];
                           [alert addButtonWithTitle:@"Cancel"];
                           alert.messageText = strf( @"Master Password For\n%@", userName );
                           alert.informativeText = @"Enter the current master password for this user.";
                           alert.accessoryView = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
                           [alert layout];
                           if ([alert runModal] == NSAlertFirstButtonReturn)
                               return ((NSTextField *)alert.accessoryView).stringValue;
                           else
                               return nil;
                       } );
                   } result:^(NSString *mpsites, NSError *error) {
                if (!mpsites || error) {
                    PearlMainQueue( ^{
                        [[NSAlert alertWithError:MPError( error, @"Failed to export mpsites." )] runModal];
                    } );
                    return;
                }

                NSError *coordinateError = nil;
                [[[NSFileCoordinator alloc] initWithFilePresenter:nil]
                        coordinateWritingItemAtURL:savePanel.URL options:0 error:&coordinateError byAccessor:^(NSURL *newURL) {
                    NSError *writeError = nil;
                    if (![mpsites writeToURL:newURL atomically:NO encoding:NSUTF8StringEncoding error:&writeError])
                        PearlMainQueue( ^{
                            [[NSAlert alertWithError:MPError( writeError, @"Could not write to the export file." )] runModal];
                        } );
                }];
                if (coordinateError)
                    PearlMainQueue( ^{
                        [[NSAlert alertWithError:MPError( coordinateError, @"Could not gain access to the export file." )] runModal];
                    } );
            }];
}

- (void)updateUsers {

    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > 2)
            [[self.usersItem submenu] removeItem:obj];
    }];

    NSManagedObjectContext *mainContext = [MPMacAppDelegate managedObjectContextForMainThreadIfReady];
    if (!mainContext) {
        self.createUserItem.title = @"New User (Not ready)";
        self.createUserItem.enabled = NO;
        self.createUserItem.toolTip = @"Please wait until the app is fully loaded.";
        self.deleteUserItem.title = @"Delete User (Not ready)";
        self.deleteUserItem.enabled = NO;
        self.deleteUserItem.toolTip = @"Please wait until the app is fully loaded.";
        [self.usersItem.submenu addItemWithTitle:@"Loading..." action:NULL keyEquivalent:@""].enabled = NO;

        return;
    }

    MPUserEntity *mainActiveUser = [self activeUserInContext:mainContext];

    self.createUserItem.title = @"New User";
    self.createUserItem.enabled = YES;
    self.createUserItem.toolTip = nil;

    self.deleteUserItem.title = mainActiveUser? @"Delete User": @"Delete User (None Selected)";
    self.deleteUserItem.enabled = mainActiveUser != nil;
    self.deleteUserItem.toolTip = mainActiveUser? nil: @"First select the user to delete.";

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO] ];
    NSArray *users = [mainContext executeFetchRequest:fetchRequest error:&error];
    if (!users)
        MPError( error, @"Failed to load users." );

    if (![users count]) {
        NSMenuItem *noUsersItem = [self.usersItem.submenu addItemWithTitle:@"No users" action:NULL keyEquivalent:@""];
        noUsersItem.enabled = NO;
        noUsersItem.toolTip = @"Begin by creating a user.";
    }

    self.usersItem.state = NSMixedState;
    for (MPUserEntity *user in users) {
        NSMenuItem *userItem = [[NSMenuItem alloc] initWithTitle:user.name action:@selector( selectUser: ) keyEquivalent:@""];
        [userItem setTarget:self];
        [userItem setRepresentedObject:user.permanentObjectID];
        [[self.usersItem submenu] addItem:userItem];

        if (!mainActiveUser && [user.name isEqualToString:[MPMacConfig get].usedUserName])
            [super setActiveUser:mainActiveUser = user];

        if ([mainActiveUser isEqual:user]) {
            userItem.state = NSOnState;
            self.usersItem.state = NSOffState;
        }
        else
            userItem.state = NSOffState;
    }

    [self updateMenuItems];
}

- (void)showMenu {

    [self updateMenuItems];

    [self.statusView popUpStatusItemMenu:self.statusView.menu];
}

- (void)updateMenuItems {

    MPUserEntity *activeUser = [self activeUserForMainThread];
//    if (!(self.showItem.enabled = ![self.sitesWindowController.window isVisible])) {
//        self.showItem.title = @"Show (Showing)";
//        self.showItem.toolTip = @"Master Password is already showing.";
//    }
//    else if (!(self.showItem.enabled = (activeUser != nil))) {
//        self.showItem.title = @"Show (No user)";
//        self.showItem.toolTip = @"First select the user to show passwords for.";
//    }
//    else {
//        self.showItem.title = @"Show";
//        self.showItem.toolTip = nil;
//    }

    if (self.key) {
        self.lockItem.title = @"Lock";
        self.lockItem.enabled = YES;
        self.lockItem.toolTip = nil;
    }
    else {
        self.lockItem.title = @"Lock (Locked)";
        self.lockItem.enabled = NO;
        self.lockItem.toolTip = @"Master Password is currently locked.";
    }

    BOOL loginItemEnabled = [self loginItemEnabled];
    self.openAtLoginItem.state = loginItemEnabled? NSOnState: NSOffState;
    self.showFullScreenItem.state = [[MPMacConfig get].fullScreen boolValue]? NSOnState: NSOffState;
    self.initialWindowController.openAtLoginButton.state = loginItemEnabled? NSOnState: NSOffState;
    self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;

    self.savePasswordItem.state = activeUser.saveKey? NSOnState: NSOffState;
    if (!activeUser) {
        self.savePasswordItem.title = @"Save Password (No user)";
        self.savePasswordItem.enabled = NO;
        self.savePasswordItem.toolTip = @"First select your user and unlock by showing the Master Password window.";
    }
    else if (!self.key) {
        self.savePasswordItem.title = @"Save Password (Locked)";
        self.savePasswordItem.enabled = NO;
        self.savePasswordItem.toolTip = @"First unlock by showing the Master Password window.";
    }
    else {
        self.savePasswordItem.title = @"Save Password";
        self.savePasswordItem.enabled = YES;
        self.savePasswordItem.toolTip = nil;
    }
}

#pragma mark - PearlConfigDelegate

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)oldValue {

    [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:NSStringFromSelector( configKey )];
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
