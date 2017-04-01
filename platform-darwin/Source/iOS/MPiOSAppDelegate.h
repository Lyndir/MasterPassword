//
//  MPiOSAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MPAppDelegate_Shared.h"

@interface MPiOSAppDelegate : MPAppDelegate_Shared

- (void)showFeedbackWithLogs:(BOOL)logs forVC:(UIViewController *)viewController;
- (void)openFeedbackWithLogs:(BOOL)logs forVC:(UIViewController *)viewController;

- (void)showExportForVC:(UIViewController *)viewController;
- (void)changeMasterPasswordFor:(MPUserEntity *)user saveInContext:(NSManagedObjectContext *)moc didResetBlock:(void ( ^ )(void))didReset;

@end
