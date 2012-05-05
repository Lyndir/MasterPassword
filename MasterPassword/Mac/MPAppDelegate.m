//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Key.h"
#import "MPConfig.h"
#import "MPElementEntity.h"
#import <Carbon/Carbon.h>


@interface MPAppDelegate ()

@property (readwrite, strong, nonatomic) MPPasswordWindowController     *passwordWindow;

@end

@implementation MPAppDelegate
@synthesize statusItem;
@synthesize unlockItem;
@synthesize lockItem;
@synthesize showItem;
@synthesize statusMenu;
@synthesize passwordWindow;

@dynamic persistentStoreCoordinator, managedObjectModel, managedObjectContext;
@synthesize key;
@synthesize keyHash;
@synthesize keyHashHex;

static EventHotKeyID MPShowHotKey = { .signature = 'show', .id = 1 };

+ (void)initialize {
    
    [MPConfig get];
    
#ifdef DEBUG
    [PearlLogger get].autoprintLevel = PearlLogLevelTrace;
#endif
}

static OSStatus MPHotKeyHander(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData){

    // Extract the hotkey ID.
	EventHotKeyID hotKeyID;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,
                      NULL,sizeof(hotKeyID),NULL,&hotKeyID);
    
    // Check which hotkey this was.
    if (hotKeyID.signature == MPShowHotKey.signature && hotKeyID.id == MPShowHotKey.id) {
        [((__bridge MPAppDelegate *)userData) activate:nil];
        return noErr;
    }
    
    return eventNotHandledErr;
}

- (void)showMenu {
    
    [self.showItem setEnabled:![self.passwordWindow.window isVisible]];
    [self.statusItem popUpStatusItemMenu:self.statusMenu];
}

- (IBAction)activate:(id)sender {
    
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [self addObserver:self forKeyPath:@"key" options:0 context:nil];
    
    // Status item.
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.title = @"•••";
    self.statusItem.highlightMode = YES;
    self.statusItem.target = self;
    self.statusItem.action = @selector(showMenu);
    
    // Global hotkey.
    EventHotKeyRef hotKeyRef;
    EventTypeSpec hotKeyEvents[1] = { { .eventClass = kEventClassKeyboard, .eventKind = kEventHotKeyPressed } };
    OSStatus status = InstallApplicationEventHandler(NewEventHandlerUPP(MPHotKeyHander), GetEventTypeCount(hotKeyEvents), hotKeyEvents,
                                                     (__bridge void *)self, NULL);
	if(status != noErr)
        err(@"Error installing application event handler: %d", status);
	status = RegisterEventHotKey(35 /* p */, controlKey + cmdKey, MPShowHotKey, GetApplicationEventTarget(), 0, &hotKeyRef);
	if(status != noErr)
        err(@"Error registering hotkey: %d", status);
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {

    if (!self.passwordWindow)
        self.passwordWindow = [[MPPasswordWindowController alloc] initWithWindowNibName:@"MPPasswordWindowController"];
    [self.passwordWindow showWindow:self];
    
    [self unlock:self];
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

- (IBAction)unlock:(id)sender {
    
    if (!self.key)
        // Try and load the key from the keychain.
        [self loadStoredKey];
    
    if (!self.key)
        // Ask the user to set the key through his master password.
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.key)
                return;
            
            NSAlert *alert = [NSAlert alertWithMessageText:@"Master Password is locked."
                                             defaultButton:@"Unlock" alternateButton:@"Change" otherButton:@"Quit"
                                 informativeTextWithFormat:@"Your master password is required to unlock the application."];
            NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 22)];
            [alert setAccessoryView:passwordField];
            [alert layout];
            [passwordField becomeFirstResponder];
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

            [self printStore];
        });
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
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
