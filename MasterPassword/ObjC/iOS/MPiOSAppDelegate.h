//
//  MPiOSAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#import "MPAppDelegate_Shared.h"
#import "GPPShare.h"

@interface MPiOSAppDelegate : MPAppDelegate_Shared

- (void)showGuide;
- (void)showSetup;
- (void)showFeedbackWithLogs:(BOOL)logs forVC:(UIViewController *)viewController;

- (void)export;
- (void)changeMasterPasswordFor:(MPUserEntity *)user inContext:(NSManagedObjectContext *)moc didResetBlock:(void (^)(void))didReset;

@end
