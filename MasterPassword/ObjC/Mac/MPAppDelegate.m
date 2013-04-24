//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import <Carbon/Carbon.h>

@interface MPAppDelegate ()

@property(nonatomic) BOOL wasRunning;

@end

@implementation MPAppDelegate

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
static EventHotKeyID MPShowHotKey = { .signature = 'show', .id = 1 };
static EventHotKeyID MPLockHotKey = { .signature = 'lock', .id = 1 };
#pragma clang diagnostic pop

+ (void)initialize {

    static dispatch_once_t initialize;
    dispatch_once( &initialize, ^{
        [MPMacConfig get];

#ifdef DEBUG
        [PearlLogger get].printLevel = PearlLogLevelDebug;//Trace;
#endif
    } );
}

static OSStatus MPHotKeyHander(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {

    // Extract the hotkey ID.
    EventHotKeyID hotKeyID;
    GetEventParameter( theEvent, kEventParamDirectObject, typeEventHotKeyID,
            NULL, sizeof(hotKeyID), NULL, &hotKeyID );

    // Check which hotkey this was.
    if (hotKeyID.signature == MPShowHotKey.signature && hotKeyID.id == MPShowHotKey.id) {
        [((__bridge MPAppDelegate *)userData) activate:nil];
        return noErr;
    }
    if (hotKeyID.signature == MPLockHotKey.signature && hotKeyID.id == MPLockHotKey.id) {
        [((__bridge MPAppDelegate *)userData) lock:nil];
        return noErr;
    }

    return eventNotHandledErr;
}

- (void)updateUsers {

    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > 1)
            [[self.usersItem submenu] removeItem:obj];
    }];

    NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextForThreadIfReady];
    if (!moc) {
        self.createUserItem.title = @"New User (Not ready)";
        self.createUserItem.enabled = NO;
        self.createUserItem.toolTip = @"Please wait until the app is fully loaded.";
        [self.usersItem.submenu addItemWithTitle:@"Loading..." action:NULL keyEquivalent:@""].enabled = NO;

        return;
    }

    self.createUserItem.title = @"New User";
    self.createUserItem.enabled = YES;
    self.createUserItem.toolTip = nil;

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPUserEntity class] )];
    fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO] ];
    NSArray *users = [moc executeFetchRequest:fetchRequest error:&error];
    if (!users)
    err(@"Failed to load users: %@", error);

    if (![users count]) {
        NSMenuItem *noUsersItem = [self.usersItem.submenu addItemWithTitle:@"No users" action:NULL keyEquivalent:@""];
        noUsersItem.enabled = NO;
        noUsersItem.toolTip = @"Use the iOS app to create users and make sure iCloud is enabled in its preferences as well.  "
                @"Then give iCloud some time to sync the new user to your Mac.";
    }

    for (MPUserEntity *user in users) {
        NSMenuItem *userItem = [[NSMenuItem alloc] initWithTitle:user.name action:@selector(selectUser:) keyEquivalent:@""];
        [userItem setTarget:self];
        [userItem setRepresentedObject:[user objectID]];
        [[self.usersItem submenu] addItem:userItem];

        if ([user.name isEqualToString:[MPMacConfig get].usedUserName])
            [self selectUser:userItem];
    }
}

- (void)selectUser:(NSMenuItem *)item {

    NSError *error = nil;
    NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextForThreadIfReady];
    self.activeUser = (MPUserEntity *)[moc existingObjectWithID:[item representedObject] error:&error];

    if (error)
    err(@"While looking up selected user: %@", error);
}

- (void)showMenu {

    [self updateMenuItems];

    [self.statusItem popUpStatusItemMenu:self.statusMenu];
}

- (IBAction)activate:(id)sender {

    if (![self activeUserForThread])
            // No user, can't activate.
        return;

    if ([[NSApplication sharedApplication] isActive])
        [self applicationDidBecomeActive:nil];
    else
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)togglePreference:(NSMenuItem *)sender {

    if (sender == self.useICloudItem)
        [self storeManager].cloudEnabled = sender.state == NSOnState;
    if (sender == self.rememberPasswordItem)
        [MPConfig get].rememberLogin = [NSNumber numberWithBool:![[MPConfig get].rememberLogin boolValue]];
    if (sender == self.savePasswordItem) {
        MPUserEntity *activeUser = [[MPAppDelegate get] activeUserForThread];
        if ((activeUser.saveKey = !activeUser.saveKey))
            [[MPAppDelegate get] storeSavedKeyFor:activeUser];
        else
            [[MPAppDelegate get] forgetSavedKeyFor:activeUser];
        [activeUser.managedObjectContext saveToStore];
    }
    if (sender == self.dialogStyleRegular)
        [MPMacConfig get].dialogStyleHUD = @NO;
    if (sender == self.dialogStyleHUD)
        [MPMacConfig get].dialogStyleHUD = @YES;
}

- (IBAction)newUser:(NSMenuItem *)sender {
}

- (IBAction)signOut:(id)sender {

    [self signOutAnimated:YES];
}

- (IBAction)lock:(id)sender {

    self.key = nil;
}

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)oldValue {

    [[NSNotificationCenter defaultCenter]
            postNotificationName:MPCheckConfigNotification object:NSStringFromSelector( configKey ) userInfo:nil];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    [[NSUbiquitousKeyValueStore defaultStore] setString:@"0B3CA2DF-5796-44DF-B5E0-121EC3846464" forKey:@"USMStoreUUIDKey"];
    // Setup delegates and listeners.
    [MPConfig get].delegate = self;
    __weak id weakSelf = self;
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        [weakSelf updateMenuItems];
    }           forKeyPath:@"key" options:NSKeyValueObservingOptionInitial context:nil];
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        [weakSelf updateMenuItems];
    }           forKeyPath:@"activeUser" options:NSKeyValueObservingOptionInitial context:nil];

    // Status item.
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"menu-icon"];
    self.statusItem.highlightMode = YES;
    self.statusItem.target = self;
    self.statusItem.action = @selector(showMenu);

    [[NSNotificationCenter defaultCenter] addObserverForName:UbiquityManagedStoreDidChangeNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateUsers];
            }];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:UbiquityManagedStoreDidImportChangesNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateUsers];
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPCheckConfigNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;
                self.savePasswordItem.state = [[MPAppDelegate get] activeUserForThread].saveKey? NSOnState: NSOffState;
                self.dialogStyleRegular.state = ![[MPMacConfig get].dialogStyleHUD boolValue]? NSOnState: NSOffState;
                self.dialogStyleHUD.state = [[MPMacConfig get].dialogStyleHUD boolValue]? NSOnState: NSOffState;
                if ([note.object isEqual:NSStringFromSelector( @selector(dialogStyleHUD) )]) {
                    if (![self.passwordWindow.window isVisible])
                        self.passwordWindow = nil;
                    else {
                        [self.passwordWindow close];
                        self.passwordWindow = nil;
                        [self showPasswordWindow];
                    }
                }
            }];
    [self updateUsers];

    // Global hotkey.
    EventHotKeyRef hotKeyRef;
    EventTypeSpec hotKeyEvents[1] = { { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed } };
    OSStatus status = InstallApplicationEventHandler(NewEventHandlerUPP( MPHotKeyHander ), GetEventTypeCount( hotKeyEvents ),
    hotKeyEvents,
    (__bridge void *)self, NULL);
    if (status != noErr)
    err(@"Error installing application event handler: %d", status);
    status = RegisterEventHotKey( 35 /* p */, controlKey + cmdKey, MPShowHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
    err(@"Error registering 'show' hotkey: %d", status);
    status = RegisterEventHotKey( 35 /* p */, controlKey + optionKey + cmdKey, MPLockHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
    err(@"Error registering 'lock' hotkey: %d", status);
}

- (void)setActiveUser:(MPUserEntity *)activeUser {

    [self.passwordWindow close];

    [super setActiveUser:activeUser];

    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj representedObject] isEqual:[activeUser objectID]])
            [obj setState:NSOnState];
        else
            [obj setState:NSOffState];
    }];

    [MPMacConfig get].usedUserName = activeUser.name;
}

- (void)updateMenuItems {

    MPUserEntity *activeUser = [self activeUserForThread];
    if (!(self.showItem.enabled = ![self.passwordWindow.window isVisible])) {
        self.showItem.title = @"Show (Showing)";
        self.showItem.toolTip = @"Master Password is already showing.";
    }
    else if (!(self.showItem.enabled = (activeUser != nil))) {
        self.showItem.title = @"Show (No user)";
        self.showItem.toolTip = @"First select the user to show passwords for.";
    }
    else {
        self.showItem.title = @"Show";
        self.showItem.toolTip = nil;
    }

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

    self.useICloudItem.state = self.storeManager.cloudEnabled? NSOnState: NSOffState;
    self.useICloudItem.enabled = !self.storeManager.cloudEnabled;
    if (self.storeManager.cloudEnabled) {
        self.useICloudItem.title = @"Use iCloud (Required)";
        self.useICloudItem.toolTip = @"iCloud is required in this version.  Future versions will work without iCloud as well.";
    }
    else {
        self.useICloudItem.title = @"Use iCloud (Required)";
        self.useICloudItem.toolTip = nil;
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {

    [self showPasswordWindow];
}

- (void)showPasswordWindow {

    // Don't show window if we weren't already running (ie. if we haven't been activated before).
    if (!self.wasRunning)
        self.wasRunning = YES;
    else {
        if (!self.passwordWindow)
            self.passwordWindow = [[MPPasswordWindowController alloc] initWithWindowNibName:@"MPPasswordWindowController"];

        [self.passwordWindow showWindow:self];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification {

    if (![[MPConfig get].rememberLogin boolValue])
        self.key = nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextForThreadIfReady];
    if (!moc)
        return NSTerminateNow;

    if (![moc commitEditing])
        return NSTerminateCancel;

    if (![moc hasChanges])
        return NSTerminateNow;

    [moc saveToStore];
    return NSTerminateNow;
}

#pragma mark - UbiquityStoreManagerDelegate
- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager willLoadStoreIsCloud:(BOOL)isCloudStore {

    manager.cloudEnabled = YES;

    [super ubiquityStoreManager:manager willLoadStoreIsCloud:isCloudStore];
}

@end
