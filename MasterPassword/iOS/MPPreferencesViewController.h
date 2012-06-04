//
//  MPPreferencesViewController.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"

@interface MPPreferencesViewController : UITableViewController <IASKSettingsDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *avatarScrollView;

@end
