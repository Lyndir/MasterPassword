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

@interface MPAppDelegate : MPAppDelegate_Shared<MFMailComposeViewControllerDelegate>

+ (MPAppDelegate *)get;

- (void)checkConfig;
- (void)showGuide;

- (void)export;
- (void)changeMasterPasswordFor:(MPUserEntity *)user;

@end
