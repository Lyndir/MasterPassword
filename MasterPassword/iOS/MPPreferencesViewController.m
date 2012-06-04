//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPreferencesViewController.h"
#import "MPAppDelegate.h"

@interface MPPreferencesViewController ()

@end

@implementation MPPreferencesViewController
@synthesize avatarScrollView;

- (void)viewDidLoad {
    
    __block NSInteger avatarIndex = 0;
    [self.avatarScrollView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        UIButton *avatar = (UIButton *)subview;
        avatar.toggleSelectionWhenTouchedInside = YES;
        avatar.tag = avatarIndex++;
        
        [avatar onSelect:^(BOOL selected) {
            [MPAppDelegate get].activeUser.avatar = (unsigned)avatar.tag;
            [self.avatarScrollView enumerateSubviews:^(UIView *subview_, BOOL *stop_, BOOL *recurse_) {
                UIButton *avatar_ = (UIButton *)subview_;
                avatar_.selected = ([MPAppDelegate get].activeUser.avatar == (unsigned)avatar_.tag);
            } recurse:NO];
        } options:0];
    } recurse:NO];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.avatarScrollView autoSizeContent];
    
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
    
    while ([self.navigationController.viewControllers containsObject:sender])
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    [self setAvatarScrollView:nil];
    [super viewDidUnload];
}
@end
