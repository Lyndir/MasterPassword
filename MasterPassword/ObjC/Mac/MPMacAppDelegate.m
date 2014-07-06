//
//  MPMacAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "MPPasswordWindowController.h"
#import "PearlProfiler.h"
#import <Carbon/Carbon.h>
#import <ServiceManagement/ServiceManagement.h>

#define LOGIN_HELPER_BUNDLE_ID @"com.lyndir.lhunath.MasterPassword.Mac.LoginHelper"

@interface UbiquityStoreManager(Private)

- (void)markCloudStoreCorrupted;

@end

@implementation MPMacAppDelegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
static EventHotKeyID MPShowHotKey = { .signature = 'show', .id = 1 };
static EventHotKeyID MPLockHotKey = { .signature = 'lock', .id = 1 };
#pragma clang diagnostic pop

+ (void)initialize {

    static dispatch_once_t initialize = 0;
    dispatch_once( &initialize, ^{
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
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        dispatch_async( dispatch_get_main_queue(), ^{
            [weakSelf updateMenuItems];
        } );
    }           forKeyPath:@"storeManager.cloudAvailable" options:0 context:nil];

    // Status item.
    self.statusView = [[RHStatusItemView alloc] initWithStatusBarItem:
            [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength]];
    self.statusView.image = [NSImage imageNamed:@"menu-icon"];
    self.statusView.menu = self.statusMenu;
    self.statusView.target = self;
    self.statusView.action = @selector( showMenu );

    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidChangeNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updateUsers];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidImportChangesNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self updateUsers];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPCheckConfigNotification object:nil
                                                       queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        NSString *key = note.object;
        if (!key || [key isEqualToString:NSStringFromSelector( @selector( hidePasswords ) )])
            self.hidePasswordsItem.state = [[MPConfig get].hidePasswords boolValue]? NSOnState: NSOffState;
        if (!key || [key isEqualToString:NSStringFromSelector( @selector( rememberLogin ) )])
            self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;
    }];
    [self updateUsers];

    // Global hotkey.
    EventHotKeyRef hotKeyRef;
    EventTypeSpec hotKeyEvents[1] = { { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed } };
    OSStatus status = InstallApplicationEventHandler( NewEventHandlerUPP( MPHotKeyHander ), GetEventTypeCount( hotKeyEvents ),
            hotKeyEvents, (__bridge void *)self, NULL );
    if (status != noErr)
        err( @"Error installing application event handler: %i", (int)status );
    status = RegisterEventHotKey( 35 /* p */, controlKey + cmdKey, MPShowHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
        err( @"Error registering 'show' hotkey: %i", (int)status );
    status = RegisterEventHotKey( 35 /* p */, controlKey + optionKey + cmdKey, MPLockHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
        err( @"Error registering 'lock' hotkey: %i", (int)status );

    // Initial display.
    if ([[MPMacConfig get].firstRun boolValue]){
        [(self.initialWindowController = [[MPInitialWindowController alloc] initWithWindowNibName:@"MPInitialWindow"]).window makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {

    if (![[MPConfig get].rememberLogin boolValue])
        [self lock:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    NSManagedObjectContext *context = [MPMacAppDelegate managedObjectContextForMainThreadIfReady];
    if (!context)
        return NSTerminateNow;

    if (![context commitEditing])
        return NSTerminateCancel;

    if (![context hasChanges])
        return NSTerminateNow;

    [context saveToStore];
    return NSTerminateNow;
}

#pragma mark - State

- (void)setActiveUser:(MPUserEntity *)activeUser {

    [super setActiveUser:activeUser];

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
        if ([LOGIN_HELPER_BUNDLE_ID isEqualToString:[job objectForKey:@"Label"]]) {
            dbg( @"loginItemEnabled: %@", @([[job objectForKey:@"OnDemand"] boolValue]) );
            return [[job objectForKey:@"OnDemand"] boolValue];
        }

    dbg( @"loginItemEnabled: not found" );
    return NO;
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

    PearlNotMainQueue( ^{
        NSError *error;
        NSURLResponse *response;
        NSData *importedSitesData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
                                                          returningResponse:&response error:&error];
        if (error)
            err( @"While reading imported sites from %@: %@", url, error );
        if (!importedSitesData)
            return;

        NSString *importedSitesString = [[NSString alloc] initWithData:importedSitesData encoding:NSUTF8StringEncoding];
        MPImportResult result = [self importSites:importedSitesString askImportPassword:^NSString *(NSString *userName) {
            __block NSString *masterPassword = nil;

            PearlMainQueueWait( ^{
                NSAlert *alert = [NSAlert new];
                [alert addButtonWithTitle:@"Unlock"];
                [alert addButtonWithTitle:@"Cancel"];
                alert.messageText = @"Import File's Master Password";
                alert.informativeText = strf( @"%@'s export was done using a different master password.\n"
                        @"Enter that master password to unlock the exported data.", userName );
                alert.accessoryView = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
                [alert layout];
                if ([alert runModal] == NSAlertFirstButtonReturn)
                    masterPassword = ((NSTextField *)alert.accessoryView).stringValue;
            } );

            return masterPassword;
        }                         askUserPassword:^NSString *(NSString *userName, NSUInteger importCount, NSUInteger deleteCount) {
            __block NSString *masterPassword = nil;

            PearlMainQueueWait( ^{
                NSAlert *alert = [NSAlert new];
                [alert addButtonWithTitle:@"Import"];
                [alert addButtonWithTitle:@"Cancel"];
                alert.messageText = strf( @"Master Password for\n%@", userName );
                alert.informativeText = strf( @"Imports %lu sites, overwriting %lu.",
                        (unsigned long)importCount, (unsigned long)deleteCount );
                alert.accessoryView = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
                [alert layout];
                if ([alert runModal] == NSAlertFirstButtonReturn)
                    masterPassword = ((NSTextField *)alert.accessoryView).stringValue;
            } );

            return masterPassword;
        }];

        PearlMainQueue( ^{
            switch (result) {
                case MPImportResultSuccess: {
                    [self updateUsers];

                    NSAlert *alert = [NSAlert new];
                    alert.messageText = @"Successfully imported sites.";
                    [alert runModal];
                    break;
                }
                case MPImportResultCancelled:
                    break;
                case MPImportResultInternalError:
                    [NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey : @"Import failed because of an internal error."
                    }]];
                    break;
                case MPImportResultMalformedInput:
                    [NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey : @"The import doesn't look like a Master Password export."
                    }]];
                    break;
                case MPImportResultInvalidPassword:
                    [NSAlert alertWithError:[NSError errorWithDomain:MPErrorDomain code:0 userInfo:@{
                            NSLocalizedDescriptionKey : @"Incorrect master password for the import sites."
                    }]];
                    break;
            }
        } );
    } );
}

- (IBAction)togglePreference:(id)sender {

    if (sender == self.useCloudItem)
        [self storeManager].cloudEnabled = self.useCloudItem.state != NSOnState;
    if (sender == self.hidePasswordsItem)
        [MPConfig get].hidePasswords = [NSNumber numberWithBool:![[MPConfig get].hidePasswords boolValue]];
    if (sender == self.rememberPasswordItem)
        [MPConfig get].rememberLogin = [NSNumber numberWithBool:![[MPConfig get].rememberLogin boolValue]];
    if (sender == self.openAtLoginItem)
        [self setLoginItemEnabled:self.openAtLoginItem.state != NSOnState];
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
}

- (IBAction)newUser:(NSMenuItem *)sender {

    NSAlert *alert = [NSAlert alertWithMessageText:@"New User"
                                     defaultButton:@"Create User" alternateButton:nil otherButton:@"Cancel"
                         informativeTextWithFormat:@"To begin, enter your full name.\n\n"
                                 @"IMPORTANT: Enter your name correctly, including the right capitalization, "
                                 @"as you would on an official document."];
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
    [alert setAccessoryView:nameField];
    [alert layout];
    [nameField becomeFirstResponder];
    if ([alert runModal] != NSAlertDefaultReturn)
        return;

    NSString *name = [(NSSecureTextField *)alert.accessoryView stringValue];
    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        MPUserEntity *newUser = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass( [MPUserEntity class] )
                                                              inManagedObjectContext:moc];
        newUser.name = name;
        [moc saveToStore];
        NSError *error = nil;
        if (![moc obtainPermanentIDsForObjects:@[ newUser ] error:&error])
            err( @"Failed to obtain permanent object ID for new user: %@", error );

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateUsers];
            [self setActiveUser:newUser];
            [self showPasswordWindow:nil];
        }];
    }];
}

- (IBAction)deleteUser:(NSMenuItem *)sender {

    NSAlert *alert = [NSAlert alertWithMessageText:@"Delete User"
                                     defaultButton:@"Delete" alternateButton:nil otherButton:@"Cancel"
                         informativeTextWithFormat:@"This will delete %@ and all his sites.", self.activeUserForMainThread.name];
    if ([alert runModal] != NSAlertDefaultReturn)
        return;

    [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        [moc deleteObject:[self activeUserInContext:moc]];
        [self setActiveUser:nil];
        [moc saveToStore];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateUsers];
            [self showPasswordWindow:nil];
        }];
    }];
}

- (IBAction)lock:(id)sender {

    self.key = nil;
}

- (IBAction)rebuildCloud:(id)sender {

    if ([[NSAlert alertWithMessageText:@"iCloud Truth Push" defaultButton:@"Continue"
                       alternateButton:nil otherButton:@"Cancel"
             informativeTextWithFormat:@"This action will force all your iCloud enabled devices to switch to this device's version of the truth."
                     @"\n\nThis is only necessary if you notice that your devices aren't syncing properly anymore.  "
                     "Any data on other devices not available from here will be lost."] runModal] == NSAlertDefaultReturn)
        [self.storeManager rebuildCloudContentFromCloudStoreOrLocalStore:NO];
}

- (IBAction)corruptCloud:(id)sender {

    if ([[NSAlert alertWithMessageText:@"iCloud Truth Pull" defaultButton:@"Continue"
                       alternateButton:nil otherButton:@"Cancel"
             informativeTextWithFormat:@"This action will force another iCloud enabled device to push their version of the truth on all."
                     @"\n\nThis is only necessary if you notice that your devices aren't syncing properly anymore.  "
                     "Any data on this device not available from the other will be lost."] runModal] == NSAlertDefaultReturn)
        [self.storeManager markCloudStoreCorrupted];
}

- (IBAction)terminate:(id)sender {

    [self.passwordWindowController close];
    self.passwordWindowController = nil;

    [NSApp terminate:nil];
}

- (IBAction)showPopup:(id)sender {

    [self.statusView popUpMenu];
}

- (IBAction)showPasswordWindow:(id)sender {

    [NSApp activateIgnoringOtherApps:YES];

    // If no user, can't activate.
    if (![self activeUserForMainThread]) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"No User Selected";
        alert.informativeText = @"Begin by selecting or creating your user from the status menu (●●●|) next to the clock.";
        [alert runModal];
        [self showPopup:nil];
        return;
    }

    // Don't show window if we weren't already running (ie. if we haven't been activated before).
    PearlProfiler *profiler = [PearlProfiler profilerForTask:@"passwordWindowController"];
    if (!self.passwordWindowController)
        self.passwordWindowController = [[MPPasswordWindowController alloc] initWithWindowNibName:@"MPPasswordWindowController"];
    [profiler finishJob:@"init"];

    [self.passwordWindowController showWindow:self];
    [profiler finishJob:@"show"];
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

    NSError *coordinateError = nil;
    NSString *exportedSites = [self exportSitesRevealPasswords:revealPasswords];
    [[[NSFileCoordinator alloc] initWithFilePresenter:nil] coordinateWritingItemAtURL:savePanel.URL options:0 error:&coordinateError
                                                                           byAccessor:^(NSURL *newURL) {
        NSError *writeError = nil;
        if (![exportedSites writeToURL:newURL atomically:NO encoding:NSUTF8StringEncoding error:&writeError])
            PearlMainQueue( ^{
                [[NSAlert alertWithError:writeError] runModal];
            } );
    }];
    if (coordinateError)
        PearlMainQueue( ^{
            [[NSAlert alertWithError:coordinateError] runModal];
        } );
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
        err( @"Failed to load users: %@", error );

    if (![users count]) {
        NSMenuItem *noUsersItem = [self.usersItem.submenu addItemWithTitle:@"No users" action:NULL keyEquivalent:@""];
        noUsersItem.enabled = NO;
        noUsersItem.toolTip = @"Use the iOS app to create users and make sure iCloud is enabled in its preferences as well.  "
                @"Then give iCloud some time to sync the new user to your Mac.";
    }

    self.usersItem.state = NSMixedState;
    for (MPUserEntity *user in users) {
        NSMenuItem *userItem = [[NSMenuItem alloc] initWithTitle:user.name action:@selector( selectUser: ) keyEquivalent:@""];
        [userItem setTarget:self];
        [userItem setRepresentedObject:[user objectID]];
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

    [self.statusView popUpMenu];
}

- (void)updateMenuItems {

    MPUserEntity *activeUser = [self activeUserForMainThread];
//    if (!(self.showItem.enabled = ![self.passwordWindowController.window isVisible])) {
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

    self.useCloudItem.state = self.storeManager.cloudEnabled? NSOnState: NSOffState;
    self.initialWindowController.enableCloudButton.state = self.storeManager.cloudEnabled? NSOnState: NSOffState;
    self.useCloudItem.enabled = self.storeManager.cloudAvailable;
    if (self.storeManager.cloudAvailable) {
        self.useCloudItem.title = @"Use iCloud";
        self.useCloudItem.toolTip = nil;
    }
    else {
        self.useCloudItem.title = @"Use iCloud (Unavailable)";
        self.useCloudItem.toolTip = @"iCloud is not set up for your Mac user.";
    }
}

#pragma mark - PearlConfigDelegate

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)oldValue {

    [[NSNotificationCenter defaultCenter] postNotificationName:MPCheckConfigNotification object:NSStringFromSelector( configKey )];
}

@end
