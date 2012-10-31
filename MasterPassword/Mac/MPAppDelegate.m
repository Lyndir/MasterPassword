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
#import "MPConfig.h"
#import "MPElementEntity.h"
#import <Carbon/Carbon.h>


@implementation MPAppDelegate
@synthesize statusItem;
@synthesize lockItem;
@synthesize showItem;
@synthesize statusMenu;
@synthesize useICloudItem;
@synthesize rememberPasswordItem;
@synthesize savePasswordItem;
@synthesize passwordWindow;

@synthesize key;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
static EventHotKeyID MPShowHotKey = {.signature = 'show', .id = 1};
#pragma clang diagnostic pop

+ (void)initialize {

    [MPConfig get];

#ifdef DEBUG
    [PearlLogger get].printLevel = PearlLogLevelTrace;
#endif
}

+ (MPAppDelegate *)get {

    return (MPAppDelegate *)[super get];
}

static OSStatus MPHotKeyHander(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {

    // Extract the hotkey ID.
    EventHotKeyID hotKeyID;
    GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID,
     NULL, sizeof(hotKeyID), NULL, &hotKeyID);

    // Check which hotkey this was.
    if (hotKeyID.signature == MPShowHotKey.signature && hotKeyID.id == MPShowHotKey.id) {
        [((__bridge MPAppDelegate *)userData) activate:nil];
        return noErr;
    }

    return eventNotHandledErr;
}

- (void)updateUsers {
    
    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (idx > 1)
            [[self.usersItem submenu] removeItemAtIndex:(NSInteger)idx];
    }];

    NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextIfReady];
    if (!moc) {
        [self.createUserItem setEnabled:NO];
        [[self.usersItem.submenu addItemWithTitle:@"Loading..." action:NULL keyEquivalent:@""] setEnabled:NO];
        
        return;
    }

    [self.createUserItem setEnabled:YES];
    [moc performBlockAndWait:^{
        NSArray        *users = nil;
        NSError        *error        = nil;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPUserEntity class])];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"lastUsed" ascending:NO]];
        users = [moc executeFetchRequest:fetchRequest error:&error];
        if (!users)
            err(@"Failed to load users: %@", error);

        for (MPUserEntity *user in users) {
            NSMenuItem *userItem = [[NSMenuItem alloc] initWithTitle:user.name action:@selector(selectUser:) keyEquivalent:@""];
            [userItem setTarget:self];
            [userItem setRepresentedObject:user];
            [[self.usersItem submenu] addItem:userItem];
        }
    }];
}

- (void)selectUser:(NSMenuItem *)item {
    
    NSAssert1([[item representedObject] isKindOfClass:[MPUserEntity class]], @"Not a user: %@", item.representedObject);
    
    self.activeUser = item.representedObject;

    [[[self.usersItem submenu] itemArray] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj setState:NSOffState];
    }];
    item.state = NSOnState;
}

- (void)showMenu {

    self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;
    self.savePasswordItem.state     = [MPAppDelegate get].activeUser.saveKey? NSOnState: NSOffState;
    self.showItem.enabled           = ![self.passwordWindow.window isVisible];

    [self.statusItem popUpStatusItemMenu:self.statusMenu];
}

- (IBAction)activate:(id)sender {

    if ([[NSApplication sharedApplication] isActive])
        [self applicationDidBecomeActive:nil];
    else
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (IBAction)togglePreference:(NSMenuItem *)sender {

    if (sender == useICloudItem)
        [self.storeManager useiCloudStore:sender.state == NSOffState alertUser:YES];
    if (sender == rememberPasswordItem)
        [MPConfig get].rememberLogin = [NSNumber numberWithBool:![[MPConfig get].rememberLogin boolValue]];
    if (sender == savePasswordItem)
        [MPAppDelegate get].activeUser.saveKey = ![MPAppDelegate get].activeUser.saveKey;
}

- (IBAction)newUser:(NSMenuItem *)sender {
}

- (IBAction)signOut:(id)sender {
    
    [self signOutAnimated:YES];
}

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)oldValue {

    if (configKey == @selector(rememberLogin))
        self.rememberPasswordItem.state = [[MPConfig get].rememberLogin boolValue]? NSOnState: NSOffState;
    if (configKey == @selector(saveKey))
        self.savePasswordItem.state     = [MPAppDelegate get].activeUser.saveKey? NSOnState: NSOffState;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqualToString:@"key"]) {
        if (self.key)
            [self.lockItem setEnabled:YES];
        else {
            [self.lockItem setEnabled:NO];
            [self.passwordWindow close];
        }
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {

    return [[self managedObjectContextIfReady] undoManager];
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Setup delegates and listeners.
    [MPConfig get].delegate = self;
    [self addObserver:self forKeyPath:@"key" options:0 context:nil];

    // Initially, use iCloud.
    if ([[MPConfig get].firstRun boolValue])
        [[self storeManager] useiCloudStore:YES alertUser:YES];

    // Status item.
    self.statusItem                = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.title          = @"•••";
    self.statusItem.highlightMode  = YES;
    self.statusItem.target         = self;
    self.statusItem.action         = @selector(showMenu);
    
    [[NSNotificationCenter defaultCenter] addObserverForName:PersistentStoreDidChange object:nil queue:nil usingBlock:
     ^(NSNotification *note) {
         [self updateUsers];
     }];
    [[NSNotificationCenter defaultCenter] addObserverForName:PersistentStoreDidMergeChanges object:nil queue:nil usingBlock:
     ^(NSNotification *note) {
         [self updateUsers];
     }];
    [self updateUsers];

    // Global hotkey.
    EventHotKeyRef hotKeyRef;
    EventTypeSpec  hotKeyEvents[1] = {{.eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed}};
    OSStatus       status          = InstallApplicationEventHandler(NewEventHandlerUPP(MPHotKeyHander), GetEventTypeCount(hotKeyEvents),
                                                                    hotKeyEvents,
                                                                    (__bridge void *)self, NULL);
    if (status != noErr)
    err(@"Error installing application event handler: %d", status);
    status = RegisterEventHotKey(35 /* p */, controlKey + cmdKey, MPShowHotKey, GetApplicationEventTarget(), 0, &hotKeyRef);
    if (status != noErr)
    err(@"Error registering hotkey: %d", status);
}

- (void)applicationWillBecomeActive:(NSNotification *)notification {

    if (!self.passwordWindow)
        self.passwordWindow = [[MPPasswordWindowController alloc] initWithWindowNibName:@"MPPasswordWindowController"];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {

    static BOOL firstTime = YES;
    if (firstTime)
        firstTime = NO;
    else
        [self.passwordWindow showWindow:self];
}

- (void)applicationWillResignActive:(NSNotification *)notification {

    if (![[MPConfig get].rememberLogin boolValue])
        self.key = nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    if (![self managedObjectContextIfReady]) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContextIfReady] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContextIfReady] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContextIfReady] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question     = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info         = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton   = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert  *alert        = [[NSAlert alloc] init];
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

#pragma mark - UbiquityStoreManagerDelegate

- (void)ubiquityStoreManager:(UbiquityStoreManager *)manager didSwitchToiCloud:(BOOL)iCloudEnabled {
    
    [super ubiquityStoreManager:manager didSwitchToiCloud:iCloudEnabled];

    self.useICloudItem.state   = iCloudEnabled? NSOnState: NSOffState;
    self.useICloudItem.enabled = !iCloudEnabled;
    
    if (![[MPConfig get].iCloudDecided boolValue]) {
        if (iCloudEnabled)
            return;
        
        switch ([[NSAlert alertWithMessageText:@"iCloud Is Disabled"
                                 defaultButton:@"Enable iCloud" alternateButton:@"Leave iCloud Off" otherButton:@"Explain?"
                     informativeTextWithFormat:@"It is highly recommended you enable iCloud."] runModal]) {
            case NSAlertDefaultReturn: {
                [MPConfig get].iCloudDecided = @YES;
                [manager useiCloudStore:YES alertUser:NO];
                break;
            }
                
            case NSAlertOtherReturn: {
                [[NSAlert alertWithMessageText:@"About iCloud"
                                 defaultButton:[PearlStrings get].commonButtonThanks alternateButton:nil otherButton:nil
                     informativeTextWithFormat:
                  @"iCloud is Apple's solution for saving your data in \"the cloud\" "
                  @"and making sure your other iPhones, iPads and Macs are in sync.\n\n"
                  @"For Master Password, that means your sites are available on all your "
                  @"Apple devices, and you always have a backup of them in case "
                  @"you loose one or need to restore.\n\n"
                  @"Because of the way Master Password works, it doesn't need to send your "
                  @"site's passwords to Apple.  Only their names are saved to make it easier "
                  @"for you to find the site you need.  For some sites you may have set "
                  @"a user-specified password: these are sent to iCloud after being encrypted "
                  @"with your master password.\n\n"
                  @"Apple can never see any of your passwords."] runModal];
                [self ubiquityStoreManager:manager didSwitchToiCloud:iCloudEnabled];
                break;
            }
                
            default:
                break;
        };
    }
}

@end
