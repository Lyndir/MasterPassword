//
//  MPGuideViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPGuideViewController : UIViewController<UIScrollViewDelegate>

@property(weak, nonatomic) IBOutlet UIView *siteNameTip;
@property(weak, nonatomic) IBOutlet UIView *contentTip;
@property(weak, nonatomic) IBOutlet UILabel *contentTipText;
@property(weak, nonatomic) IBOutlet UIButton *usernameButton;
@property(weak, nonatomic) IBOutlet UIView *usernameTip;
@property(weak, nonatomic) IBOutlet UIButton *typeButton;
@property(weak, nonatomic) IBOutlet UIView *typeTip;
@property(weak, nonatomic) IBOutlet UIButton *toolButton;
@property(weak, nonatomic) IBOutlet UIView *toolTip;
@property(weak, nonatomic) IBOutlet UIProgressView *progress;
@property(weak, nonatomic) IBOutlet UIView *content;
@property(weak, nonatomic) IBOutlet UIButton *contentButton;
@property(weak, nonatomic) IBOutlet UITextField *contentText;
@property(weak, nonatomic) IBOutlet UIButton *volumeButton;
@property(weak, nonatomic) IBOutlet UIButton *largePlayButton;
@property(weak, nonatomic) IBOutlet UIButton *smallPlayButton;

- (IBAction)play;
- (IBAction)close;
- (IBAction)toggleVolume;

@end
