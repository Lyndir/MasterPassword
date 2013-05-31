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
#import <Carbon/Carbon.h>

@interface MPMacAppDelegate()

@property(nonatomic, strong) NSWindowController *appsWindow;
@end

@implementation MPMacAppDelegate

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
        [((__bridge MPMacAppDelegate *)userData) showPasswordWindow:nil];
        return noErr;
    }
    if (hotKeyID.signature == MPLockHotKey.signature && hotKeyID.id == MPLockHotKey.id) {
        [((__bridge MPMacAppDelegate *)userData) lock:nil];
        return noErr;
    }

    return eventNotHandledErr;
}

- (void)updateUsers {

    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > 1)
            [[self.usersItem submenu] removeItem:obj];
    }];

    NSManagedObjectContext *moc = [MPMacAppDelegate managedObjectContextForThreadIfReady];
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

    MPUserEntity *activeUser = self.activeUserForThread;
    for (MPUserEntity *user in users) {
        NSMenuItem *userItem = [[NSMenuItem alloc] initWithTitle:user.name action:@selector(selectUser:) keyEquivalent:@""];
        [userItem setTarget:self];
        [userItem setRepresentedObject:[user objectID]];
        [[self.usersItem submenu] addItem:userItem];

        if (!activeUser && [user.name isEqualToString:[MPMacConfig get].usedUserName])
            [self selectUser:userItem];
    }
    
    [self updateMenuItems];
}

- (void)selectUser:(NSMenuItem *)item {

    [self signOutAnimated:NO];

    NSError *error = nil;
    NSManagedObjectContext *moc = [MPMacAppDelegate managedObjectContextForThreadIfReady];
    self.activeUser = (MPUserEntity *)[moc existingObjectWithID:[item representedObject] error:&error];

    if (error)
    err(@"While looking up selected user: %@", error);
}

- (void)showMenu {

    [self updateMenuItems];

    [self.statusItem popUpStatusItemMenu:self.statusMenu];
}

- (IBAction)togglePreference:(NSMenuItem *)sender {

    if (sender == self.useICloudItem)
        [self storeManager].cloudEnabled = !(sender.state == NSOnState);
    if (sender == self.rememberPasswordItem)
        [MPConfig get].rememberLogin = [NSNumber numberWithBool:![[MPConfig get].rememberLogin boolValue]];
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
    if (sender == self.dialogStyleRegular)
        [MPMacConfig get].dialogStyleHUD = @NO;
    if (sender == self.dialogStyleHUD)
        [MPMacConfig get].dialogStyleHUD = @YES;
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
        err(@"Failed to obtain permanent object ID for new user: %@", error);

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateUsers];
            [self setActiveUser:newUser];
            [self showPasswordWindow:nil];
        }];
    }];
}

- (IBAction)lock:(id)sender {

    self.key = nil;
}

- (IBAction)rebuildCloud:(id)sender {

    if ([[NSAlert alertWithMessageText:@"iCloud Truth Sync" defaultButton:@"Continue"
                       alternateButton:nil otherButton:@"Cancel"
             informativeTextWithFormat:@"This action will force all your iCloud enabled devices to revert to this device's version of the truth."
                     @"\n\nThis is only necessary if you notice that your devices aren't syncing properly anymore.  "
                     "Any data on other devices not available from here will be lost."] runModal] == NSAlertDefaultReturn)
        [self.storeManager rebuildCloudContentFromCloudStoreOrLocalStore:NO];
}

- (IBAction)terminate:(id)sender {

    [self.passwordWindow close];
    self.passwordWindow = nil;
    
    [NSApp terminate:nil];
}

- (IBAction)iphoneAppStore:(id)sender {

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/id510296984"]];

    [self.appWindowDontShow.window close];
    self.appWindowDontShow = nil;
}

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)oldValue {

    [[NSNotificationCenter defaultCenter]
            postNotificationName:MPCheckConfigNotification object:NSStringFromSelector( configKey ) userInfo:nil];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Setup delegates and listeners.
    [MPConfig get].delegate = self;
    __weak id weakSelf = self;
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        [weakSelf updateMenuItems];
    }           forKeyPath:@"key" options:0 context:nil];
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        [weakSelf updateMenuItems];
    }           forKeyPath:@"activeUser" options:0 context:nil];
    [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        [weakSelf updateMenuItems];
    }           forKeyPath:@"storeManager.cloudAvailable" options:0 context:nil];

    // Status item.
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.image = [NSImage imageNamed:@"menu-icon"];
    self.statusItem.highlightMode = YES;
    self.statusItem.target = self;
    self.statusItem.action = @selector(showMenu);

    [[NSNotificationCenter defaultCenter] addObserverForName:USMStoreDidChangeNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateUsers];
            }];
    [[NSNotificationCenter defaultCenter]
            addObserverForName:USMStoreDidImportChangesNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateUsers];
            }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MPCheckConfigNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;
                self.savePasswordItem.state = [[MPMacAppDelegate get] activeUserForThread].saveKey? NSOnState: NSOffState;
                self.dialogStyleRegular.state = ![[MPMacConfig get].dialogStyleHUD boolValue]? NSOnState: NSOffState;
                self.dialogStyleHUD.state = [[MPMacConfig get].dialogStyleHUD boolValue]? NSOnState: NSOffState;
                
                if ([note.object isEqual:NSStringFromSelector( @selector(dialogStyleHUD) )]) {
                    if (![self.passwordWindow.window isVisible])
                        self.passwordWindow = nil;
                    else {
                        [self.passwordWindow close];
                        self.passwordWindow = nil;
                        [self showPasswordWindow:nil];
                    }
                }
            }];
    [self updateUsers];

    // Global hotkey.
    EventHotKeyRef hotKeyRef;
    EventTypeSpec hotKeyEvents[1] = { { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed } };
    OSStatus status = InstallApplicationEventHandler(NewEventHandlerUPP( MPHotKeyHander ), GetEventTypeCount( hotKeyEvents ),
                                                     hotKeyEvents, (__bridge void *)self, NULL);
    if (status != noErr)
    err(@"Error installing application event handler: %d", status);
    status = RegisterEventHotKey( 35 /* p */, controlKey + cmdKey, MPShowHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
    err(@"Error registering 'show' hotkey: %d", status);
    status = RegisterEventHotKey( 35 /* p */, controlKey + optionKey + cmdKey, MPLockHotKey, GetApplicationEventTarget(), 0, &hotKeyRef );
    if (status != noErr)
    err(@"Error registering 'lock' hotkey: %d", status);
    
    // iOS App window
    if ([[MPMacConfig get].showAppWindow boolValue]) {
        [self.appsWindow = [[NSWindowController alloc] initWithWindowNibName:@"MPAppsWindow" owner:self] showWindow:self];
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.appsWindow.window queue:nil
                                                      usingBlock:^(NSNotification *note) {
                                                          [MPMacConfig get].showAppWindow = @(self.appWindowDontShow.state == NSOffState);
                                                      }];
    }
}

- (void)setActiveUser:(MPUserEntity *)activeUser {

    BOOL reopenPasswordWindow = [self.passwordWindow.window isVisible];
    
    if (![[self activeUserForThread].objectID isEqual:activeUser.objectID]) {
        [self.passwordWindow close];
        self.passwordWindow = nil;
        [super setActiveUser:activeUser];
    }

    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj representedObject] isEqual:[activeUser objectID]])
            [obj setState:NSOnState];
        else
            [obj setState:NSOffState];
    }];

    [MPMacConfig get].usedUserName = activeUser.name;
    
    if (reopenPasswordWindow)
        [self showPasswordWindow:nil];
}

- (void)updateMenuItems {

    MPUserEntity *activeUser = [self activeUserForThread];
//    if (!(self.showItem.enabled = ![self.passwordWindow.window isVisible])) {
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
    self.useICloudItem.enabled = self.storeManager.cloudAvailable;
    if (self.storeManager.cloudAvailable) {
        self.useICloudItem.title = @"Use iCloud";
        self.useICloudItem.toolTip = nil;
    }
    else {
        self.useICloudItem.title = @"Use iCloud (Unavailable)";
        self.useICloudItem.toolTip = @"iCloud is not set up for your Mac user.";
    }
}

- (IBAction)showPasswordWindow:(id)sender {

    // If no user, can't activate.
    if (![self activeUserForThread])
        return;

    // Activate the app if not active.
    if (![[NSApplication sharedApplication] isActive])
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];

    // Don't show window if we weren't already running (ie. if we haven't been activated before).
    if (!self.passwordWindow)
        self.passwordWindow = [[MPPasswordWindowController alloc] initWithWindowNibName:@"MPPasswordWindowController"];
    
    [self.passwordWindow showWindow:self];
}

- (void)applicationWillResignActive:(NSNotification *)notification {

    if (![[MPConfig get].rememberLogin boolValue])
        [self lock:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    NSManagedObjectContext *moc = [MPMacAppDelegate managedObjectContextForThreadIfReady];
    if (!moc)
        return NSTerminateNow;

    if (![moc commitEditing])
        return NSTerminateCancel;

    if (![moc hasChanges])
        return NSTerminateNow;

    [moc saveToStore];
    return NSTerminateNow;
}

@end
