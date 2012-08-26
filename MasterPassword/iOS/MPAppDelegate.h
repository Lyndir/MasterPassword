//
//  MPAppDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MPAppDelegate_Shared.h"

@interface MPAppDelegate : MPAppDelegate_Shared

+ (MPAppDelegate *)get;

- (void)checkConfig;
- (void)showGuide;
- (void)showFeedbackWithLogs:(BOOL)logs forVC:(UIViewController *)viewController;

- (void)export;
- (void)changeMasterPasswordFor:(MPUserEntity *)user didResetBlock:(void(^)(void))didReset;

@end
