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
@synthesize keyID;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
static EventHotKeyID MPShowHotKey = {.signature = 'show', .id = 1};
#pragma clang diagnostic pop

+ (void)initialize {

    [MPConfig get];

#ifdef DEBUG
    [PearlLogger get].autoprintLevel = PearlLogLevelTrace;
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

- (void)showMenu {

    self.rememberPasswordItem.state = [[MPConfig get].rememberKey boolValue]? NSOnState: NSOffState;
    self.savePasswordItem.state     = [[MPConfig get].saveKey boolValue]? NSOnState: NSOffState;
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
        [MPConfig get].rememberKey = [NSNumber numberWithBool:![[MPConfig get].rememberKey boolValue]];
    if (sender == savePasswordItem)
        [MPConfig get].saveKey     = [NSNumber numberWithBool:![[MPConfig get].saveKey boolValue]];
}

- (void)didUpdateConfigForKey:(SEL)configKey fromValue:(id)oldValue {

    if (configKey == @selector(rememberKey))
        self.rememberPasswordItem.state = [[MPConfig get].rememberKey boolValue]? NSOnState: NSOffState;
    if (configKey == @selector(saveKey))
        self.savePasswordItem.state     = [[MPConfig get].saveKey boolValue]? NSOnState: NSOffState;
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

    return [[self managedObjectContext] undoManager];
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

    if (![[MPConfig get].rememberKey boolValue])
        self.key = nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.

    if (![self managedObjectContext]) {
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

    self.useICloudItem.state   = iCloudEnabled? NSOnState: NSOffState;
    self.useICloudItem.enabled = !iCloudEnabled;
}

@end
